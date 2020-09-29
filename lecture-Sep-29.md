# Booleans and Conditional (R2) Continued

## Select Instructions

Thanks to `explicate-control` and the grammar of C1, compiling `if`
statements to x86 is straightforward. Let `arg1` and `arg2` be the
results of translating `atm1` and `atm2` to x86, respectively.

    if (eq? atm1 atm2)       =>      cmpq arg2, arg1
      goto l1;                       je l1
    else                             jmp l2
      goto l2;

and similarly for the other comparison operators.

We only use the `set` and `movzbq` dance for comparisons in an
assignment statement. Let `arg1` and `arg2` be the results of
translating `atm1` and `atm2` to x86, respectively.

    var = (eq? atm1 atm2);    =>     cmpq arg2, arg1
                                     sete %al
                                     mozbq %al, var


## Register Allocation

### Liveness Analysis

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

        locals: (x y)
        start:
            callq 'read_int
            movq %rax, x
            callq 'read_int
            movq %rax, y
            cmpq $1, x
            jl inner_then
            jmp inner_else
        inner_then:
            cmpq $0, x
            je outer_then
            jmp outer_else
        inner_else:
            cmpq $2, x
            je outer_then
            jmp outer_else
        outer_then:
            movq y, %rax
            addq $2, %rax
            jmp conclusion
        outer_else:
            movq y, %rax
            addq $10, %rax
            jmp conclusion

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


### Build Interference

Nothing surprising. Need to give `movzbq` special treatment similar to
the `movq` instruction. Also, the register `al` should be considered
the same as `rax`, because it is a part of `rax`.


## Patch Instructions

* `cmpq` the second argument must not be an immediate.

* `movzbq` the target argument must be a register.


## Challenge: Optimize and Remove Jumps

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

# R3 Language (Tuples)


    type ::= Integer | Boolean | (Vector type+) | Void
    exp ::= ... 
      | (vector exp+)
      | (vector-ref exp int)
      | (vector-set! exp int exp)
      | (void)
    R3 ::= (program exp)


## Example Programs

* Tuples are first class

        (let ([t (vector 40 #t (vector 2))])
          (if (vector-ref t 1)
             (+ (vector-ref t 0)
                (vector-ref (vector-ref t 2) 0))
             44))

* Tuples may be aliased

        (let ([t1 (vector 3 7)])
          (let ([t2 t1])
            (let ([_ (vector-set! t2 0 42)])
              (vector-ref t1 0))))

* Tuples live forever (from the programmer's view)

        (vector-ref
          (let ([t (vector 3 7)])
            t)
          0)

## Garbage Collection

* Def. The *live data* are all of the tuples that might be accessed by
  the program in the future. We can overapproximate this as all of the
  tuples that are reachable, transitively, from the registers or
  procedure call stack. We refer to the registers and stack
  collectively as the *root set*.

* The goal of a garbage collector is to reclaim the data that is not
  live.

* We shall use a 2-space copying collector, using Cheney's algorithm
  (BFS) for the copy.

* Alternative garbage collection techniques:
   * generational copy collectors
   * mark and sweep
   * reference counting + mark and sweep

Overview of how GC fits into a running program.:

0. Ask the OS for 2 big chunks of memory. Call them FromSpace and ToSpace.
1. Run the program, allocating tuples into the FromSpace.
2. When the FromSpace is full, copy the *live data* into the ToSpace.
3. Swap the roles of the ToSpace and FromSpace and go back to step 1.
