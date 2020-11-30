# Compiling Assignment and Begin

Example program:

    (let ([sum 0])
      (let ([i 5])
        (begin
          (while (> i 0)
            (begin
              (set! sum (+ sum i))
              (set! i (- i 1))))
          sum)))

An example that involves `lambda`:

    (let ([x 0])
      (let ([y 0])
        (let ([z 20])
          (let ([f (lambda: ([a : Integer]) : Integer (+ a (+ x z)))])
            (begin
              (set! x 10)
              (set! y 12)
              (f y))))))

Yet another example:

    (define (f [x : Integer]) : (Vector ( -> Integer) ( -> Void))
      (vector
       (lambda: () : Integer x)
       (lambda: () : Void (set! x (+ 1 x)))))

    (let ([counter (f 0)])
      (let ([get (vector-ref counter 0)])
        (let ([inc (vector-ref counter 1)])
          (begin
            (inc)
            (get)))))

## Convert Assignments

To extend the lifetime of variables, we can "box" them, that is, put
them on the heap.

If a variable is never on the LHS of a `set!`, then there is no need
to box it. We can copy its value into a closure to extend its live.

If a variable is not free in any `lambda`, then there is also no need
to box it. We can translate `set!` into assignment in C_3.

So in this example, we box `x` but not `y`, `z`, and `a`.

    (let ([x 0])
      (let ([y 0])
        (let ([z 20])
          (let ([f (lambda: ([a : Integer]) : Integer (+ a (+ x z)))])
            (begin
              (set! x 10)
              (set! y 12)
              (f y))))))

    ==>

    (define (main) : Integer
      (let ([x0 (vector 0)])
        (let ([y1 0])
          (let ([z2 20])
            (let ([f4 (lambda: ([a3 : Integer]) : Integer
                          (+ a3 (+ (vector-ref x0 0) z2)))])
              (begin 
                (vector-set! x0 0 10)
                (set! y1 12)
                (f4 y1)))))))

To determine which variables to box, create a auxiliary function
`assigned&free` that returns the set of variables that are
assigned-to, the set of variables that are free-in-a-lambda, and an
updated expression in which the bound variables that are both
assigned-to and free-in-a-lambda have been marked with the
`AssignedFree` AST node.

Recipe for boxing a variable:

1. initialize the variable with a one-element vector containing the
   original initializer.
   
        (Let (AssignedFree x) e body)
        ==>
        (Let x (Prim 'vector (list e')) body')

2. change uses of the variable to `vector-ref`.

        (Var x)
        ==>
        (Prim 'vector-ref (list (Var x) (Int 0)))

3. change `set!` with the variable on the LHS to a `vector-set!`.

        (SetBang x e)
        ==>
        (Prim 'vector-set! (list (Var x) (Int 0) e'))


## Remove Complex Operands

The `while`, `set!`, and `begin` expressions are all complex.
Their subexpressions are allowed to be complex.


## Explicate Control

To handle `begin`, we need a new auxiliary function:
`explicate-effect`.  It takes an expression and a continuation block
and produces a block that performs the effects in the expression
followed by the block.

### Integers

    (explicate-effect (Int n) cont)
    ==>
    cont

### Assignment

    (explicate-effect (SetBang x e) cont)
    ==>
    e^
    
where

    e^ = (explicate-assign x e cont)

### Begin
    
    (explicate-effect (Begin es body) cont)
    ==>
    es'
    
where

    body' = (explicate-effect body cont)
    
and `es'` is the reslult of applying `explicate-effect` to each
expression in `es`, back-to-front, using `body'` as the initial
continuation. (Hint: use `for/foldr`.)

### Apply

    (explicate-effect (Call e es) cont)
    ==>
    (Seq (Call e es) (force cont))

There are three new kinds of statements in C_7:
1. `Call`
2. `read`
3. `vector-set!`


## Select Instructions

Add cases for the three new statements: `Call`, `read`, and
`vector-set!` by adapting the code generation for those forms in
assignment position.


## Register Allocation

Use dataflow analysis in `uncover-live`.


