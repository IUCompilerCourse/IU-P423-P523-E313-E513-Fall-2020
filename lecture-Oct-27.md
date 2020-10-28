# Code Review of Tuple & Garbage Collection

Announcements:
* Midterm exam on Friday, available 7am to 11:59pm, 90 minutes.

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

;; for/list, range
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

;; use Racket's make-list instead, for/list
(define (duplicate x n) 
  (if (zero? n) '()
      (cons x (duplicate x (sub1 n)))))

;; for/list
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

Lower each of the following forms to x86:

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

Variables of vector type that are live during a call to `collect` must
be spilled. To ensure that, create interference edges with
callee-saved registers.  (We already add edges to the caller-saved
registers.)

```
(define (add-from-instr graph instr live-after types)
  (match instr
    [(Callq 'collect)
     (for ([x live-after]) 
       (if (list? (match-alist (Var x) types))  ;; is variable x a vector?, vector-type?
         (for ([y (append caller-registers callee-registers)])
           (add-edge! graph x y))
         (for ([y caller-registers]) 
           (add-edge! graph x y))))]
    ...))
```

## `allocate-registers`

Spill vector-typed variables to the root stack.

2 root stack spills
3 regular spills

How much space on root stack?  5 slots
On the regular stack? 5 slots

Two registers:
0  int
1  int
------
2  vector     0
3  int        1
4  int        2
5  vector     3
6  int        4
```
(define (assign-nat n type)
  (let [(last-reg (sub1 (length reg-colors)))]
    (cond [(<= n last-reg)
           (Reg (rev-match-alist n reg-colors))]
          [(list? type) ;; vector-type?
           (Deref 'r15 (* 8 (add1 (- n last-reg))))]
          [else
           (Deref 'rbp (* (add1 (- n last-reg)) (- 8)))]
          )))

(define (generate-assignments locals colors)
  (cond [(empty? locals) '()]
        [else (match (car locals)
                [`(,(Var v) . ,type)
                 (cons `(,v . ,(assign-nat (match-alist v colors) type)) 
                       (generate-assignments (cdr locals) colors))])]))
```

## `print-x86`

In the prelude, call the `initialize` function to set up the garbage
collector.

In the prelude and conclusion, add code for pushing and popping a
frame for `main` to the root stack. Initialize all the slots in the
frame to zero.

```
(define (make-main stack-size used-regs root-spills)
  (let* ([extra-pushes (filter (lambda (reg)
                                (match reg
                                  [(Reg x) (index-of callee-registers x)]
                                  [x false]))
                              used-regs)]
         [push-bytes (* 8 (length extra-pushes))]
         [stack-adjust (- (round-stack-to-16 (+ push-bytes stack-size)) push-bytes)])
    (Block '()
      (append (list (Instr 'pushq (list (Reg 'rbp)))
                    (Instr 'movq (list (Reg 'rsp) (Reg 'rbp))))
              (map (lambda (x) (Instr 'pushq (list x))) extra-pushes) 
              (list (Instr 'subq (list (Imm stack-adjust) (Reg 'rsp)))) 
              (initialize-garbage-collector root-spills)
              (list (Jmp 'start))))))

(define (initialize-garbage-collector root-spills)
  (list (Instr 'movq (list (Imm root-stack-size) (Reg 'rdi)))
        (Instr 'movq (list (Imm heap-size) (Reg 'rsi)))
        (Callq 'initialize)
        (Instr 'movq (list (Global 'rootstack_begin) (Reg 'r15)))
        (Instr 'movq (list (Imm 0) (Deref (Reg 'r15) 0))
        ...
        (Instr 'movq (list (Imm 0) (Deref (Reg 'r15) k))
        (Instr 'addq (list (Imm root-spills) (Reg 'r15)))))
```
