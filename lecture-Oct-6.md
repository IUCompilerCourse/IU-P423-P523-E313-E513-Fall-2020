# Code Review: Booleans and Control Flow


## Type Checking

### Example 1

```
(define (type-check-exp env)
  (lambda (e)
    (match e
      [(Var x) (dict-ref env x)]
      [(Int n) 'Integer]
      [(Bool b) 'Boolean]
      [(Prim op args) ((type-check-prim env) e)]
      [(Let x e body)
       (define Te ((type-check-exp env) e))
       (define Tb ((type-check-exp (dict-set env x Te)) body))
       Tb]
      [(If cnd cnsq alt)
       (unless (eqv? 'Boolean ((type-check-exp env) cnd))
         (error "condition given to if should be bool, given " cnd))
       (define Tc ((type-check-exp env) cnsq))
       (define Ta ((type-check-exp env) alt))
       (unless (equal? Tc Ta)
         (error (string-append "consequent and alternative in if should "
                               "have same type, given")
                (list Tc Ta)))
       Tc]
      [else
       (error "type-check-exp couldn't match" e)])))

(define (type-check-prim env)
  (lambda (prim)
    (let ([recur (type-check-exp env)])
      (match prim
        [(Prim 'read (list)) 'Integer]
        [(Prim 'eq? (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (eqv? Te1 Te2)
             (and (eqv? Te1 Te1)
                  (or (eqv? Te1 'Integer)
                      (eqv? Te1 'Boolean)))
             'Boolean
             (error "eq? should take two ints or two bools, given " (list e1 e2)))]
        [(Prim '< (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Integer)
                  (eqv? Te2 'Integer))
             'Boolean
             (error "< should take two ints, given " (list e1 e2)))]
        [(Prim '<= (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Integer)
                  (eqv? Te2 'Integer))
             'Boolean
             (error "<= should take two ints, given " (list e1 e2)))]
        [(Prim '> (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Integer)
                  (eqv? Te2 'Integer))
             'Boolean
             (error "> should take two ints, given " (list e1 e2)))]
        [(Prim '>= (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Integer)
                  (eqv? Te2 'Integer))
             'Boolean
             (error ">= should take two ints, given " (list e1 e2)))]
        [(Prim '+ (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Integer)
                  (eqv? Te2 'Integer))
             'Integer
             (error "+ should take two ints, given " (list e1 e2)))]
        [(Prim '- (list e))
         (define Te (recur e))
         (if (eqv? Te 'Integer)
             'Integer
             (error "- should take one int, given " (list e)))]
        [(Prim '- (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Integer)
                  (eqv? Te2 'Integer))
             'Integer
             (error "- should take two ints, given " (list e1 e2)))]
        [(Prim 'and (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Boolean)
                  (eqv? Te2 'Boolean))
             'Boolean
             (error "and should take two bools, given " (list e1 e2)))]
        [(Prim 'or (list e1 e2))
         (define Te1 (recur e1))
         (define Te2 (recur e2))
         (if (and (eqv? Te1 'Boolean)
                  (eqv? Te2 'Boolean))
             'Boolean
             (error "or should take two bools, given " (list e1 e2)))]
        [(Prim 'not (list e))
         (define Te (recur e))
         (if (eqv? Te 'Boolean)
             'Boolean
             (error "not should take one bool, given " (list e)))]))))
             
(define (type-check p)
  (match p
    [(Program info body)
     (define Tb ((type-check-exp '()) body))
     (unless (equal? Tb 'Integer)
       (error "result of the program must be an integer, not " Tb))
     (Program info body)]))
```

### Example 2

