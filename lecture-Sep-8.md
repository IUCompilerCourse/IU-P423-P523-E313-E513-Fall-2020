# Code Review

## `uniquify`

    (define (uniquify-exp symtab)
      (lambda (e)
        (match e
          [(Var x) (Var (get-sym-rep symtab x))] ;; (dict-ref symtab x)
          [(Int n) (Int n)]
          [(Let x e body)
           (let* ([new-sym (gensym x)]
                  [new-symtab (add-to-symtab symtab x new-sym)])
                  ;; (dict-set symtab x new-sym)
             (Let new-sym  ((uniquify-exp symtab) e)
               ((uniquify-exp new-symtab) body)))]
          [(Prim op es)
           (Prim op (for/list ([e es]) ((uniquify-exp symtab) e)))]
          )))

Example:

    (let ([x 10])
       (let ([x (+ x 1)])
         x))

    wrong:
    (let ([x.1 10])
       (let ([x.2 (+ x.2 1)])
         x.2))
         
    correct:
    (let ([x.1 10])
       (let ([x.2 (+ x.1 1)])
         x.2))


## `remove-complex-opera*`

    ;; rco-atom : exp -> exp * (var * exp) list
    (define (rco-atom e)
      (match e
        [(Var x) (values (Var x) '())]
        [(Int n) (values (Int n) '())]
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
        ))

    (define (make-lets bs e)
      (match bs
        [`() e]
        [`((,x . ,e^) . ,bs^)
         (Let x e^ (make-lets bs^ e))]))

    ;; rco-exp : exp -> exp
    (define (rco-exp e)
      (match e
        [(Var x) (Var x)]
        [(Int n) (Int n)]
        [(Let x rhs body)
         (Let x (rco-exp rhs) (rco-exp body))]
        [(Prim op es)
         (define-values (new-es sss)
           (for/lists (l1 l2) ([e es]) (rco-atom e)))
         (make-lets (append* sss) (Prim op new-es))]
        ))

## `explicate-control`

    (define (explicate-tail exp)
      (match exp
        [(Var x) (values (Return (Var x)) '())]
        [(Int n) (values (Return (Int n)) '())]
        [(Let lhs rhs body)
         (let*-values
             ([(body-c0 body-vars) (explicate-tail body)]
              [(new-tail new-rhs-vars) (explicate-assign lhs rhs body-c0)])
           (values new-tail (append new-rhs-vars body-vars)))]
        [(Prim op es)
         (values (Return (Prim op es)) '())]))

    (define (explicate-assign r1exp v c)
      (match r1exp
        [(Let x e body) 
         (define-values (tail let-binds) (explicate-assign body v c))
         (define-values (tail^ let-binds^) (explicate-assign e (Var x) tail))
         (values tail^ (cons x (append let-binds let-binds^)))]
        [else
          (values (Seq (Assign v r1exp) c) '())]
         ))

## `select-instructions`

    (define (select-instr-atm a)
      (match a
        [(Int i) (Imm i)]
        [(Var _) a]))

    (define (select-instr-assign v e)
      (match e
        [(Int i) 
         (list (Instr 'movq (list (select-instr-atm e) v)))]
        [(Var _)
         (list (Instr 'movq (list (select-instr-atm e) v)))]
        [(Prim 'read '())
         (list (Callq 'read_int)
               (Instr 'movq (list (Reg 'rax) v)))]
        [(Prim '- (list a))
         (list (Instr 'movq (list (select-instr-atm a) v))
               (Instr 'negq (list v)))]
        [(Prim '+ (list a1 a2))
         (list (Instr 'movq (list (select-instr-atm a1) v))
               (Instr 'addq (list (select-instr-atm a2) v)))]))

    (define (select-instr-stmt stmt)
      (match stmt
        [(Assign (Var v) (Prim '+ (list (Var v1) a2))) #:when (equal? v v1)
         (list (Instr 'addq (list (select-instr-atm a2) (Var v))))]
        [(Assign (Var v) (Prim '+ (list a1 (Var v2)))) #:when (equal? v v2)
         (list (Instr 'addq (list (select-instr-atm a1) (Var v))))]
        [(Assign v e)
         (select-instr-assign v e)]))

    (define (select-instr-tail t)
      (match t
        [(Seq stmt t*) 
         (append (select-instr-stmt stmt) (select-instr-tail t*))]
        [(Return (Prim 'read '())) 
         (list (Callq 'read_int) (Jmp 'conclusion))]
        [(Return e) (append
                     (select-instr-assign (Reg 'rax) e)
                     (list (Jmp 'conclusion)))]))

    (define (select-instructions p)
      (match p
        [(Program info (CFG (list (cons 'start t))))
         (Program info
           (CFG (list (cons 'start (Block '() (select-instr-tail t))))))]))

## `assign-homes`

    (define (calc-stack-space ls) (* 8 (length ls))

    (define (find-index v ls)
      (cond
        ;;[(eq? v (Var-name (car ls))) 1]
        [(eq? v (car ls)) 1]
        [else (add1 (find-index v (cdr ls)))]
        ))

    (define (assign-homes-imm i ls)
      (match i
        [(Reg reg) (Reg reg)]
        [(Imm int) (Imm int)]
        [(Var v) (Deref 'rbp (* -8 (find-index v (cdr ls))))]
       ))
       
    (define (assign-homes-instr i ls)
      (match i
        [(Instr op (list e1)) 
         (Instr op (list (assign-homes-imm e1 ls)))]
        [(Instr op (list e1 e2))
         (Instr op (list (assign-homes-imm e1 ls) (assign-homes-imm e2 ls)))]
        [else i]
        ))
        
    (define (assign-homes-block b ls)
      (match b
        [(Block info es) 
         (Block info (for/list ([e es]) (assign-homes-instr e ls)))]
        ))

    (define (assign-homes p)
      (match p
        [(Program info (CFG es)) 
         (Program (list (cons 'stack-space (calc-stack-space (cdr (car info)))))
           (CFG (for/list ([ls es]) 
             (cons (car ls) (assign-homes-block (cdr ls) (car info))))))]
        ))

## `patch-instructions`

    (define (patch-instr  instruction)
      (match instruction
        [(Instr op (list (Deref  reg off) (Deref reg2 off2)))
             (list (Instr 'movq (list (Deref reg off) (Reg 'rax)))
                   (Instr op (list (Reg 'rax) (Deref reg2 off2))))]
        [else (list instruction)]))

    (define (patch-block b)
      (match b
        [(Block '() instrs) (Block '() (append-map patch-instr instrs))]
        ))

    (define (patch-instructions p)
       (match p
        [(Program info (CFG B-list))
         (Program info
                  (CFG
                   (map
                    (lambda (x) `(,(car x) . ,(patch-block (cdr x)))) 
                    B-list)))]))

## `print-x86`

    (define (print-x86-imm e)
      (match e
        [(Deref reg i)
         (format "~a(%~a)" i reg)]
        [(Imm n) (format "$~a" n)]
        [(Reg r) (format "%~a" r)]
        ))

    (define (print-x86-instr e)
      (verbose "R1/print-x86-instr" e)
      (match e
        [(Callq f)
         (format "\tcallq\t~a\n" (label-name (symbol->string f)))]
        [(Jmp label) (format "\tjmp ~a\n" (label-name label))]
        [(Instr instr-name (list s d))
         (format "\t~a\t~a, ~a\n" instr-name
                 (print-x86-imm s) 
                 (print-x86-imm d))]
        [(Instr instr-name (list d))
         (format "\t~a\t~a\n" instr-name (print-x86-imm d))]
        [else (error "R1/print-x86-instr, unmatched" e)]
        ))

    (define (print-x86-block e)
      (match e
        [(Block info ss)
         (string-append* (for/list ([s ss]) (print-x86-instr s)))]
        [else
         (error "R1/print-x86-block unhandled " e)]))

    (define (print-x86 e)
      (match e
        [(Program info (CFG G))
         (define stack-space (dict-ref info 'stack-space))
         (string-append
          (string-append*
           (for/list ([(label block) (in-dict G)])
             (string-append (format "~a:\n" (label-name label))
                            (print-x86-block block))))
          "\n"
          (format "\t.globl ~a\n" (label-name "main"))
          (format "~a:\n" (label-name "main"))
          (format "\tpushq\t%rbp\n")
          (format "\tmovq\t%rsp, %rbp\n")
          (format "\tsubq\t$~a, %rsp\n" (align stack-space 16))
          (format "\tjmp ~a\n" (label-name 'start))
          (format "~a:\n" (label-name 'conclusion))
          (format "\taddq\t$~a, %rsp\n" (align stack-space 16))
          (format "\tpopq\t%rbp\n")
          (format "\tretq\n")
          )]
        [else (error "print-x86, unmatched" e)]
        ))

# Register Allocation

Main ideas:

* Put as many variables in registers as possible, and *spill* the rest
  to the stack.

* Variables that are not in use at the same time can be assigned to
  the same register.

## Registers and Calling Conventions

* caller-save registers

        rax rdx rcx rsi rdi r8 r9 r10 r11
	

* callee-save registers

    	rsp rbp rbx r12 r13 r14 r15

## Running Example

    (let ([v 1])
	  (let ([w 46])
		(let ([x (+ v 7)])
		  (let ([y x])
		    (let ([z (+ x w)])
		      (+ z (- y)))))))

After instruction selection:

    locals: (v w x y z t.2 t.1)
    movq $1, v
    movq $46, w
    movq v, x
    addq $7, x
    movq x, y
    movq x, z
    addq w, z
    movq y, t.1
    negq t.1
    movq z, t.2
    addq t.1, t.2
    movq t.2, %rax
    jmp conclusion

## Liveness Analysis

Goal: figure out the program regions where a variable is in use.

Def. A variable is *live* at a program point if the value in the
variable is used at some later point in the program.

The following equations compute the live before/after sets
for each instruction.
The instructions of the program are numbered 1 to n.

    L_after(k) = L_before(k + 1)
	L_after(n) = {}
	
	L_before(k) = (L_after(k) - W(k)) U R(k)
	
Here's the program with the live-after set next to each instruction.
Compute them from bottom to top.

    locals: (v w x y z t.2 t.1)
    movq $1, v                      {v}
    movq $46, w                     {v,w}
    movq v, x                       {w,x}
    addq $7, x                      {w,x}
    movq x, y                       {w,x,y}
    movq x, z                       {w,y,z}
    addq w, z                       {y,z} = ({t.1,z} - {t.1}) U {y}
    movq y, t.1                     {t.1,z} = ({t.1,z} - {t.1}) U {t.1}
    negq t.1                        {t.1,z} = ({t.1,t.2} - {t.2}) U {z}
    movq z, t.2                     {t.1,t.2} = ({t.2} - {t.2}) U {t.1,t.2}
    addq t.1, t.2                   {t.2} = ({} - {rax}) U {t.2}
    movq t.2, %rax                  {}
    jmp conclusion                  {}
