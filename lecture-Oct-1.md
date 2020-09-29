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