```
(define (check-bool e) 
    (match e
        ['Boolean 'Boolean]
        [else (error "expected Boolean but got" e)]
        ))

(define (check-int e) 
    (match e
        ['Integer 'Integer]
        [else (error "expected Integer but got" e)]
        ))

(define (check-eq ts)
    (if (equal? (first ts) (last ts))
        (void)
        (error "Cannot compare items of different types" ts)))

(define (type-check-op op ts)
    (match op
        ['read 'Integer]
        ['+ (for ([t ts]) (check-int t)) 'Integer]
        ['- (for ([t ts]) (check-int t)) 'Integer]
        ['not (for ([t ts]) (check-bool t)) 'Boolean]
        ['and (for ([t ts]) (check-bool t)) 'Boolean]
        ['or (for ([t ts]) (check-bool t)) 'Boolean]
        ['eq? (check-eq ts) 'Boolean]
        ['cmp (check-eq ts) 'Boolean]
        ['< (for ([t ts]) (check-int t)) 'Boolean]
        ['<= (for ([t ts]) (check-int t)) 'Boolean]
        ['> (for ([t ts]) (check-int t)) 'Boolean]
        ['>= (for ([t ts]) (check-int t)) 'Boolean]
        [else (error "unknown operator" op)]
))

(define (type-check-exp env)
  (lambda (e)
    (match e
      [(Var x) (dict-ref env x)]
      [(Int n) 'Integer]
      [(Bool b) 'Boolean]
      [(Let x e body)
        (define Te ((type-check-exp env) e))
        (define Tb ((type-check-exp (dict-set env x Te)) body))
        Tb]

      [(If e1 e2 e3)
       (define T1 ((type-check-exp env) e1))
       (unless (equal? T1 'Boolean) 
         (error "Conditional of if statement must resolve to a boolean. Was " T1))
       (define T2 ((type-check-exp env) e2))
       (define T3 ((type-check-exp env) e3))
       (unless (equal? T2 T3) 
         (error "Return types of both branches of If must match. Got" T2 " and " T3))
       T2]
      [(Prim op es)
        (define ts
           (for/list ([e es]) ((type-check-exp env) e)))
        (define t-ret (type-check-op op ts))
        t-ret]
      [else
       (error "type-check-exp couldn't match" e)])))

(define (type-checker e)
    (match e
      [(Program info body)
       (define Tb ((type-check-exp '()) body))
       (unless (equal? Tb 'Integer)
         (error "result of the program must be an integer, not " Tb))
       (Program info body)]
      ))
```

## Remove Complex Operands

### Example 1

```
(define (rco-atom e)
  (match e
      [(Var x) (values (Var x) '())]
      [(Int n) (values (Int n) '())]
      [(Bool bool) (values (Bool bool) '())]
      [(Let x e body)
       (define tmp (gensym "tmp"))
       (define-values (e-val e-alist) (rco-atom e))
       (values (Var tmp) (append e-alist  `((,tmp . ,(Let x e-val (rco-exp body))))))]
      [(Prim op es)
       (define tmp (gensym "tmp"))
       (define-values (new-es bs)
         (for/lists (l1 l2) ([e es])
           (rco-atom e)))
       (values (Var tmp) (append bs `((,tmp . ,(Prim op new-es))))))]
      [(If cond exp else)
       (define tmp (gensym "tmp"))
       (define cond-val (rco-exp cond))
       (define exp-val (rco-exp exp))
       (define else-val (rco-exp else))
       (values (Var tmp) `((,tmp . ,(If cond-val exp-val else-val))))]
      ))

