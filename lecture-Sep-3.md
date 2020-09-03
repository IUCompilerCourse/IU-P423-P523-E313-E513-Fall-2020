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
        movq    $10, -16(%rbp)
        negq    -16(%rbp)
        movq    -16(%rbp), %rax
        movq    %rax, -8(%rbp)
        addq    $52, -8(%rbp)
        movq    -8(%rbp), %rax
        jmp     conclusion
        
        .globl _main
    main:
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $16, %rsp
        jmp start

    conclusion:
        addq    $16, %rsp
        popq    %rbp
        retq
    
