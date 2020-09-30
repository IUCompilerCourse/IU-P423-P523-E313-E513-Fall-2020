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

* Draw Fig. 5.6. (just the FromSpace)

* Graph Copy via Cheney's Algorithm
    * breadth-first search (quick reminder what that is) uses a queue
    * Cheney: use the ToSpace as the queue, use two pointers to keep
      track of the front (scan pointer) and back (free pointer) of the queue.
        1. Copy tuples pointed to by the root set into the ToSpace
           to form the initial queue.
        2. While copying a tuple, mark the old one and store the
           address of the new tuple inside the old tuple.
           This is called a *forwarding pointer*.
        3. Start processing tuples from the front of the queue.  For
           each tuple, copy the tuples that are directly reachable from
           it to the back of the queue in the ToSpace, unless the tuple
           has already been copied.  Update the pointers in the
           processed tuple to the copies or the forwarding pointer.
    * Draw Fig. 5.6

* An implementation of a garbage collector is in `runtime.c`.


* Data Representation

    * Problems: 
        1. how to differentiate pointers from other things on the
          procedure call stack? 
        2. how can the GC access the pointers that are in registers?
        3. how to differentiate poitners from other things inside tuples?
    * Solutions
        1. Use a root stack (aka. shadow stack), i.e., place all
           tuples in a separate stack that works in parallel to the
           normal stack.  Draw Fig. 5.7.
        2. Spill vector-typed variables to the root stack if they are
           live during a call to the collector.
        3. Add a 64-bit header or "tag" to each tuple. (Fig. 5.8)
           The header includes 
            * 1 bit to indicate forwarding (0) or not (1). If 0, then
              the header is the forwarding pointer.
            * 6 bits to store the length of the tuple (max of 50)
            * 50 bits for the pointer mask to indicate which elements 
              of the tuple are pointers.

* Compiler Passes (fig 5.16)

  * type-check

    Add cases for the new expressions. (Fig 5.1)

    type ::= ... | (Vector type+) | Void
    exp ::= ... | (vector exp+) | (vector-ref exp int)
        | (vector-set! exp int exp) | (void)

    To help the GC identify vectors (pointers to the heap),
    wrap every sub-expression with its type. This information
    will be propagated in the flatten pass to all variables.

    (HasType exp type)

  * shrink
  
    Add HasType to the generated code.

  * expose-allocation (new)

    Lower vector creation into a call to collect, a call to allocate,
    and then initialize the memory (see 5.3.1).
    
    Make sure to place the code for sub-expressions prior to 
    the sequence collect-allocate-initialize. Sub-expressions
    may also call collect, and we can't have partially
    constructed vectors during collect!

    New forms in the output language:

        exp ::= 
           (Collect int)       call the GC and you're going to need `int` bytes
         | (Allocate int type) allocate `int` bytes
         | (GlobalValue name)  access global variables

    * `free_ptr`: the next empty spot in the FromSpace
    * `fromspace_end`: the end of the FromSpace

  * remove-complex-opera*
  
    The new forms Collect, Allocate, GlobalValue should be treated
    as complex operands.
    
    Add case for HasType.
    
    Adapt case for Prim to make sure the enclosing HasType does
    not get separated from it.

  * explicate-control
  
    minor changes to handle the new forms
    
  * uncover-locals
  
    Collect the local variables and their types by inspecting
    assignment statements. Store in the info field of Program.
  
  * select-instructions (5.3.3)
  
    We use `r11` for temporary storage and `r15` for the top of the root
    stack, so we remove them from the list of registers used for
    register allocation.

    Here is where we implement the new operations needed for tuples.
  
    * `vector-ref` turns into a movq with deref in the source
    * `vector-set!` turns into movq with a deref in the target
    * `(Assign lhs (Allocate len (Vector type ...)))`
       * put the current free_ptr into lhs
       * move the free_ptr forward by 8(len+1)   (room for tag)
       * initialize the tag (use bitwise-ior and arithmetic-shift)
         using the type information for the pointer mask.
    * `(Collect bytes)`: turns into a `callq` to the collect function. 
      Pass the top of the root stack (`r15`) in register `rdi` and 
      the number of bytes in `rsi`.
       
  * allocate-registers
  
    * Spill vector-typed variables to the root stack. Handle this
      in the code for assigning homes (converting colors to
      stack locations and registers.)
    * If a vector variable is live during a call to collect,
      make sure to spill it. Do this by adding interference edges
      between the call-live vector variables and the callee-saved
      registers. You'll need to pass the variable-type information
      as another parameter to build-interference.
  
  * print-x89

    * Move the root stack forward to make room for the vector spills.
    * The first call to collect might happen before all the
      slots in the root stack have been initialized.
      So make sure to zero-initialize the root stack in the prelude!
