# Compiling Functions

## The R4 Language

Concrete Syntax:

    type ::= ... | (type... -> type)
    exp ::= ... | (exp exp...)
    def ::= (define (var [var : type]...) : type exp)
    R4 ::= def... exp

Abstract Syntax:

    exp ::= ... | (Apply exp exp...)
    def ::= (Def var ([var : type] ...) type '() exp)
    R4 ::= (ProgramDefsExp '() (def ...) exp)

* Because of the function type `(type... -> type)`, functions are
  first-class in that they can be passed as arguments to other functions
  and returned from them. They can also be stored inside tuples.
  
* Functions may be recursive and even mutually recursive.  That is,
  each function name is in scope for the entire program.

Example program:

    (define (map-vec [f : (Integer -> Integer)]
                     [v : (Vector Integer Integer)]) : (Vector Integer Integer)
       (vector (f (vector-ref v 0)) (f (vector-ref v 1))))
       
    (define (add1 [x : Integer]) : Integer
       (+ x 1))
       
    (vector-ref (map-vec add1 (vector 0 41)) 1)

Go over the interpreter (Fig. 6.4)

## Functions in x86

Labels can be used to mark the beginning of a function

The address of a label can be obtained using the `leaq` instruction
and PC-relative addressing:

    leaq add1(%rip), %rbx

Calling a function whose address is in a register, i.e., indirect
function call.

    callq *%rbx
        
### Abstract Syntax:

    arg ::= ... | (FunRef label)
    instr ::= ... | (IndirectCallq arg) | (TailJmp arg) 
           | (Instr 'leaq (list arg arg))
    def ::= (Def label '() '() info ((label . block) ...))
    x86_3 ::= (ProgramDefs info (def...))

### Calling Conventions

The `callq` instruction
1. pushes the return address onto the stack
2. jumps to the target label or address (for indirect call)

But there is more to do to make a function call:
1. parameter passing
2. pushing and popping frames on the procedure call stack
3. coordinating the use of registers for local variables


#### Parameter Passing

The C calling convention uses the following six registers (in that order)
for argument passing:

    rdi, rsi, rdx, rcx, r8, r9

The calling convention says that the stack may be used for argument
passing if there are more than six arguments, but we shall take an
alternate approach that makes it easier to implement efficient tail
calls. If there are more than six arguments, then `r9` will store a
tuple containing the sixth argument and the rest of the arguments.

#### Pushing and Popping Frames

The instructions for each function will have a prelude and conclusion
similar to the one we've been generating for `main`.

The most important aspect of the prelude is moving the stack pointer
down by the size needed the function's frame. Similarly, the
conclusion needs to move the stack pointer back up.

Recall that we are storing variables of vector type on the root stack.
So the prelude needs to move the root stack pointer `r15` up and the
conclusion needs to move the root stack pointer back down.  Also, in
the prelude, this frame's slots in the root stack must be initialized
to `0` to signal to the garbage collector that those slots do not yet
contain a pointer to a vector.

As we did for `main`, the prelude must also save the contents of the
old base pointer `rbp` and set it to the top of the frame, so that we
can use it for accessing local variables that have been spilled to the
stack.

|Caller View    | Callee View   | Contents       |  Frame 
|---------------|---------------|----------------|---------
| 8(%rbp)       |               | return address | 
| 0(%rbp)       |               | old rbp        |
| -8(%rbp)      |               | callee-saved   |  Caller (e.g. map-vec)
|  ...          |               |   ...          |
| -8(j+1)(%rbp) |               | spill          |
|  ...          |               |   ...          |
|               | 8(%rbp)       | return address | 
|               | 0(%rbp)       | old rbp        |
|               | -8(%rbp)      | callee-saved   |  Callee (e.g. add1 as f)
|               |  ...          |   ...          |
|               | -8(j+1)(%rbp) | spill          |
|               |  ...          |   ...          |


#### Coordinating Registers

Recall that the registers are categorized as either caller-saved or
callee-saved. 

If the function uses any of the callee-saved registers, then the
previous contents of those registers needs to be saved and restored in
the prelude and conclusion of the function.

Regarding caller-saved registers, nothing new needs to be done.
Recall that we make sure not to assign call-live variables to
caller-saved registers.

#### Efficient Tail Calls

Normally the amount of stack space used by a program is O(d) where d
is the depth of nested function calls.

This means that recursive functions almost always use at least O(n)
space.

However, we can sometimes use much less space.

A *tail call* is a function call that is the last thing to happen
inside another function.

Example: the recursive call to `tail-sum` is a tail call.

    (define (tail-sum [n : Integer] [r : Integer]) : Integer
      (if (eq? n 0) 
          r
          (tail-sum (- n 1) (+ n r))))

    (+ (tail-sum 5 0) 27)


    (define (sum [n : Integer]) : Integer
      (if (eq? n 0) 
          0
          (+ n (sum (- n 1))))) ;; not a tail call

Because a tail call is the last thing to happen, we no longer need the
caller's frame and can reuse that stack space for the callee's frame.
So we can clean up the current frame and then jump to the callee.
However, some care must be taken regarding argument passing.

The standard convention for passing more than 6 arguments is to use
slots in the caller's frame. But we're deleting the caller's frame.
We could use the callee's frame, but its difficult to move all the
variables without stomping on eachother because the caller and callee
frames overlap in memory. This could be solved by using auxilliary
memory somewhere else, but that increases the amount of memory
traffic.

We instead recommend using the heap to pass the arguments that don't
fit in the 6 registers.

Instead of `callq`, use `jmp` for the tail call because the return
address that is already on the stack is the correct one.  

Use `rax` to hold the target address for an indirect jump.

