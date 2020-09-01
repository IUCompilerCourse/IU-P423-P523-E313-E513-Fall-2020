

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
    exp ::= atm | (read) | (- atm) | (+ atm atm) | (let ([var exp]) exp)
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
    nt ::= atm | (read) | (- atm) | (+ atm atm) | (let ([var nt]) nt)
    tail ::= atm | (read) | (- atm) | (+ atm atm) | (let ([var nt]) tail)
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


Select Instructions
-------------------

Translate statements into x86-style instructions.

For example

	x = (+ 10 32);
	=>
	movq $10, x
	addq $32, x

Some cases can be handled with a single instruction.

	x = (+ 10 x);
	=>
	addq $10, x
    

The `read` operation must be turned into a 
call to the `read_int` function in `runtime.c`.

	x = (read);
	=>
	callq read_int
	movq %rax x
	
The return statement is treated like an assignment to `rax` followed
by a jump to the `conclusion` label.

	return e;
	=>
    instr
    jmp conclusion
    
where

    rax = e;
    =>
    instr
	
    
The Stack and Procedure Call Frames
-----------------------------------

The stack is a conceptually sequence of frames, one for each procedure
call. The stack grows down.

The *base pointer* `rbp` is used for indexing into the frame.

The *stack poitner* `rsp` points to the top of the stack.

| Position  | Contents       |
| --------- | -------------- |
| 8(%rbp)   | return address |
| 0(%rbp)   | old rbp        |
| -8(%rbp)  | variable 1     |
| -16(%rbp) | variable 2     |
| -24(%rbp) | variable 3     |
|   ...     |    ...         |
| 0(%rsp)   | variable n     |


Assign Homes
------------

Replace variables with stack locations.

Consider the program `(+ 52 (- 10))`.

Suppose we have two variables in the pseudo-x86, `tmp.1` and `tmp.2`.
We places them in the -16 and -8 offsets from the base pointer `rbp`
using the `deref` form.

	movq $10, tmp.1
	negq tmp.1
	movq tmp.1, tmp.2
	addq $52, tmp.2
	movq tmp.2, %rax
    =>
	movq $10, -16(%rbp)
	negq -16(%rbp)
	movq -16(%rbp), -8(%rbp)
	addq $52, -8(%rbp)
	movq -8(%rbp), %rax
	

Patch Instructions
------------------

Continuing the above example, we need to ensure that
each instruction follows the rules of x86. 

For example, the move from stack location -16 to -8 uses two memory
locations in the same instruction. So we split it up into two
instructions and use rax to hold the value at location -16.

	movq $10 -16(%rbp)
	negq -16(%rbp)
	movq -16(%rbp) -8(%rbp) *
	addq $52 -8(%rbp)
	movq -8(%rbp) %rax
    =>
	movq $10 -16(%rbp)
	negq -16(%rbp)
	movq -16(%rbp), %rax *
	movq %rax, -8(%rbp)  *
	addq $52, -8(%rbp)
	movq -8(%rbp), %rax
    

Print x86
---------

Translate the x86 AST into a string in the form of the x86 concrete
syntax.

We also need to include a prelude and conclusion for the main
procedure, and insert a call to print_int using rdi for parameter
passing.

The return address is saved to the stack by the caller (For the `main`
function, the caller is the operating system.)

The prelude must 
1. save the old base pointer, 
2. move the base pointer to the top of the stack
3. move the stack pointer down passed all the local variables.
4. jump to the start label

The conclusion must
1. move the stack pointer up passed all the local variables
2. pops the old base pointer
3. returns from the `main` function via `retq` 

Continuing the above example

    start:
		movq	$10, -16(%rbp)
		negq	-16(%rbp)
		movq	-16(%rbp), %rax
		movq	%rax, -8(%rbp)
		addq	$52, -8(%rbp)
		movq	-8(%rbp), %rax
        jmp     conclusion
        
		.globl _main
	main:
		pushq	%rbp
		movq	%rsp, %rbp
		subq	$16, %rsp
        jmp start

    conclusion:
		addq	$16, %rsp
		popq	%rbp
		retq
    
