# More x86 with an eye toward instruction selection for R2

    cc ::= e | l | le | g | ge
    instr ::= ... | xorq arg, arg | cmpq arg, arg | set<cc> arg
          | movzbq arg, arg | j<cc> label 

x86 assembly does not have Boolean values (false and true),
but the integers 0 and 1 will serve.

x86 assembly does not have direct support for logical `not`.
But `xorq` can do the job:

          | 0 | 1 |
          |---|---|
        0 | 0 | 1 |
        1 | 1 | 0 |

    var = (not arg);       =>       movq arg, var
                                    xorq $1, var

The `cmpq` instruction can be used to implement `eq?`, `<`, etc.
But it's a bit strange. It puts the result in a mysterious
EFLAGS register.

    var = (< arg1 arg2)    =>       cmpq y, x
                                    setl %al
                                    movzbq %al, var

The `cmpq` instruction can also be used for conditional branching.
The conditional jump instructions `je`, `jl`, etc. also read
from the EFLAGS register.


    if (eq? arg1 arg2)    =>       cmpq arg2, arg1
      goto l1;                     je l1
    else                           jmp l2
      goto l2;


# The C1 intermediate language

Syntax of C1

    bool ::= #t | #f
    atm ::= int | var | bool
    cmp ::= eq? | < | <= | > | >=
    exp ::= ... | (not atm) (cmp atm atm)
    stmt ::= ...
    tail ::= ... 
         | goto label; 
         | if (cmp atm atm) 
             goto label; 
           else
             goto label;
    C1 ::= label1:
             tail1
           label2:
             tail2
           ...


# Explicate Control

Consider the following program

    (let ([x (read)])
      (let ([y (read)])
        (if (if (< x 1) (eq? x 0)  (eq? x 2))
            (+ y 2)
            (+ y 10))))

A straightforward way to compile an `if` expression is to recursively
compile the condition, and then use the `cmpq` and `je` instructions
to branch on its Boolean result. Let's first focus in the `(if (< x 1) ...)`.

    ...
    cmpq $1, x          ;; (< x 1)
    setl %al
    movzbq %al, tmp
    cmpq $1, tmp        ;; (if (< x 1) ...)
    je then_branch1
    jmp else_branch1
    ...

But notice that we used two `cmpq`, a `setl`, and a `movzbq`
when it would have been better to use a single `cmpq` with
a `jl`.

    callq read_int
    movq %rax, x
    callq read_int
    movq %rax, y
    cmpq $1, x          ;; (if (< x 1) ...)
    jl then_branch1
    jmp else_branch1
    ...
        
Ok, so we should recognize when the condition of an `if` is a
comparison, and specialize our code generation. But can we do even
better? Consider the outer `if` in the example program, whose
condition is not a comparison, but another `if`.  Can we rearrange the
program so that the condition of the `if` is a comparison?  How about
pushing the outer `if` inside the inner `if`:

    (let ([x (read)])
      (let ([y (read)])
        (if (< x 1) 
          (if (eq? x 0)
            (+ y 2)
            (+ y 10))
          (if (eq? x 2)
            (+ y 2)
            (+ y 10)))))

Unfortunately, now we've duplicated the two branches of the outer `if`.
A compiler must *never* duplicate code!

Now we come to the reason that our Cn programs take the forms of a
control flow *graph* instead of a *tree*. A graph allows multiple
edges to point to the save vertex, thereby enabling sharing instead of
duplication. Recall that the nodes of the control flow graph are
labeled `tail` statements and the edges are expressed with `goto`.

Using these insights, we can compile the example to the following C1
program.

    (let ([x (read)])
      (let ([y (read)])
        (if (if (< x 1) (eq? x 0)  (eq? x 2))
            (+ y 2)
            (+ y 10))))
    => 
    start:
        x = (read);
        y = (read);
        if (< x 1)
           goto inner_then;
        else
           goto inner_else;
    inner_then:
        if (eq? x 0)
           goto outer_then;
        else
           goto outer_else;
    inner_else:
        if (eq? x 2)
           goto outer_then;
        else
           goto outer_else;
    outer_then:
        return (+ y 2);
    outer_else:
        return (+ y 10);

Notice that we've acheived both objectives.
1. The condition of each `if` is a comparison.
2. We have not duplicated the two branches of the outer `if`.


A new function for compiling the condition expression of an `if`:

