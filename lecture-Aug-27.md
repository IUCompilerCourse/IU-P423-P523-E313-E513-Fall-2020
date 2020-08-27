# August 27


## Teams and Github Repositories

## Definitional Interpreters `interp-R0.rkt`, `R0-interp-example.rkt`

    Draw correctness diagram.

## The R1 Language: R0 + variables and let

    exp ::= int | (read) | (- exp) | (+ exp exp) 
          | var | (let ([var exp]) exp)
    R1 ::= exp

Examples:

    (let ([x (+ 12 20)])
      (+ 10 x))

    (let ([x 32]) 
      (+ (let ([x 10]) x) 
         x))

Interpreter for R1: `interp-R1.rkt`

## x86 Assembly Language

	reg ::= rsp | rbp | rsi | rdi | rax | .. | rdx  | r8 | ... | r15
	arg ::=  $int | %reg | int(%reg) 
	instr ::= addq  arg, arg |
			  subq  arg, arg |
			  negq  arg | 
			  movq  arg, arg | 
			  callq label |
			  pushq arg | 
			  popq arg | 
			  retq 
	prog ::=  .globl main
			   main:  instr^{+}


Intel Machine:
    * program counter
    * registers
    * memory (stack and heap)

Example program:

	(+ 10 32)

    =>

		.globl main
	main:
		movq	$10, %rax
		addq	$32, %rax
		movq	%rax, %rdi
		callq	print_int
		movq    $0, %rax
		retq


## What's different?

1. 2 args and return value vs. 2 arguments with in-place update
2. nested expressions vs. atomic expressions
3. order of evaluation: left-to-right depth-first, vs. sequential
4. unbounded number of variables vs. registers + memory
5. variables can overshadow vs. uniquely named registers + memory

* `select-instructions`: convert each R1 operation into a sequence
  of instructions
* `remove-complex-opera*`: ensure that each sub-expression is
  atomic by introducing temporary variables
* `explicate-control`: convert from the AST to a control-flow graph
* `assign-homes`: replace variables with stack locations
* `uniquify`: rename variables so they are all unique


In what order should we do these passes?
	
Gordian Knot: 
* instruction selection
* register/stack allocation

solution: do instruction selection optimistically, assuming all
	  registers then do register allocation then patch up the
	  instructions


	R_1
	|    uniquify
	V
	R_1
	|    remove-complex-opera*
	V
    R_1
    |    explicate-control
    V
	C_0
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
	x86 string




    
