Overview of the Passes
----------------------

    R1
    |    uniquify
    V
    R1'
    |    remove-complex-opera*
    V
    R1''
    |    explicate-control
    V
    C0
    |    select instructions
    V
    x86*
    |    assign homes
    V
    x86*
    |    patch instructions
    V
    x86
    |    print x86
    V
    x86-in-text

Uniquify
--------

This pass gives a unique name to every variable, so that variable
shadowing and scope are no longer important.

We recommend using `gensym` to generate a new name for each variable
bound by a `let` expression.

To update variable occurences to match the new names, use an
association list to map the old names to the new names, extending this
map in the case for `let` and doing a lookup in the case for
variables.

Examples:

    (let ([x 32])
      (let ([y 10])
        (+ x y)))
    =>
    (let ([x.1 32])
      (let ([y.2 10])
        (+ x.1 y.2)))


    (let ([x 32])
      (+ (let ([x 10]) x) x))
    =>
    (let ([x.1 32])
      (+ (let ([x.2 10]) x.2) x.1))


Remove Complex Operators and Operands
-------------------------------------

This pass makes sure that the arguments of each operation are atomic
expressions, that is, variables or integer constants. The pass
accomplishes this goal by inserting temporary variables to replace the
non-atomic expressions with variables.

Examples:

    (+ (+ 42 10) (- 10))
    =>
    (let ([tmp.1 (+ 42 10)])
      (let ([tmp.2 (- 10)])
        (+ tmp.1 tmp.2)))


    (let ([a 42])
      (let ([b a])
        b))
    =>
    (let ([a 42])
      (let ([b a])
        b))

and not

    (let ([tmp.1 42])
      (let ([a tmp.1])
        (let ([tmp.2 a])
          (let ([b tmp.2])
            b))))


Grammar of the output:

    atm ::= var | int
    exp ::= atm | (read) | (- atm) | (+ atm atm) 
        | (let ([var exp]) exp)
    R1'' ::= exp

Recommended function organization:

    rco-atom : exp -> atm * (var * exp) list

    rco-exp : exp -> exp

Inside `rco-atom` and `rco-exp`, for recursive calls,
use `rco-atom` when you need the result to be an atom
and use `rco-exp` when you don't care.


Explicate Control
-----------------

This pass makes the order of evaluation explicit in the syntax.
For now, this means flattening `let` into a sequence of
assignment statements.

The target of this pass is the C0 language.
Here is the grammar for C0.

    atm ::= int | var
    exp ::= atm | (read) | (- atm) | (+ atm atm)
    stmt ::= var = exp; 
    tail ::= return exp; | stmt tail 
    C0 ::= (label: tail)^+
    
Example:

    (let ([x (let ([y (- 42)])
               y)])
      (- x))
    =>
    locals:
      '(x y)
    start:
        y = (- 42);
        x = y;
        return (- x);

Aside regarding **tail position**. Here is the grammar for R1'' again
but splitting the exp non-terminal into two, one for `tail` position
and one for not-tail `nt` position.

    atm ::= var | int
    nt ::= atm | (read) | (- atm) | (+ atm atm) 
       | (let ([var nt]) nt)
    tail ::= atm | (read) | (- atm) | (+ atm atm) 
         | (let ([var nt]) tail)
    R1'' ::= tail

Recommended function organization:

    explicate-tail : exp -> tail * var list
    
    explicate-assign : exp -> var -> tail -> tail * var list

The `explicate-tail` function takes and R1 expression in tail position
and returns a C0 tail and a list of variables that use to be let-bound
in the expression. This list of variables is then stored in the `info`
field of the `Program` node.

The `explicate-assign` function takes 1) an R1 expression that is not
in tail position, that is, the right-hand side of a `let`, 2) the
`let`-bound variable, and 3) the C0 tail for the body of the `let`.
The output of `explicate-assign` is a C0 tail and a list of variables
that were let-bound. 

Here's a trace of these two functions on the above example.

    explicate-tail (let ([x (let ([y (- 42)]) y)]) (- x))
      explicate-tail (- x)
        => {return (- x);}, ()
      explicate-assign (let ([y (- 42)]) y) x {return (- x);}
        explicate-assign y x {return (- x);}
          => {x = y; return (- x)}, ()
        explicate-assign (- 42) y {x = y; return (- x);}
          => {y = (- 42); x = y; return (- x);}, ()
        => {y = (- 42); x = y; return (- x);}, (y)
      => {y = (- 42); x = y; return (- x);}, (x y)


