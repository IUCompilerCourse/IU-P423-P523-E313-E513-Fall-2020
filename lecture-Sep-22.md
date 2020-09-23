# Example x86 output from running example

Input R1 program:

    (let ([v 1])
      (let ([w 42])
        (let ([x (+ v 7)])
          (let ([y x])
             (let ([z (+ x w)])
               (+ z (- y)))))))

using two registers: rbx, rcx

      | Color |   Home    |
      |-------|-----------|
    t |    0  |  rbx      |
    v |    0  |  rbx      |
    w |    2  | -16(%rbp) |
    x |    0  |  rbx      |
    y |    0  |  rbx      |
    z |    1  |  rcx      |

Output x86:

    start:
        movq	$1, %rbx
        movq	$42, -16(%rbp)
        addq	$7, %rbx
        movq	%rbx, %rcx
        addq	-16(%rbp), %rcx
        negq	%rbx
        movq	%rcx, %rax
        addq	%rbx, %rax
        jmp conclusion

        .globl main
    main:
        pushq	%rbp
        movq	%rsp, %rbp
        pushq	%rbx
        subq	$8, %rsp
        jmp start
        
    conclusion:
        addq	$8, %rsp
        popq	%rbx
        popq	%rbp
        retq


    (let ([x1 (read)])
      (let ([x2 (read)])
        (+ (+ x1 x2)
           42)))
       
    _start:
        callq	_read_int
        movq	%rax, %rbx
        callq	_read_int
        movq	%rax, %rcx
        addq	%rcx, %rbx
        movq	%rbx, %rax
        addq	$42, %rax
        jmp _conclusion

        .globl _main
    _main:
        pushq	%rbp
        movq	%rsp, %rbp
        pushq	%rbx
        subq	$8, %rsp
        jmp _start
    _conclusion:
        addq	$8, %rsp
        popq	%rbx
        popq	%rbp
        retq


       
# Code Review of Register Allocation

## Liveness Analysis

    uncover-live
      uncover-line-block
        uncover-live-stmts
          uncover-live-instr **
            write-vars
            read-vars

## Build Interference

    build-interference  (print-dot)
      build-interference-block
        build-interference-instr **

## Allocate Registers

    allocate-registers
      color-graph **
        choose-color
      identify-home
      assign-homes-block (no change)