(define (rco-exp e)
  (match e
      [(Var x) (Var x)]
      [(Int n) (Int n)]
      [(Bool bool) (Bool bool)]
      [(Let x e body)
       (begin (define e-val (rco-exp e))
              (Let x e-val (rco-exp body)))]
      [(Prim op es)
       (let [(exps (split-pairs (for/list ([e es]) 
                                     (begin (define-values (var alist) (rco-atom e)) 
                                            `(,var . ,alist)))))]
         (expand-alist (cdr exps) (Prim op (car exps))))]
      [(If cond exp else)
       (define exp-var (rco-exp exp))
       (define else-var (rco-exp else))
       (define cond-var (rco-exp cond))
       (If cond-var exp-var else-var)]
      ))

(define (remove-complex-opera* p)
  (match p
    [(Program info e)
     (Program info (rco-exp e))]
    ))
```

### Example 2

```
(define (remove-complex-opera* p)
    (match p
      [(Program info e)
       (Program info (rco-exp e))]))

(define (rco-atom e)
  (match e
    [(Var x) (values (Var x) '())]
    [(Int n) (values (Int n) '())]
    [(Bool b) (values (Bool b) '())]
    [(Let x rhs body)
     (define new-rhs (rco-exp rhs))
     (define-values (new-body body-ss) (rco-atom body))
     (values new-body (append `((,x . ,new-rhs)) body-ss))]
    [(Prim op es) 
     (define-values (new-es sss)
       (for/lists (l1 l2) ([e es]) (rco-atom e)))
     (define ss (append* sss))
     (define tmp (gensym 'tmp))
     (values (Var tmp)
             (append ss `((,tmp . ,(Prim op new-es)))))]
    [(If e1 e2 e3)
     (define-values (new-es sss)
       (for/lists (l1 l2) ([e (list e1 e2 e3)]) (rco-atom e)))
     (define ss (append* sss))
     (define tmp (gensym 'tmp))
     (match new-es
	    [(list e1 e2 e3)
	     (values (Var tmp)
             (append ss `((,tmp . ,(If e1 e2 e3)))))])]
    ))

(define (make-lets^ bs e)
  (match bs
    [`() e]
    [`((,x . ,e^) . ,bs^)
     (Let x e^ (make-lets^ bs^ e))]))

(define (rco-exp e)
  (match e
    [(Var x) (Var x)]
    [(Int n) (Int n)]
    [(Bool b) (Bool b)]
    [(Let x rhs body)
     (Let x (rco-exp rhs) (rco-exp body))]
    [(Prim op es)
     (define-values (new-es sss)
       (for/lists (l1 l2) ([e es]) (rco-atom e)))
     (make-lets^ (append* sss) (Prim op new-es))]
    [(If e1 e2 e3)
     (define-values (new-es sss)
       (for/lists (l1 l2) ([e (list e1 e2 e3)]) (rco-atom e)))
     (match new-es
	    [(list e1 e2 e3)
	     (make-lets^ (append* sss) (If e1 e2 e3))])]
    ))
```

## Explicate Control

### Example 1

```
(define (do-assignment exp var tail)
  (match exp
    [(Return (Int n)) (Seq (Assign var (Int n)) tail)]
    [(Return (Var x)) (Seq (Assign var (Var x)) tail)]
    [(Return (Bool bool)) (Seq (Assign var (Bool bool)) tail)]
    [(Return (Prim op es)) (Seq (Assign var (Prim op es)) tail)]
    [(Seq stmt seq-tail) (Seq stmt (do-assignment seq-tail var tail))]))

(define (explicate-assign exp var tail cgraph)
  (match exp
    [(If pred then else)
     (define tail-block (gensym "block"))
     (define-values (then-block then-vars then-graph) (explicate-assign then var (Goto tail-block) cgraph))
     (define-values (else-block else-vars else-graph) (explicate-assign else var (Goto tail-block) then-graph))
     (define-values (pred-exp pred-vars pred-cgraph) (explicate-pred pred then-block else-block else-graph))
     (values pred-exp (remove-duplicates (append then-vars else-vars pred-vars)) 
               (cons `(,tail-block . ,tail) pred-cgraph))]
    [(Let x exp body)
      (begin (define-values (exp-body body-vars body-graph) (explicate-assign body var tail cgraph))
             (define-values (body-tail vars newgraph) (explicate-assign exp (Var x) exp-body body-graph))
             (values body-tail (cons (Var x) (remove-duplicates (append body-vars vars))) newgraph))]
    [x (begin (define-values (exp-tail exp-vars exp-graph) (explicate-tail exp cgraph))
              (values (do-assignment exp-tail var tail) exp-vars exp-graph))
  ]))

(define (explicate-pred e true-block false-block cgraph)
  (match e
    [(Bool b) (values (if b true-block false-block) '() cgraph))]

    ;;[(Bool bool) 
    ;; (values (IfStmt (Prim 'eq? (list (Bool bool) (Bool #t))) (Goto true-lbl) (Goto false-lbl)) '() cgraph)]
     
    [(Var x) 
     (let ([true-lbl (gensym "block")]
           [false-blb (gensym "block")])
      (values (IfStmt (Prim 'eq? (list (Var x) (Bool #t))) (Goto true-lbl) (Goto false-lbl)) '() 
          ... cgraph ...)]
    [(Prim 'not (list var)) (values (IfStmt (Prim 'eq? (list var (Bool #f))) (Goto true-lbl) (Goto false-lbl)) '() cgraph)]
    [(Prim cmp es) (values (IfStmt (Prim cmp es) (Goto true-lbl) (Goto false-lbl)) '() cgraph)]
    [(Let x exp body)
      (begin (define-values (exp-body body-vars body-graph) (explicate-pred body true-lbl false-lbl cgraph))
             (define-values (tail vars tail-graph) (explicate-assign exp (Var x) exp-body body-graph)) 
             (values tail (cons (Var x) (remove-duplicates (append body-vars vars))) tail-graph))]
    [(If pred then else) 
     (let ([true-lbl (gensym "block")]
           [false-lbl (gensym "block")])
        (begin (define-values (then-exp then-vars then-cgraph) (explicate-pred then (Goto true-lbl) (Goto false-lbl) cgraph))
               (define-values (else-exp else-vars else-cgraph) (explicate-pred else (Goto true-lbl) (Goto false-lbl) then-cgraph))
               (define-values (pred-exp pred-vars pred-cgraph) (explicate-pred pred then-exp else-exp else-cgraph))
               (values pred-exp (remove-duplicates (append then-vars else-vars pred-vars))
                  ... pred-cgraph))))]
    ))
                                  
(define (explicate-tail e cgraph)
  (match e
      [(Var x) (values (Return (Var x)) '() cgraph)]
      [(Int n) (values (Return (Int n)) '() cgraph)]
      [(Bool bool) (values (Return (Bool bool)) '() cgraph)]
      [(Let x e body)
       (begin (define-values (exp-body body-vars body-graph) (explicate-tail body cgraph))
         (define-values (tail vars newgraph) (explicate-assign e (Var x) exp-body body-graph))
         (values tail (cons (Var x) (remove-duplicates (append body-vars vars))) newgraph))]
      [(Prim op es)
       (values (Return (Prim op es)) '() cgraph)]
      [(If pred then else)
        (let ([then-block (gensym "block")] [else-block (gensym "block")])
          (begin (define-values (then-exp then-vars then-cgraph) (explicate-tail then cgraph))
                 (define-values (else-exp else-vars else-cgraph) (explicate-tail else then-cgraph))
                 (define-values (pred-exp pred-vars pred-cgraph) (explicate-pred pred then-block else-block else-cgraph))
                 (values pred-exp (remove-duplicates (append then-vars else-vars pred-vars))
                      (cons `(,then-block . ,then-exp) (cons `(,else-block . ,else-exp) pred-cgraph)))))]
      ))

(define (explicate-control p)
  (match p
    [(Program info e)
     (begin (define-values (tail vars graph) (explicate-tail e '())) 
            (Program `((locals . ,vars)) (CFG (cons `(start . ,tail) graph))))]
    ))
```


### Example 2

```
(define Explicate-CFG '())

(define (add-to-cfg t)
  (define new-label (gensym "l"))
  (set! Explicate-CFG (cons (cons new-label t) Explicate-CFG))
  new-label)

(define (explicate-tail exp)
  (match  exp
    [(Int n) (values (Return (Int n)) '())]
    [(Var v) (values (Return (Var v)) '())]
    [(Bool bool) (values (Return (Bool bool)) '())]
    [(Prim rator rand) (values (Return (Prim rator rand)) '())]
    [(Let var exp body)
     (let*-values ([(let-body variables1) (explicate-tail body)]
                   [(assigned-tail variables2) (explicate-assign exp var let-body)])
       (values assigned-tail (cons var (append variables1 variables2))))]
    [(If cnd thn els)
     (let*-values ([(thn-tail vars1) (explicate-tail thn)]
                   [(els-tail vars2) (explicate-tail els)])
     (let-values ([(cnd-tail vars3) (explicate-pred cnd thn-tail els-tail)])
       (values cnd-tail (append vars1 vars2 vars3))))]))

(define (explicate-assign exp var tail)
  (match  exp
    [(Int n) (values (Seq (Assign (Var var) (Int n)) tail) '())]
    [(Var v) (values (Seq (Assign (Var var) (Var v)) tail) '())]
    [(Bool bool) (values (Seq (Assign (Var var) (Bool bool)) tail) '())]
    [(Prim rator rand) (values (Seq (Assign (Var var) (Prim rator rand)) tail) '())]
    [(Let var* exp body)
     (let*-values ([(body-tail vars1) (explicate-assign body var tail)]
                   [(exp-tail vars2) (explicate-assign exp var* body-tail)])
       (values exp-tail (cons var* (append vars1 vars2))))]
    [(If cnd thn els)
     (define label (add-to-cfg tail))
     (let*-values ([(thn-tail vars1) (explicate-assign thn var (Goto label))]
                   [(els-tail vars2) (explicate-assign els var (Goto label))]
                   [(cnd-tail vars3) (explicate-pred cnd thn-tail els-tail)])
       (values cnd-tail (append vars3 vars1 vars2)))]))

(define (explicate-pred e tail1 tail2)
  (match e
    [(Bool bool) (if bool (values tail1 '()) (values tail2 '()))]
    [(Var v)
     (define label1 (add-to-cfg tail1))
     (define label2 (add-to-cfg tail2))
     (values (IfStmt (Prim 'eq? (list (Var v) (Bool #t))) 
                     (Goto label1) (Goto label2)) 
             '())]
    [(Prim rator (list exp1 exp2))
     (define label1 (add-to-cfg tail1))
     (define label2 (add-to-cfg tail2))
     (define atm1 (gensym "rator-1-"))
     (define atm2 (gensym "rator-2-"))
     (let*-values ([(atm2-tail vars2) (explicate-assign exp2 atm2 (IfStmt (Prim rator (list (Var atm1) (Var atm2))) (Goto label1) (Goto label2)))]
                    [(atm1-tail vars1) (explicate-assign exp1 atm1 atm2-tail)])
        (values atm1-tail (cons atm1 (cons atm2 (append vars1 vars2)))))]
    [(Prim 'not (list exp))
     (define label1 (add-to-cfg tail1))
     (define label2 (add-to-cfg tail2))
     (values (IfStmt (Prim 'eq? (list exp (Bool #t))) (Goto label2) (Goto label1)) '())]
    [(Let var exp body)
      (define label1 (add-to-cfg tail1))
      (define label2 (add-to-cfg tail2))
      (define t (gensym "let-ec-"))
      (let*-values ([(body-tail vars1) (explicate-assign body t (IfStmt (Prim 'eq? (list (Var t) (Bool #t))) (Goto label1) (Goto label2)))]
                    [(exp-tail vars2) (explicate-assign exp var body-tail)])
        (values exp-tail (cons t (cons var (append vars1 vars2)))))]
    [(If cnd thn els)
     (define label1 (add-to-cfg tail1))
     (define label2 (add-to-cfg tail2))
     (let*-values ([(thn-block vars2) (explicate-pred thn (Goto label1) (Goto label2))]
                   [(els-block vars3) (explicate-pred els (Goto label1) (Goto label2))]
                   [(thn-label) (add-to-cfg thn-block)]
                   [(els-label) (add-to-cfg els-block)]
                   [(result vars) (explicate-pred cnd (Goto thn-label) (Goto els-label))]
                   )
       (values result (append vars vars2 vars3)))]
    ))

(define (explicate-control p)
  (set! Explicate-CFG '())
  (match p
    [(Program info e)
     (let-values ([(tail vars) (explicate-tail e)])
       (Program
        (list (cons 'locals vars))
        (CFG (cons (cons 'start tail) Explicate-CFG))))]
    ))

```

## Optimize Jumps

```
#lang racket
(require "utilities.rkt")
(require graph)
(provide (all-defined-out))

(define (is-trivial? block)
  (match block
    [(Goto label) #t]
    [else #f]))

(define (get-label block)
  (match block
    [(Goto label) label]))

(define (add-to-hash hash src-label goto-label)
  (hash-set! hash src-label goto-label)
  (hash-map hash 
    (lambda (k v) (if (equal? v src-label)
      (hash-set! hash k goto-label)
      (void))))
  hash)

(define (short-cut blocks)
  (define ret (make-hash))
  (for ([(label block) (in-dict blocks)])
          (if (is-trivial? block)
            (add-to-hash ret label (get-label block))
            (hash-set! ret label label)))
  ret)

(define (patch-tail hash tl)
  (match tl
    [(IfStmt cnd thn els) (IfStmt cnd (patch-tail hash thn) (patch-tail hash els))]
    [(Return exp) tl]
    [(Seq stmt tail) (Seq stmt (patch-tail hash tail))]
    [(Goto label) (Goto (hash-ref hash label))]
    ))

(define (patch-gotos short-cuts blocks)   
  (for/list ([(label block) (in-dict blocks)])
        (cons label (patch-tail short-cuts block))))

(define (optimize-jumps p)
  (match p
    [(Program info (CFG blocks))
      (define short-cuts (short-cut blocks))
      (define not-short-cut (filter (lambda (b) (or (not (is-trivial? (cdr b))) (equal? (car b) 'start))) blocks))
      (define patched (patch-gotos short-cuts not-short-cut))
      (define ref-graph (block-list->racketgraph patched))
      (define has-neighbors (filter (lambda (b) (or (has-vertex? ref-graph (car b)) (equal? (car b) 'start))) patched))
      (Program info (CFG (patch-gotos short-cuts has-neighbors)))]))

(define (build-graph-optimize label tail racket-cfg)
  (match tail
    [(Goto target) (add-directed-edge! racket-cfg target label)]
    [(IfStmt cnd thn els) (begin
                            (build-graph-optimize label thn racket-cfg)
                            (build-graph-optimize label els racket-cfg))]
    [(Seq stmt tl) (build-graph-optimize label tl racket-cfg)]
    [_ (void)]))

(define (block-list->racketgraph blocks)
  (define racket-cfg (directed-graph '()))
     (for ([(label block) (in-dict blocks)])
       (build-graph-optimize label block racket-cfg))
     racket-cfg)
```

## Select Instructions

```
(define (sel-ins-atm c0a)
  (match c0a
    [(Int n) (Imm n)]
    [(Var x) (Var x)]
    [(Bool b) 
     (match b
      [#t (Imm 1)]
      [#f (Imm 0)])]))

(define (sel-ins-stmt c0stmt)
  (match c0stmt
    [(Assign v e)
     (if (atm? e)
         (list (Instr 'movq (list (sel-ins-atm e) v)))
         (match e
           [(Prim 'read '())
            (list (Callq 'read_int)
                  (Instr 'movq (list (Reg 'rax) v)))]
           [(Prim '- (list atm))
            (define x86atm (sel-ins-atm atm))
            (if (equal? x86atm v)
                (list (Instr 'negq (list v)))
                (list (Instr 'movq (list x86atm v))
                      (Instr 'negq (list v))))]
           [(Prim '+ (list atm1 atm2))
            (define x86atm1 (sel-ins-atm atm1))
            (define x86atm2 (sel-ins-atm atm2))
            (cond [(equal? x86atm1 v) (list (Instr 'addq (list x86atm2 v)))]
                  [(equal? x86atm2 v) (list (Instr 'addq (list x86atm1 v)))]
                  [else (list (Instr 'movq (list x86atm1 v))
                              (Instr 'addq (list x86atm2 v)))])]
           [(Prim 'not (list atm))
            (if (eqv? v atm)
                (list (Instr 'xorq (list (Imm 1) v)))
                (list (let ([atm_ (sel-ins-atm atm)])
                        (Instr 'movq (list atm_ v)))
                      (Instr 'xorq (list (Imm 1) v))))]
           [(Prim 'eq? (list atm1 atm2))
            (let ([atm1_ (sel-ins-atm atm1)]
                  [atm2_ (sel-ins-atm atm2)]
                  [v_ (sel-ins-atm v)])
              (list
               (Instr 'cmpq (list atm2_ atm1_))
               (Instr 'set (list 'e (Reg 'al)))
               (Instr 'movzbq (list (Reg 'al) v_))))]
           [(Prim '< (list atm1 atm2))
           (let ([atm1_ (sel-ins-atm atm1)]
                  [atm2_ (sel-ins-atm atm2)]
                  [v_ (sel-ins-atm v)])
              (list
               (Instr 'cmpq (list atm2_ atm1_))
               (Instr 'set (list 'l (Reg 'al)))
               (Instr 'movzbq (list (Reg 'al) v_))))]))]))

(define (sel-ins-tail c0t)
  (match c0t
    [(Return e)
     (append (sel-ins-stmt (Assign (Reg 'rax) e))
             (list (Jmp 'conclusion)))]
    [(Seq stmt tail)
     (define x86stmt (sel-ins-stmt stmt))
     (define x86tail (sel-ins-tail tail))
     (append x86stmt x86tail)]
    [(Goto label)
     (list (Jmp label)) ]
    [(IfStmt (Prim 'eq? (list arg1 arg2)) (Goto label1) (Goto label2))
     (let ([arg1_ (sel-ins-atm arg1)]
           [arg2_ (sel-ins-atm arg2)])
       (list
        (Instr 'cmpq (list arg2_ arg1_))
        (JmpIf 'e label1)
        (Jmp label2)))]
    [(IfStmt (Prim '< (list arg1 arg2)) (Goto label1) (Goto label2))
     (let ([arg1_ (sel-ins-atm arg1)]
           [arg2_ (sel-ins-atm arg2)])
       (list
        (Instr 'cmpq (list arg2_ arg1_))
        (JmpIf 'l label1)
        (Jmp label2)))]))

(define (select-instructions p)
  (match p
    [(Program info (CFG es))
     (Program info (CFG (for/list ([ls es]) (cons (car ls) (Block '() (sel-ins-tail (cdr ls)))))))]))
```

## Remove Jumps

```
(define (fix-block instrs cfg removed-blocks all-blocks curr-block)
  (cond
    [(null? instrs) '()]
    [else (let ([instr (car instrs)])
            (match instr
              ;; check if the target has only this edge
              [(Jmp target) #:when (and (not (equal? target 'conclusion))
                                        (equal? (length (get-neighbors cfg target)) 1)
                                        (< (edge-weight cfg target curr-block) 2))
                            (begin
                              (set-add! removed-blocks target)
                              (append
                               (fix-block (Block-instr* (dict-ref all-blocks target)) cfg removed-blocks all-blocks curr-block)
                               (fix-block (cdr instrs) cfg removed-blocks all-blocks curr-block)))]
              [_ (cons instr (fix-block (cdr instrs) cfg removed-blocks all-blocks curr-block))]))]))

(define (remove-jumps p)
  (match p
    [(Program info (CFG blocks))
     ;; Get cfg
     (define r-cfg (dict-ref info 'r-cfg))
     ;; tsorted vertices
     (define vertices-order (tsort (transpose r-cfg)))
     ;;keep track of new blocks
     (define new-blocks '())
     ;;keep track of removed blocks
     (define removed-blocks (mutable-set))
     ;;remove jumps
     (for ([vert vertices-order])
       (if (not (set-member? removed-blocks vert))
           (let* ([instrs (Block-instr* (dict-ref blocks vert))]
                  [block-info (Block-info (dict-ref blocks vert))]
                  [new-instrs (fix-block instrs r-cfg removed-blocks blocks vert)]
                  [new-block (Block block-info new-instrs)])
             (set! new-blocks (cons (cons vert new-block) new-blocks)))
           (void)))
     ;;(display new-blocks)
     (Program info (CFG new-blocks))]))
```

## Uncover Live

### Example 1

```
(define (uncover-live p)
  (match p
    [(Program info (CFG e))
     (define cfg-with-edges
       (isomorph e))
     (define cfg-we-tp (transpose cfg-with-edges))
     (define reverse-top-order
       (tsort cfg-we-tp))
     (Program
      info
      (CFG
       (foldl
        (lambda (label cfg)
          (begin
            (define block (cdr (assv label e)))
            (define-values (instr+ bl-info)
              (match block
                [(Block bl-info instr+) (values instr+ bl-info)]))
            (define neighbors (get-neighbors cfg-with-edges label))
            (define live-after
              (foldr
               (lambda (nbr lv-after)
                 (set-union
                  lv-after
                  ; the lv-before of its neighbor
                  ; TODO this assv is failing? or see above
                  (begin
                    (match (cdr (assv nbr cfg))
                      [(Block bl-info instr+)
                       (car bl-info)]))))
               '()
               (filter (lambda (vtx) (not (eqv? vtx 'conclusion)))
                       neighbors)))
            (define liveness-blk (liveness instr+ live-after))
            (define blonk (Block liveness-blk instr+))
            (cons `(,label . ,blonk) cfg)))
        '()
        ; remove conclusion from liveness analysis since we have not
        ; created it yet
        (filter (lambda (vtx) (not (eqv? vtx 'conclusion)))
                reverse-top-order))))]))
```

### Example 2

```
(define/public (adjacent-instr s)
  (match s
    [(Jmp label)
     (cond [(string-suffix? (symbol->string label) "conclusion") (set)]
           [else (set label)])]
    [(JmpIf cc label) (set label)]
    [else (set)]))

(define (adjacent-instrs b)
  (match b
    [(Block info ss)
     (for/fold ([outs (set)]) ([s ss])
       (set-union outs (adjacent-instr s)))]
    ))

(define (CFG->graph cfg)
  (define G (directed-graph '()))
  (for ([label (in-dict-keys cfg)])
    (add-vertex! G label))
  (for ([(s b) (in-dict cfg)])
    (for ([t (adjacent-instrs b)])
      (add-directed-edge! G s t)))
  G)

(define (live-before label CFG-hash)
  (match (hash-ref CFG-hash label)
    [(Block info ss)
     (car (dict-ref info 'lives))]))

(define/public (uncover-live-CFG cfg)
  (define G (CFG->graph cfg))
  (define CFG-hash (make-hash))
  (for ([label (tsort (transpose G))])
    (define live-after
      (for/fold ([lives (set)])
                ([lbl (in-neighbors G label)])
        (set-union lives (live-before lbl CFG-hash))))
    (define new-block
      (uncover-live-block (dict-ref cfg label) live-after))
    (hash-set! CFG-hash label new-block)
    )
  (hash->list CFG-hash))

(define/override (uncover-live ast)
  (verbose "uncover-live " ast)
  (match ast
    [(Program info (CFG G))
     (Program info (CFG (uncover-live-CFG G)))]
    ))
```

## Patch Instructions 

```
(define (patch-instructions-instrs instr)
  (match instr
    [(Instr op (list (Deref r1 n1) (Deref r2 n2)))
     (list (Instr 'movq (list (Deref r1 n1) (Reg 'rax)))
           (Instr op (list (Reg 'rax) (Deref r2 n2))))]
    [(Instr 'movq (list (Reg r1) (Reg r2)))
     (cond
       [(equal? r1 r2) '()]
       [else (list instr)])]
    [(Instr 'cmpq (list  arg1 (Imm n)))
     (list (Instr 'movq (list (Imm n) (Reg 'rax)))
           (Instr 'cmpq (list arg1 (Reg 'rax))))]
    [(Instr 'movzbq (list  arg1 (Imm n)))
         (list (Instr 'movq (list (Imm n) (Reg 'rax)))
               (Instr 'mvzbq (list arg1 (Reg 'rax))))]
    [_ (list instr)]))

(define (patch-instructions-block block)
  (match block
    [(Block info instrs)
     (Block info (flatten (for/list ([instr instrs]) 
                            (patch-instructions-instrs instr))))]))

(define (patch-instructions p)
  (match p
    [(Program info (CFG blocks))
     (Program info (CFG (for/list ([block blocks]) 
                          (cons (car block) (patch-instructions-block (cdr block)))))) ]))
```
