# Compiling Functions, the Passes

## Type Check

Go over the figure in the book.

## Shrink

    (ProgramDefsExp info defs exp)
    ==>
    (ProgramDefs info (append defs (list mainDef)))
    
where `mainDef` is

    (Def 'main '() 'Integer '() exp')

## Reveal Functions (new)

We'll need to generate `leaq` instructions for references to
functions, so it makes sense to differentiate them from let-bound
variables.

    (Var x)
    ==>
    (Var x)

    (Var f)
    ==>
    (FunRef f)


    (Let x (Bool #t)
      (Apply (If (Var x) (Var 'add1) (Var 'sub1)) 
             (Int 41)))
    => 
    (Let x (Bool #t)
      (Apply (If (Var x) (FunRef 'add1) (FunRef 'sub1)) 
             (Int 41)))


## Limit Functions (new)

Transform functions so that have at most 6 parameters.

### Function definition

    (Def f ([x1 : t1] ... [xn : tn]) rt info body)
    ==>
    (Def f ([x1 : t1] ... [x5 : t5] [vec : (Vector t6 ... tn)]) rt info
       new-body)

and transform the `body`, replace occurences of parameters `x6` and
higher as follows

    x6
    ==>
    (vector-ref vec 0)
    
    x7
    ==>
    (vector-ref vec 1)

    ...

### Function application

If there are more than 6 arguments, pass arguments 6 and higher in a
vector:

    (Apply e0 (e1 ... en))
    ==>
    (Apply e0 (e1 ... e5 (vector e6 ... en)))


## Remove Complex Operands

Treat `FunRef` and `Apply` as complex operands.

    (Prim '+ (list (Int 5) (FunRef add1)))
    =>
    (Let ([tmp (FunRef add1)])
      (Prim '+ (list (Int 5) (Var tmp))))

Arguments of `Apply` need to be atomic expressions.


## Explicate Control

* assignment
* tail
* predicate

Add cases for `FunRef` and `Apply` to the three helper functions
for assignment, tail, and predicate contexts.

In assignment and predicate contexts, `Apply` becomes `Call`.

In tail contexts, `Apply` becomes `TailCall`.

You'll need a new helper function for function definitions.
The code will be similar to the previous code for `Program`

Previous assignment:

    (define/override (explicate-control p)
      (match p
        [(Program info body)
         (set! control-flow-graph '())
         (define-values (body-block vars) (explicate-tail body))
         (define new-info (dict-set info 'locals vars))
         (Program new-info
                  (CFG (dict-set control-flow-graph 'start body-block)))]
         ))

adapt the above to process every function definition.


## Uncover Locals

Add a case for `TailCall` to the helper for tail contexts.

Create a new helper function for function definitions.
Again, it will be similar to the previous code for `Program`.



## Select Instructions

### `FunRef` becomes `leaq`

We'll keep `FunRef` as an instruction argument for now,
placing it in a `leaq` instruction.

    (Assign lhs (FunRef f))
    ==>
    (Instr 'leaq (list (FunRef f) lhs'))

### `Call` becomes `IndirectCallq`

    (Assign lhs (Call fun (arg1 ... argn)))
    ==>
    movq arg'1 rdi
    movq arg'2 rsi
    ...
    (IndirectCallq fun')
    (Instr 'movq (Reg 'rax) lhs')

### `TailCall` becomes `TailJmp`

We postpone the work of popping the frame until later by inventing an
instruction we'll call `TailJmp`.

    (TailCall fun (arg1 ... argn))
    ==>
    movq arg'1 rdi
    movq arg'2 rsi
    ...
    (TailJmp fun')

### Function Definitions

    (Def f ([x1 : T1] ... [xn : Tn]) rt info CFG)
       1. CFG => CFG'
       2. prepend to start block from CFG'
           movq rdi x1
           ...
       4. parameters get added to the list of local variables
    =>
    (Def f '() '() new-info new-CFG)

alternative:
  replace parameters (in the CFG) with argument registers


## Uncover Live

New helper function for function definitions.

Treat `IndirectCallq` like `Callq`.


## Build Interference Graph

New helper function for function definitions.

Compute one interference graph per function.

Spill vector-typed variables that are live during any function call.
(Because our functions make trigger `collect`.) So add interference
edges between those variables and the callee-saved registers.

## Patch Instructions

The destination of `leaq` must be a register.

The destination of `TailJmp` should be `rax`.

    (TailJmp %rbx)
    ==>
    movq %rbx, %rax
    (TailJmp rax)

## Print x86


    (FunRef label) => label(%rip)

    (IndirectCallq arg) => callq *arg
    
    (TailJmp rax)
    =>
    addq frame-size, %rsp         move stack pointer up
    popq %rbx                     callee-saved registers
    ...
    subq root-frame-size, %r15    move root-stack pointer
    popq %rbp                     restore rbp
    jmp *%rax                     jump to the target function
    
