# Compiling Functions, Example Translations

## Example 1

source program:

    (define (add  [x : Integer] [y : Integer]) : Integer
       (+ x y))

    (add 40 2)

after shrink:

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
       ((fun-ref add10705) 40 2))

after limit-functions

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       (+ x10706 y10707))
       
    (define (main) : Integer
       ((fun-ref add10705) 40 2))

skipping expose allocation

after remove-complex-opera*

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       (+ x10706 y10707))
       
    (define (main) : Integer
       (let ([tmp10708 (fun-ref add10705)])
         (tmp10708 40 2)))

after explicate-control

    (define (add10705  [x10706 : Integer] [y10707 : Integer]) : Integer
       add10705start:
          return (+ x10706 y10707);
    )
    (define (main) : Integer
        mainstart:
           tmp10708 = (fun-ref add10705);
           (tmp10708 40 2)
    )

skipping optimize-jumps

skipping uncover-locals

after instruction selection

    (define (add10705) : _
       add10705start:
          movq %rcx, x10706
          movq %rdx, y10707
          movq x10706, %rax
          addq y10707, %rax
          jmp add10705conclusion
    )
    (define (main ) : _
        mainstart:
           leaq (fun-ref add10705), tmp10708
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
           leaq (fun-ref add10705), %rsi
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
    )
    (define (main ) : _
        mainstart:
           leaq (fun-ref add10705), %rsi
           movq $40, %rcx
           movq $2, %rdx
           movq %rsi, %rax
           tailjmp %rax
     )

after print-x86

        .globl _add10709
        .align 16
    _add10709:
        pushq	%rbp
        movq	%rsp, %rbp
        jmp	_add10709start
    _add10709start:
        movq	%rcx, %rsi
        movq	%rdx, %rcx
        movq	%rsi, %rax
        addq	%rcx, %rax
        jmp _add10709conclusion
    _add10709conclusion:
        popq	%rbp
        retq
        
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
    _mainstart:
        leaq	_add10709(%rip), %rsi
        movq	$40, %rcx
        movq	$2, %rdx
        movq	%rsi, %rax
        popq	%rbp
        jmp	*%rax
    _mainconclusion:
        popq	%rbp
        retq

## Example 2

source program:

    (define (m [a : Integer] [b : Integer] [c : Integer] [d : Integer]
               [e : Integer] [f : Integer] [g : Integer] [h : Integer]
               [i : Integer]) : Integer
       i)

    (m 777 776 775 774 773 772 771 770 42)

skipping shrink

after uniquify:

    (define (m4 [a5 : Integer] [b6 : Integer] [c7 : Integer] 
                [d8 : Integer] 
                [e9 : Integer] [f10 : Integer] [g11 : Integer] 
                [h12 : Integer] [i13 : Integer]) : Integer
       i13)
       
    (define (main) : Integer
       (m4 777 776 775 774 773 772 771 770 42))

after reveal-functions:

    (define (m4 [a5 : Integer] [b6 : Integer] [c7 : Integer] 
                [d8 : Integer]
                [e9 : Integer] 
                [f10 : Integer] [g11 : Integer] 
                [h12 : Integer] [i13 : Integer]) : Integer
       i13)
       
    (define (main) : Integer
       ((fun-ref m4)                              *****
        777 776 775 774 773 772 771 770 42))

after limit-functions:

    (define (m4 [a5 : Integer] [b6 : Integer] [c7 : Integer] 
                [d8 : Integer] 
                [e9 : Integer] 
                [vec14 : (Vector Integer Integer Integer Integer)]   *****
                ) : Integer
       (vector-ref vec14 3))                   *****
    (define (main) : Integer
       ((fun-ref m4) 777 776 775 774 773
        (vector 772 771 770 42)))              *****

after expose allocation:

    (define (m4 [a5 : Integer] [b6 : Integer] [c7 : Integer] [d8 : Integer] 
                [e9 : Integer]
                [vec14 : (Vector Integer Integer Integer Integer)]) : Integer
       (vector-ref vec14 3))
       
    (define (main) : Integer
        ((fun-ref m4) 777 776 775 774 773
          (let ([vecinit16 772])             *****
          (let ([vecinit17 771])
          (let ([vecinit18 770])
          (let ([vecinit19 42])
          (let ([collectret24 (if (< (+ (global-value free_ptr) 40) 
                                     (global-value fromspace_end))
                                  (void)
                                  (collect 40))])
          (let ([alloc15 (allocate 4 (Vector Integer Integer Integer Integer))])
          (let ([initret23 (vector-set! alloc15 0 vecinit16)])
          (let ([initret22 (vector-set! alloc15 1 vecinit17)])
          (let ([initret21 (vector-set! alloc15 2 vecinit18)])
          (let ([initret20 (vector-set! alloc15 3 vecinit19)])
           alloc15))))))))))))