explicate-pred : R2_exp x C1_tail x C1_tail -> C1_tail x var list

    (explicate-pred #t B1 B2)  => B1
    
    (explicate-pred #f B1 B2)  => B2
    
    (explicate-pred (< atm1 atm2) B1 B2)  =>  if (< atm1 atm2)
                                                goto l1;
                                              else
                                                goto l2;
         where B1 and B2 are added to the CFG with labels l1 and l2.

    (explicate-pred (if e1 e2 e3) B1 B2)   =>   B5
         where we add B1 and B2 to the CFG with labels l1 and l2.
               (explicate-pred e2 (goto l1) (goto l2))   =>  B3
               (explicate-pred e3) (goto l1) (goto l2))  =>  B4
               (explicate-pred e1 B3 B3)                 =>  B5

explicate-tail : R2_exp -> C1_tail x var list

    (explicate-tail (if e1 e2 e3))   =>   B3
         where (explicate-tail e2) => B1
               (explicate-tail e3) => B2
               (explicate-pred e1 B1 B2) => B3


explicate-assign : R2_exp -> var -> C1_tail -> C1_tail x var list

    (explicate-assign (if e1 e2 e3) x B1)   =>   B4
         where we add B1 to the CFG with label l1
               (explicate-assign e2 x (goto l1))   =>   B2
               (explicate-assign e3 x (goto l1))   =>   B3
               (explicate-pred e1 B2 B3)           =>   B4


# Select Instructions

Thanks to `explicate-control` and the grammar of C1, compiling `if`
statements to x86 is straightforward.

    if (eq? atm1 atm2)       =>      cmpq arg2, arg1
      goto l1;                       je l1
    else                             jmp l2
      goto l2;

and similarly for the other comparison operators.

We only use the `set` and `movzbq` dance for comparisons in an
assignment statement.

    var = (eq? atm1 atm2);    =>     cmpq arg2, arg1
                                     sete %al
                                     mozbq %al, var


# Register Allocation

## Liveness Analysis

We know how to perform liveness on a basic block.
But now we have a whole graph full of basic blocks.
Example:

                      start
                     /      \
                    /        \
            inner_then      inner_else
            |         \____/         |
            |         /    \         |
            outer_then      outer_else
            

Q: In what *order* should we process the blocks? 
A: Reverse topological order.
   In other words, first process the blocks with no out-edges,
   because the live-after set for the last instruction in each
   of those blocks is the empty set. In this example, first
   process `outer_then` and `outer_else`. Then imagine that those
   blocks are removed from the graph. Again select a block with
   no out-edges and repeat the process, continuing until all the
   blocks are gone.

Q: How do we compute the live-after set for the instruction at the end
   of each block? After all, we don't know which way the conditional
   jumps will go.
A: Take the *union* of the live-before set of the first instruction of
   every *successor* block. Thus we compute a conservative
   approximation of the real live-before set.


# Build Interference

Nothing surprising. Need to give `movzbq` special treatment similar to
the `movq` instruction. Also, the register `al` should be considered
the same as `rax`, because it is a part of `rax`.


# Patch Instructions

* `cmpq` the second argument may not be an immediate.

* `movzbq` the target argument must be a register.


# Challenge: Optimize and Remove Jumps

The output of `explicate-control` for our running example is not quite
as nice as we advertised above. It generates lots of trivial blocks
that just goto another block.

    block8482:
        if (eq? x8473 2)
           goto block8479;
        else
           goto block8480;
    block8481:
        if (eq? x8473 0)
           goto block8477;
        else
           goto block8478;
    block8480:
        goto block8476;
    block8479:
        goto block8475;
    block8478:
        goto block8476;
    block8477:
        goto block8475;
    block8476:
        return (+ y8474 10);
    block8475:
        return (+ y8474 2);
    start:
        x8473 = (read);
        y8474 = (read);
        if (< x8473 1)
           goto block8481;
        else
           goto block8482;

Two passes:
1. `optimize-jumps` collapses sequences of jumps through trivial
    blocks into a single jump. Remove the trivial blocks.

        B1 -> B2* -> B3* -> B4 -> B5* -> B6
        =>
        B1 -> B4 -> B6


2. `remove-jumps` merges a block with one that comes after
   if there is only one in-edge to the later one.
   
   
        B1    B2    B3         B1    B2     B3
        |      \    /          B4     \     /
        |       \  /            \      \   /
        B4       B5       =>     \       B5
          \     /                 \     /
           \   /                   \   /
             B6                      B6
