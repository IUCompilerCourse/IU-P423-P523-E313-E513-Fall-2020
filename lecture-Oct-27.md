# Code Review of Tuple & Garbage Collection

Announcements:
* Midterm exam on Friday

## `type-check`

* add `HasType`
* type checking of `vector-set!`

```
(define (type-check-exp env e)
  (match e
    [(Var x)
     (define type (match-alist x env))
     (values (HasType (Var x) type) type)]
    ...
    [(Prim 'vector-set! (list vect (Int i) val))
     (define-values (vect-exp vect-type) (type-check-exp env vect))
     (define-values (i-exp i-type) (type-check-exp env (Int i)))
     (define-values (val-exp val-type) (type-check-exp env val))
     (if (not (eq? i-type 'Integer))
         (error "The type of index for vector-set! must be an Integer")
         (if (not (eq? (car vect-type) 'Vector))
             (error "Vector set got a non vector")
             (if (not (equal? (list-ref vect-type (add1 i)) val-type))
                 (error (format "Changing vector types is not supported got ~a ~a" 
                     (list-ref vect-type (add1 i)) val-type))
                 (values (HasType (Prim 'vector-set! (list vect-exp i-exp val-exp))
                                  'Void) 'Void))))]
    ...)
```

## `expose-allocation`

lower `(vector e1 ... en)` creation into:
1. evaluate the initializing expressions `e1` ... `en`
2. call `collect` if there is not enough room in the FromSpace
3. allocate the vector using the `allocate` form
4. initialize the vector's elements using `vector-set!`

```
(define (expose-exp e)
  (match e
    [(HasType (Prim 'vector es) type)
     (let* ([len (length es)] 
            [bytes (* 8 len)]
            [vect (gensym 'vec)] 
            [vars (generate-n-vars len)])
       (expand-into-lets vars (for/list ([e es]) (expose-exp e)) 
          (do-allocate vect len bytes
              (bulk-vector-set (HasType (Var vect) type) vars type) 
              type)
          type))]
    ...))

(define (generate-n-vars n)
  (if (zero? n) '()
      (cons (gensym 'tmp) (generate-n-vars (sub1 n)))))

(define (expand-into-lets vars exps base base-type)
  (if (empty? exps) base
    (HasType
      (Let (car vars) (car exps) 
           (expand-into-lets (cdr vars) (cdr exps) base base-type))
      base-type)))

;; ommitting the HasType's for readability
(define (do-allocate vect len bytes base type)
    (Let '_ (If (Prim '< (list (Prim '+ (list (GlobalValue 'free_ptr) (Int bytes)))
                                 (GlobalValue 'fromspace_end)))
                (Void)
                (Collect bytes))
    (Let vect (Allocate len type) base)))

(define (bulk-vector-set vect vars types)
  (expand-into-lets (duplicate '_ (length vars)) 
    (make-vector-set-exps vect 0 vars (cdr types)) vect types))

;; use Racket's make-list instead
(define (duplicate x n) 
  (if (zero? n) '()
      (cons x (duplicate x (sub1 n)))))

(define (make-vector-set-exps vect accum vars types)
  (if (empty? vars) '()
      (cons (Prim 'vector-set! (list vect (Int accum) (Var (car vars))))
            (make-vector-set-exps vect (add1 accum) (cdr vars) (cdr types)))))
```

## `uncover-locals`

Collect up all the variables and their types into an association list
in the `Program` info.

```
(define (uncover-block tail)
  (match tail
    [(Seq (Assign var (HasType x type)) t)
     (cons `(,var . ,type) (uncover-block t))]
    [x '()]))

(define (uncover-locals p)
  (match p
    [(Program info (CFG B-list))
     (let ([locals (remove-duplicates
                     (append-map (lambda (x) 
                                    (uncover-block (cdr x))) B-list))])
       (Program `((locals . ,locals)) (CFG B-list)))]))
```


## `select-instructions`

Lower each of the following forms to x86
* `vector-ref`
* `vector-set!`
* `allocate`
* `collect`

```
(define (slct-stmt tail)
  (match tail
    [(Assign (Var x) (HasType exp t))
     (match exp
       ...
       [(Prim 'vector-ref (list (HasType vect t1) (HasType (Int n) t2))) 
        (list (Instr 'movq (list (slct-atom vect) (Reg 'r11))) 
              (Instr 'movq (list (Deref 'r11 (* 8 (add1 n))) (Var x))))]
       [(Prim 'vector-set! (list (HasType vect t1) (HasType (Int n) t2) (HasType arg t3)))
        (list (Instr 'movq (list (slct-atom vect) (Reg 'r11))) 
              (Instr 'movq (list (slct-atom arg) (Deref 'r11 (* 8 (add1 n))))) 
              (Instr 'movq (list (Imm 0) (Var x))))]
       [(Allocate len types)
        (let ([tag (calculate-tag (reverse (cdr types)) (length (cdr types)))])
          (list (Instr 'movq (list (Global 'free_ptr) (Var x))) 
                (Instr 'addq (list (Imm (* 8 (add1 len))) (Global 'free_ptr))) 
                (Instr 'movq (list (Var x) (Reg 'r11))) 
                (Instr 'movq (list (Imm tag) (Deref 'r11 0)))))]
       [(Collect bytes) 
        (list (Instr 'movq (list (Reg 'r15) (Reg 'rdi)))
              (Instr 'movq (list (Imm bytes) (Reg 'rsi))) 
              (Callq 'collect))]
       ...)]))
```


## `build-interference`



## `allocate-registers`



## `print-x86`