skipping remove-complex-opera*

after explicate-control:

    (define (m4 [a5 : Integer] [b6 : Integer] [c7 : Integer] [d8 : Integer] 
                [e9 : Integer]
                [vec14 : (Vector Integer Integer Integer Integer)]) : Integer
       m4start:
          return (vector-ref vec14 3);
    )
    
    (define (main) : Integer
        block31:
           (collect 40)
           goto block29;
        block30:
           collectret24 = (void);
           goto block29;
        block29:
           alloc15 = (allocate 4 (Vector Integer Integer Integer Integer));
           initret23 = (vector-set! alloc15 0 vecinit16);
           initret22 = (vector-set! alloc15 1 vecinit17);
           initret21 = (vector-set! alloc15 2 vecinit18);
           initret20 = (vector-set! alloc15 3 vecinit19);
           (tail-call tmp25 777 776 775 774 773 alloc15)             *****
        mainstart:
           tmp25 = (fun-ref m4);           ***** (thanks to RCO)
           vecinit16 = 772;
           vecinit17 = 771;
           vecinit18 = 770;
           vecinit19 = 42;
           tmp26 = (global-value free_ptr);
           tmp27 = (+ tmp26 40);
           tmp28 = (global-value fromspace_end);
           if (< tmp27 tmp28)
              goto block30;
           else
              goto block31;
     )

skipping uncover-locals

after instruction selection:

    (define (m4) : _
       m4start:
          movq %rcx, a5                       *****
          movq %rdx, b6                       *****
          movq %rdi, c7                       *****
          movq %rsi, d8                       *****
          movq %r8, e9                        *****
          movq %r9, vec14                     *****
          movq vec14, %r11
          movq 32(%r11), %rax
          jmp m4conclusion
    )
    (define (main) : _
        block31:
           movq %r15, %rdi
           movq $40, %rsi
           callq collect
           jmp block29

        block30:
           movq $0, collectret24
           jmp block29

        block29:
           movq free_ptr(%rip), alloc15
           addq $40, free_ptr(%rip)
           movq alloc15, %r11
           movq $9, 0(%r11)
           movq alloc15, %r11
           movq vecinit16, 8(%r11)
           movq $0, initret23
           movq alloc15, %r11
           movq vecinit17, 16(%r11)
           movq $0, initret22
           movq alloc15, %r11
           movq vecinit18, 24(%r11)
           movq $0, initret21
           movq alloc15, %r11
           movq vecinit19, 32(%r11)
           movq $0, initret20
           movq $777, %rcx                              *****
           movq $776, %rdx                              *****
           movq $775, %rdi                              *****
           movq $774, %rsi                              *****
           movq $773, %r8                               *****
           movq alloc15, %r9                            *****
           tailjmp tmp25                                *****

        mainstart:
           leaq (fun-ref m4), tmp25                     *****
           movq $772, vecinit16
           movq $771, vecinit17
           movq $770, vecinit18
           movq $42, vecinit19
           movq free_ptr(%rip), tmp26
           movq tmp26, tmp27
           addq $40, tmp27
           movq fromspace_end(%rip), tmp28
           cmpq tmp28, tmp27
           jl block30
           jmp block31
    )

skipping allocate-registers

