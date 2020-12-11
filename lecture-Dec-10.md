# Review for Final Exam: Functions & Lambda

We reviewed lambda last time, so today we'll review functions.


Hypothetical alternative language with 2nd-class functions

    exp ::= ... | (Apply var exp...)
    def ::= (Def var ([var : type] ...) type '() exp)
    R4-2nd ::= (ProgramDefsExp '() (def ...) exp)

## Functions (R4)

Syntax:

    type ::= ... | (type... -> type)
    exp ::= ... | (Apply exp exp...)
    def ::= (Def var ([var : type] ...) type '() exp)
    R4 ::= (ProgramDefsExp '() (def ...) exp)

In R4, functions are *first class* values which means they can be
stored in vectors, passed as arguments to other functions, etc.

Functions in R4 are *not lexically scoped*, that is, the body of a
function cannot refer to a (non-global) variable defined outside the
function. To reinforce this point, the syntax of R4 only allows
function definitions at the top level, and not nested inside
expressions.

Example:

    (define (add1 [y : Integer]) : Integer
      (+ 1 y))

    (define (twice [f : (Integer -> Integer)] [x : Integer]) : Integer
      (+ (f x) (f x)))

    (twice add1 (read))

## Functions (x86)

A function is an address, i.e., the address of the first instruction
in the function's code.

We obtain the address of a function by using PC-relative addressing
on the label for the function.

    leaq	_twice65(%rip), %rcx

We call a function using the `callq` instruction with a `*` 
followed by a register that is holding the address of the function.

    callq	*%rcx

Calling conventions:

* Parameters are passed in these six registers, in order:

        rdi rsi rdx rcx r8 r9

  If there are more than six parameters, we pass parameters
  6 and higher in a vector that is passed in `r9`.

* return value is placed in `rax`.

* If a function uses callee-saved registers, it must
  save and restore them in the prelude and conclusion.
  
        rsp rbp r15 (rbx r12 r13 r14)
  
* We make sure not to use caller-saved registers for variables
  that are live during a call.

        rax r11 (rcx rdx rsi rdi r8 r9 r10)

Example:


        .globl _add64
        .align 16
    _add164:
        pushq	%rbp
        movq	%rsp, %rbp
        jmp	_add64start
    _add164start:
        movq	$1, %rax
        addq	%rdi, %rax
        jmp _add164conclusion
    _add164conclusion:
        popq	%rbp
        retq
        
        .globl _twice65
        .align 16
    _twice65:
        pushq	%rbp
        movq	%rsp, %rbp
        pushq	%r13               *** callee saved registers
        pushq	%r12
        pushq	%rbx
        subq	$8, %rsp           *** why this? 
                                   *** odd # of callee-saved
        jmp	_twice65start
    _twice65start:
        movq	%rdi, %rbx
        movq	%rsi, %r12
        movq	%r12, %rdi
        callq	*%rbx             *** call to f
        movq	%rax, %r13
        movq	%r12, %rdi
        callq	*%rbx             *** call to f
        movq	%rax, %rcx
        movq	%r13, %rax
        addq	%rcx, %rax
        jmp _twice65conclusion
    _twice65conclusion:
        addq	$8, %rsp
        popq	%rbx              *** callee saved registers
        popq	%r12
        popq	%r13
        popq	%rbp
        retq

        .globl _main
        .align 16
    _main:
        pushq	%rbp
        movq	%rsp, %rbp
        pushq	%r12
        pushq	%rbx
        movq	$65536, %rdi
        movq	$65536, %rsi
        callq	_initialize
        movq	_rootstack_begin(%rip), %r15
        jmp	_mainstart
    _mainstart:
        leaq	_twice65(%rip), %rbx
        leaq	_add164(%rip), %r12
        callq	_read_int
        movq	%rax, %rsi               *** tail call to twice
        movq	%r12, %rdi
        movq	%rbx, %rax
        popq	%rbx
        popq	%r12
        popq	%rbp
        jmp	*%rax
    _mainconclusion:
        popq	%rbx
        popq	%r12
        popq	%rbp
        retq


## Reveal Functions

Differentiate between function names and let-bound variables.

    (define (add147 [y49 : Integer]) : Integer
       (+ 1 y49)
    )

    (define (twice48 [f50 : (Integer -> Integer)] 
         [x51 : Integer]) : Integer
       (+ (f50 x51) (f50 x51))
    )

    (define (main) : Integer
       ((fun-ref twice48) (fun-ref add147) (read))
    )


## Limit Functions

Limit functions to 6 parameters. Use vectors for the extra ones.

## Remove Complex Operands

`FunRef` and `Apply` are complex. 
Arguments of `Apply` are atomic.

    (define (add147 [y49 : Integer]) : Integer
       (+ 1 y49))

    (define (twice48 [f50 : (Integer -> Integer)] 
                     [x51 : Integer]) : Integer
       (let ([tmp52 (f50 x51)])
          (let ([tmp53 (f50 x51)])
             (+ tmp52 tmp53))))

    (define (main) : Integer
       (let ([tmp54 (fun-ref twice48)])
          (let ([tmp55 (fun-ref add147)])
             (let ([tmp56 (read)])
                (tmp54 tmp55 tmp56)))))


## Explicate Control

Differentiate between calls and tail calls.

    (define (add147 [y49 : Integer]) : Integer
       add147start:
          return (+ 1 y49);
    )

    (define (twice48 [f50 : (Integer -> Integer)] 
                     [x51 : Integer]) : Integer
       twice48start:
          tmp52 = (call f50 x51);
          tmp53 = (call f50 x51);
          return (+ tmp52 tmp53);
    )

    (define (main) : Integer
       mainstart:
          tmp54 = (fun-ref twice48);
          tmp55 = (fun-ref add147);
          tmp56 = (read);
          (tail-call tmp54 tmp55 tmp56)
    )


## Select Instructions

1. FunRef: translate to PC-relative addressing of the function 
   label
2. Function calls: pass arguments in registers, get result 
   in `rax`, translate to `callq *`.
3. Function definitions: retrieve arguments from registers
4. Tail calls: use fake `tail-jmp` instruction to postpone 
   generated code for popping the frame.

Output:

    (define (add147) : Integer
       add147start:
          movq %rdi, y49                  ***
          movq $1, %rax
          addq y49, %rax
          jmp add147conclusion
    )

    (define (twice48) : Integer
       twice48start:
          movq %rdi, f50                ***
          movq %rsi, x51                ***
          movq x51, %rdi            ***
          callq *f50                ***
          movq %rax, tmp52
          movq x51, %rdi            ***
          callq *f50                ***
          movq %rax, tmp53
          movq tmp52, %rax
          addq tmp53, %rax
          jmp twice48conclusion
    )

    (define (main) : Integer
       mainstart:
          leaq (fun-ref twice48), tmp54          ***
          leaq (fun-ref add147), tmp55           ***
          callq read_int
          movq %rax, tmp56
          movq tmp55, %rdi              ***
          movq tmp56, %rsi              ***
          tail-jmp tmp54                ***
    )


## Register Allocation


An example with functions and vectors (example in book):

    (define (map [f : (Integer -> Integer)] 
                 [v : (Vector Integer Integer)])
                 : (Vector Integer Integer)
      (vector (f (vector-ref v 0)) (f (vector-ref v 1))))
      
    (define (add1 [x : Integer]) : Integer (+ x 1))
    
    (vector-ref (map add1 (vector 0 41)) 1)


After instruction selection:

    (define (map47) : Integer
       block75:
          movq %r15, %rdi
          movq $24, %rsi
          callq collect
          jmp block73

       block74:
          movq $0, _57
          jmp block73

       block73:
          movq free_ptr(%rip), %r11
          addq $24, free_ptr(%rip)
          movq $5, 0(%r11)
          movq %r11, alloc52
          movq alloc52, %r11
          movq vecinit53, 8(%r11)
          movq $0, _56
          movq alloc52, %r11
          movq vecinit54, 16(%r11)
          movq $0, _55
          movq alloc52, %rax
          jmp map47conclusion

       map47start:
          movq %rdi, f49
          movq %rsi, v50
          movq v50, %r11
          movq 8(%r11), tmp62
          movq tmp62, %rdi
          callq *f49
          movq %rax, vecinit53
          movq v50, %r11
          movq 16(%r11), tmp63
          movq tmp63, %rdi
          callq *f49
          movq %rax, vecinit54
          movq free_ptr(%rip), tmp64
          movq tmp64, tmp65
          addq $24, tmp65
          movq fromspace_end(%rip), tmp66
          cmpq tmp66, tmp65
          jl block74
          jmp block75


    )

    (define (add48) : Integer
       add48start:
          movq %rdi, x51
          movq x51, %rax
          addq $1, %rax
          jmp add48conclusion
    )

    (define (main) : Integer
       block78:
          movq %r15, %rdi
          movq $24, %rsi
          callq collect
          jmp block76

       block77:
          movq $0, _61
          jmp block76

       block76:
          movq free_ptr(%rip), %r11
          addq $24, free_ptr(%rip)
          movq $5, 0(%r11)
          movq %r11, alloc58
          movq alloc58, %r11
          movq $0, 8(%r11)
          movq $0, _60
          movq alloc58, %r11
          movq $41, 16(%r11)
          movq $0, _59
          movq tmp68, %rdi
          movq alloc58, %rsi
          callq *tmp67
          movq %rax, tmp72
          movq tmp72, %r11
          movq 16(%r11), %rax
          jmp mainconclusion

       mainstart:
          leaq (fun-ref map47), tmp67
          leaq (fun-ref add48), tmp68
          movq free_ptr(%rip), tmp69
          movq tmp69, tmp70
          addq $24, tmp70
          movq fromspace_end(%rip), tmp71
          cmpq tmp71, tmp70
          jl block77
          jmp block78
    )

After register allocation:

    (define (map47) : Integer
       map47start:
          movq %rdi, %r12
          movq %rsi, -8(%r15)            *****
          movq -8(%r15), %r11
          movq 8(%r11), %rdi
          movq %rdi, %rdi
          callq *%r12
          movq %rax, %rbx
          movq -8(%r15), %r11
          movq 16(%r11), %rdi
          movq %rdi, %rdi
          callq *%r12
          movq %rax, %r12
          movq free_ptr(%rip), %rcx
          movq %rcx, %rcx
          addq $24, %rcx
          movq fromspace_end(%rip), %rdx
          cmpq %rdx, %rcx
          jl block74
          jmp block75

       block75:
          movq %r15, %rdi
          movq $24, %rsi
          callq collect
          jmp block73

       block74:
          movq $0, %rcx
          jmp block73

       block73:
          movq free_ptr(%rip), %r11
          addq $24, free_ptr(%rip)
          movq $5, 0(%r11)
          movq %r11, %rcx
          movq %rcx, %r11
          movq %rbx, 8(%r11)
          movq $0, %rdx
          movq %rcx, %r11
          movq %r12, 16(%r11)
          movq $0, %rdx
          movq %rcx, %rax
          jmp map47conclusion
    )

    (define (add48) : Integer
       add48start:
          movq %rdi, %rdi
          movq %rdi, %rax
          addq $1, %rax
          jmp add48conclusion
    )

    (define (main) : Integer
       block78:
          movq %r15, %rdi
          movq $24, %rsi
          callq collect
          jmp block76

       block77:
          movq $0, %rcx
          jmp block76

       block76:
          movq free_ptr(%rip), %r11
          addq $24, free_ptr(%rip)
          movq $5, 0(%r11)
          movq %r11, %rsi
          movq %rsi, %r11
          movq $0, 8(%r11)
          movq $0, %rcx
          movq %rsi, %r11
          movq $41, 16(%r11)
          movq $0, %rcx
          movq %r12, %rdi
          movq %rsi, %rsi
          callq *%rbx
          movq %rax, %rcx
          movq %rcx, %r11
          movq 16(%r11), %rax
          jmp mainconclusion

       mainstart:
          leaq (fun-ref map47), %rbx
          leaq (fun-ref add48), %r12
          movq free_ptr(%rip), %rcx
          movq %rcx, %rcx
          addq $24, %rcx
          movq fromspace_end(%rip), %rdx
          cmpq %rdx, %rcx
          jl block77
          jmp block78
    )

