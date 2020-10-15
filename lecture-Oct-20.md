# Compiling Functions, Example Translations

## Example 1

Source program:

    (define (add  [x : Integer] [y : Integer]) : Integer
       (+ x y))

    (add 40 2)

After shrink:

    (define (add  [x : Integer] [y : Integer]) : Integer
       (+ x y))

    (define (main) : Integer
        (add 40 2))

after uniquify:

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       (+ x10706 y10707))
    (define (main) : Integer
        (add10705 40 2))


after reveal-functions:

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       (+ x10706 y10707))
       
    (define (main ) : Integer
       (add10705 40 2))

after limit-functions

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       (+ x10706 y10707))
       
    (define (main ) : Integer
       'add10705 40 2))

skipping expose allocation

after remove-complex-opera*

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       (+ x10706 y10707))
       
    (define (main) : Integer
       (let ([tmp10708 add10705])
         (tmp10708 40 2)))

after explicate-control

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       add10705start:
          return (+ x10706 y10707);

    )
    (define (main) : Integer
        mainstart:
           tmp10708 = add10705;
           (tmp10708 40 2)
    )

skipping optimize-jumps

skipping uncover-locals

after instruction selection

    (define (add10705 ) : _
       add10705start:
          movq %rcx, x10706
          movq %rdx, y10707
          movq x10706, %rax
          addq y10707, %rax
          jmp add10705conclusion
    )
    (define (main ) : _
        mainstart:
           leaq 'add10705, tmp10708
           movq $40, %rcx
           movq $2, %rdx
           tailjmp tmp10708
     )

skipping remove-jumps

skipping uncover-live, build-interference

after allocate-registers

    (define (add10705 ) : _
       add10705start:
          movq %rcx, %rsi
          movq %rdx, %rcx
          movq %rsi, %rax
          addq %rcx, %rax
          jmp add10705conclusion
    )
    (define (main) : _
        mainstart:
           leaq 'add10705, %rsi
           movq $40, %rcx
           movq $2, %rdx
           tailjmp %rsi
    )

after patch instructions

    (define (add10705 ) : _
       add10705start:
          movq %rcx, %rsi
          movq %rdx, %rcx
          movq %rsi, %rax
          addq %rcx, %rax
          jmp add10705conclusion


    )(define (main ) : _
        mainstart:
           leaq 'add10705, %rsi
           movq $40, %rcx
           movq $2, %rdx
           movq %rsi, %rax
           tailjmp %rax


     )

after print-x86

    _add10709start:
        movq	%rcx, %rsi
        movq	%rdx, %rcx
        movq	%rsi, %rax
        addq	%rcx, %rax
        jmp _add10709conclusion

        .globl _add10709
        .align 16
    _add10709:
        pushq	%rbp
        movq	%rsp, %rbp
        jmp	_add10709start

    _add10709conclusion:
        popq	%rbp
        retq
    _mainstart:
        leaq	_add10709(%rip), %rsi
        movq	$40, %rcx
        movq	$2, %rdx
        movq	%rsi, %rax
        popq	%rbp
        jmp	*%rax

        .globl _main
        .align 16
    _main:
        pushq	%rbp
        movq	%rsp, %rbp
        movq	$16384, %rdi
        movq	$16, %rsi
        callq	_initialize
        movq	_rootstack_begin(%rip), %r15
        jmp	_mainstart

    _mainconclusion:
        popq	%rbp
        retq

## Example 2