after patch instructions:

    (define (m4) : _
       m4start:
          movq %rcx, %r10
          movq %rdx, %rcx
          movq %rdi, %rcx
          movq %rsi, %rcx
          movq %r8, %rcx
          movq %r9, %rcx
          movq %rcx, %r11
          movq 32(%r11), %rax
          jmp m4conclusion
    )
    (define (main) : _
        block30:
           movq $0, %rcx
           jmp block29

        block29:
           movq free_ptr(%rip), %r9
           addq $40, free_ptr(%rip)
           movq %r9, %r11
           movq $9, 0(%r11)
           movq %r9, %r11
           movq %r13, 8(%r11)
           movq $0, %rcx
           movq %r9, %r11
           movq %r14, 16(%r11)
           movq $0, %rcx
           movq %r9, %r11
           movq -40(%rbp), %rax
           movq %rax, 24(%r11)
           movq $0, %rcx
           movq %r9, %r11
           movq %rbx, 32(%r11)
           movq $0, %rcx
           movq $777, %rcx
           movq $776, %rdx
           movq $775, %rdi
           movq $774, %rsi
           movq $773, %r8
           movq %r12, %rax                  *****
           tailjmp %rax                     *****

        mainstart:
           leaq (fun-ref m4), %r12
           movq $772, %r13
           movq $771, %r14
           movq $770, -40(%rbp)
           movq $42, %rbx
           movq free_ptr(%rip), %rdx
           addq $40, %rdx
           movq fromspace_end(%rip), %rcx
           cmpq %rcx, %rdx
           jl block30
           movq %r15, %rdi
           movq $40, %rsi
           callq collect
           jmp block29
    )

after print x86

    _m4start:
        movq	%rcx, %r10
        movq	%rdx, %rcx
        movq	%rdi, %rcx
        movq	%rsi, %rcx
        movq	%r8, %rcx
        movq	%r9, %rcx
        movq	%rcx, %r11
        movq	32(%r11), %rax
        jmp _m4conclusion

        .globl _m4
        .align 16
    _m4:
        pushq	%rbp
        movq	%rsp, %rbp
        jmp	_m4start

    _m4conclusion:
        popq	%rbp
        retq
    _block30:
        movq	$0, %rcx
        jmp _block29
    _block29:
        movq	_free_ptr(%rip), %r9
        addq	$40, _free_ptr(%rip)
        movq	%r9, %r11
        movq	$9, 0(%r11)
        movq	%r9, %r11
        movq	%rbx, 8(%r11)
        movq	$0, %rcx
        movq	%r9, %r11
        movq	%r13, 16(%r11)
        movq	$0, %rcx
        movq	%r9, %r11
        movq	%r14, 24(%r11)
        movq	$0, %rcx
        movq	%r9, %r11
        movq	-40(%rbp), %rax
        movq	%rax, 32(%r11)
        movq	$0, %rcx
        movq	$777, %rcx
        movq	$776, %rdx
        movq	$775, %rdi
        movq	$774, %rsi
        movq	$773, %r8
        movq	%r12, %rax
        addq	$16, %rsp                  ***** conclusion of main
        popq	%r14                       *****
        popq	%rbx                       *****
        popq	%r12                       *****
        popq	%r13                       *****
        popq	%rbp                       *****
        jmp	*%rax                          *****
    _mainstart:
        leaq	_m4(%rip), %r12            *****
        movq	$772, %rbx
        movq	$771, %r13
        movq	$770, %r14
        movq	$42, -40(%rbp)
        movq	_free_ptr(%rip), %rdx
        addq	$40, %rdx
        movq	_fromspace_end(%rip), %rcx
        cmpq	%rcx, %rdx
        jl _block30
        movq	%r15, %rdi
        movq	$40, %rsi
        callq	_collect
        jmp _block29

        .globl _main
        .align 16
    _main:
        pushq	%rbp
        movq	%rsp, %rbp
        pushq	%r13
        pushq	%r12
        pushq	%rbx
        pushq	%r14
        subq	$16, %rsp
        movq	$16384, %rdi
        movq	$16, %rsi
        callq	_initialize
        movq	_rootstack_begin(%rip), %r15
        jmp	_mainstart

    _mainconclusion:
        addq	$16, %rsp
        popq	%r14
        popq	%rbx
        popq	%r12
        popq	%r13
        popq	%rbp
        retq

# Lambda: Lexically Scoped Functions


## Example

    (define (f [x : Integer]) : (Integer -> Integer)
       (let ([y 4])
          (lambda: ([z : Integer]) : Integer
             (+ x (+ y z)))))

    (let ([g (f 5)])
      (let ([h (f 3)])
        (+ (g 11) (h 15))))


## Syntax

concrete syntax:

    exp ::= ... | (lambda: ([var : type]...) : type exp)
    R5 ::= def* exp

abstract syntax:

    exp ::= ... | (Lambda ([var : type]...) type exp)
    R5 ::= (ProgramDefsExp info def* exp)

    (Let var exp exp)

