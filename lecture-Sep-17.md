# Concrete Syntax of R2

    bool ::= #t | #f
    cmp ::=  eq? | < | <= | > | >= 
    exp ::= int | (read) | (- exp) | (+ exp exp) | (- exp exp)
       |  var | (let ([var exp]) exp)
       | bool | (and exp exp) | (not exp) 
       | (cmp exp exp) | (if exp exp exp) 
    R2 ::= exp
    
New things:
* Boolean literals: `#t` and `#f`.
* Logical operators on Booleans: `and`, `or`, `not`.
* Comparison operators: `eq?`, `<`, etc.
* The `if` conditional expression. Branching!
* Subtraction on integers.


# Semantics of R2

    (define (interp-op op)
      (match op
        ...
        ['not (lambda (v) (match v [#t #f] [#f #t]))]
        ['eq? (lambda (v1 v2)
                (cond [(or (and (fixnum? v1) (fixnum? v2))
                           (and (boolean? v1) (boolean? v2)))
                       (eq? v1 v2)]))]
        ['< (lambda (v1 v2)
              (cond [(and (fixnum? v1) (fixnum? v2)) (< v1 v2)]))]
        ...))

    (define (interp-exp env)
      (lambda (e)
        (define recur (interp-exp env))
        (match e
          ...
          [(Bool b) b]
          [(If cnd thn els)
           (define b (recur cnd))
           (match b
             [#t (recur thn)]
             [#f (recur els)])]
          [(Prim 'and (list e1 e2))
           (define v1 (recur e1))
           (match v1
             [#t (match (recur e2) [#t #t] [#f #f])]
             [#f #f])]
          [(Prim op args)
           (apply (interp-op op) (for/list ([e args]) (recur e)))]
          )))

    (define (interp-R2 p)
      (match p
        [(Program info e)
         ((interp-exp '()) e)]
        ))

Things to note:
* Our treatment of Booleans and operations on them is strict in the
  sense that we don't allow other kinds of values (such as integers)
  to be treated as if they are Booleans.
* `and` is short-circuiting.
* The handling of primitive operators has been factored out
  into an auxilliary function named `interp-op`.


# Type errors and static type checking

In Racket:

    > (not 1)
    #f

    > (car 1)
    car: contract violation
      expected: pair?
      given: 1

In Typed Racket:

    > (not 1)
    #f

    > (car 1)
    Type Checker: Polymorphic function `car' could not be applied to arguments:
    Domains: (Listof a)
             (Pairof a b)
    Arguments: One
    in: (car 1)


A type checker, aka. type system, enforces at compile-time that only
the appropriate operations are applied to values of a given type.

To accomplish this, a type checker must predict what kind of value
will be produced by an expression at runtime.

Type checker:

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
          ...
          [else
           (error "type-check-exp couldn't match" e)])))

    (define (type-check env)
      (lambda (e)
        (match e
          [(Program info body)
           (define Tb ((type-check-exp '()) body))
           (unless (equal? Tb 'Integer)
             (error "result of the program must be an integer, not " Tb))
           (Program info body)]
          )))

How should the type checker handle the `if` expression?


# Shrinking R2

Several of the language forms in R2 are redundant and can be easily
expressed using other language forms. They are present in R2 to make
programming more convenient, but they do not fundamentally increase
the expressiveness of the language. 

To reduce the number of language forms that later compiler passes have
to deal with, we shrink R2 by translating away some of the forms.
For example, subtraction is expressible as addition and negation.

    (- e1 e2)   =>   (+ e1 (- e2))
    
The less-than-or-equal operation on integers is expressible using
less-than and not. Here's an incorrect first attempt:

    (<= e1 e2)  =>   (not (< e2 e1))                 wrong!

When compiling, one must always keep in mind that expressions
may contain side effects, such as `(read)`. Flipping the order
of `e1` and `e2` can change a program's behavior, which means
that the above transformation is incorrect. 


# More x86 with an eye toward instruction selection

    cc ::= e | l | le | g | ge
    instr ::= ... | xorq arg, arg | cmpq arg, arg | set<cc> arg
          | movzbq arg, arg | j<cc> label 

The x86 language does not have direct support for logical `not`.
But `xorq` can do the job:

          | 0 | 1 |
          |---|---|
        0 | 0 | 1 |
        1 | 1 | 0 |

    var = (not arg);       =>       movq arg, var
                                    xorq $1, var

The `cmpq` instruction can be used to implement `eq?`, `<`, etc.
But it's a bit strange. It puts the result in a mysterious
EFLAGS register.

    var = (< arg1 arg2)    =>       cmpq y, x
                                    setl %al
                                    movzbq %al, var

The `cmpq` instruction can also be used for conditional branching.
The conditional jump instructions `je`, `jl`, etc. also read
from the EFLAGS register.


    if (eq? arg1 arg2)    =>       cmpq arg2, arg1
      goto l1;                     je l1
    else                           jmp l2
      goto l2;


# The C1 intermediate language

Syntax of C1

    bool ::= #t | #f
    atm ::= int | var | bool
    cmp ::= eq? | < | <= | > | >=
    exp ::= ... | (not atm) (cmp atm atm)
    stmt ::= ...
    tail ::= ... 
         | goto label; 
         | if (cmp atm atm) 
             goto label; 
           else
             goto label;
    C1 ::= label1:
             tail1
           label2:
             tail2
           ...


# Explicate Control

Consider the following program

    (let ([x (read)])
      (let ([y (read)])
        (if (if (< x 1) (eq? x 0)  (eq? x 2))
            (+ y 2)
            (+ y 10))))

A straightforward way to compile an `if` expression is to recursively
compile the condition, and then use the `cmpq` and `je` instructions
to branch on its Boolean result. Let's first focus in the `(if (< x 1) ...)`.

    ...
    cmpq $1, x          ;; (< x 1)
    setl %al
    movzbq %al, tmp
    cmpq $1, tmp        ;; (if (< x 1) ...)
    je then_branch1
    jmp else_branch1
    ...

But notice that we used two `cmpq`, a `setl`, and a `movzbq`
when it would have been better to use a single `cmpq` with
a `jl`.

    callq read_int
    movq %rax, x
    callq read_int
    movq %rax, y
    cmpq $1, x          ;; (if (< x 1) ...)
    jl then_branch1
    jmp else_branch1
    ...
        
Ok, so we should recognize when the condition of an `if` is a
comparison, and specialize our code generation. But can we do even
better? Consider the outer `if` in the example program, whose
condition is not a comparison, but another `if`.  Can we rearrange the
program so that the condition of the `if` is a comparison?  How about
pushing the outer `if` inside the inner `if`:

    (let ([x (read)])
      (let ([y (read)])
        (if (< x 1) 
          (if (eq? x 0)
            (+ y 2)
            (+ y 10))
          (if (eq? x 2)
            (+ y 2)
            (+ y 10)))))

Unfortunately, now we've duplicated the two branches of the outer `if`.
A compiler must *never* duplicate code!

Now we come to the reason that our Cn programs take the forms of a
control flow *graph* instead of a *tree*. A graph allows multiple
edges to point to the save vertex, thereby enabling sharing instead of
duplication. Recall that the nodes of the control flow graph are
labeled `tail` statements and the edges are expressed with `goto`.

Using these insights, we can compile the example to the following C1
program.

    (let ([x (read)])
      (let ([y (read)])
        (if (if (< x 1) (eq? x 0)  (eq? x 2))
            (+ y 2)
            (+ y 10))))
    => 
    start:
        x = (read);
        y = (read);
        if (< x 1)
           goto inner_then;
        else
           goto inner_else;
    inner_then:
        if (eq? x 0)
           goto outer_then;
        else
           goto outer_else;
    inner_else:
        if (eq? x 2)
           goto outer_then;
        else
           goto outer_else;
    outer_then:
        return (+ y 2);
    outer_else:
        return (+ y 10);

Notice that we've acheived both objectives.
1. The condition of each `if` is a comparison.
2. We have not duplicated the two branches of the outer `if`.


A new function for compiling the condition expression of an `if`:

explicate-pred : R2_exp x C1_tail x C1_tail -> C1_tail x var list

    (explicate-pred #t B1 B2)  => B1
    
    (explicate-pred #f B1 B2)  => B2
    
    (explicate-pred (< atm1 atm2) B1 B2)  =>  if (< atm1 atm2)
                                                goto l1;
                                              else
                                                goto l2;
         where B1 and B2 are added to the CFG with labels l1 and l2.

    (explicate-pred (if e1 e2 e3) B1 B2)   =>   B5
         where we add B1 and B2 to the CFG with labels l1 and l2.
               (explicate-pred e2 (goto l1) (goto l2))   =>  B3
               (explicate-pred e3) (goto l1) (goto l2))  =>  B4
               (explicate-pred e1 B3 B3)                 =>  B5

explicate-tail : R2_exp -> C1_tail x var list

    (explicate-tail (if e1 e2 e3))   =>   B3
         where (explicate-tail e2) => B1
               (explicate-tail e3) => B2
               (explicate-pred e1 B1 B2) => B3


explicate-assign : R2_exp -> var -> C1_tail -> C1_tail x var list

    (explicate-assign (if e1 e2 e3) x B1)   =>   B4
         where we add B1 to the CFG with label l1
               (explicate-assign e2 x (goto l1))   =>   B2
               (explicate-assign e3 x (goto l1))   =>   B3
               (explicate-pred e1 B2 B3)           =>   B4
