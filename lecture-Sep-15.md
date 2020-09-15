# Register Allocation: Graph Coloring via Sudoku

* Goal: map each variable to a register such that no two interfering
  variables get mapped to the same register. 
  
* Secondary goal: minimize the number of stack locations that need
  to be used.

* In the interference graph, this means that adjacent vertices must be
  mapped to different registers. 

* If we think of registers and stack locations as colors, then this
  becomes an instance of the *graph coloring problem*.

If you aren't familiar with graph coloring, you might instead be
familiar with another instance of it, *Sudoku*.

Review Sudoku and relate it to graph coloring.

    -------------------
    |  9  |5 3 7|  1 4|
    |  3 8|  4 6|  9  |
    |4    |1    |2    |
    -------------------
    |     |     |    2|
    |7   9|8   2|1   5|
    |6    |     |     |
    -------------------
    |    4|    8|    6|
    |  6  |4 9  |7 2  |
    |8 7  |6 2 3|  4  |
    -------------------

* Squares on the board corresponds to vertices in the graph.
* The vertices for squares in the same *row* are connected by edges.
* The vertices for squares in the same *column* are connected by edges.
* The vertices for squares in the same *3x3 region* are connected by edges.
* The numbers 1-9 are corresponds to 9 different colors. 

What strategies do you use to play Sudoku?

* Pencil Marks? (most-constrained-first)
  We'll record the colors that cannot be used,
  i.e. the *saturation* of the vertex.
* Backtracking?
    * Register allocation is easier than Sudoku in
      that we can spill to the stack, i.e., we can always add more colors.
    * Also, it is important for a register allocator to be
	  efficient, and backtracking is exponential time.
	* So it's better to *not* use backtracking.

We'll use the DSATUR algorithm of Brelaz (1979).
Use natural numbers for colors.
The set W is our worklist, that is, the vertices that still need to be
colored.

    W <- vertices(G)
    while W /= {} do
      pick a vertex u from W with maximal saturation
      find the lowest color c not in { color[v] | v in adjacent(u) }.
      color[u] <- c
      W <- W - {u}

Initial state:

    {}     {}     {}
    t ---- z      x
	       |\___  |
		   |    \ |
		   |     \|
		   y ---- w ---- v
		   {}     {}    {}

There's a tie amogst all vertices. Color t 0. Update saturation of adjacent.

    {}    {0}     {}
    t:0----z      x
	       |\___  |
		   |    \ |
		   |     \|
		   y ---- w ---- v
		   {}    {}     {}

Vertex z is the most saturated. Color z 1. Update saturation of adjacent.

    {1}   {0}     {}
    t:0----z:1    x
	       |\___  |
		   |    \ |
		   |     \|
		   y ---- w ---- v
		  {1}    {1}    {}


There is a tie between y and w. Color w 0. 

    {1}   {0}     {0}
    t:0----z:1    x
	       |\___  |
		   |    \ |
		   |     \|
	       y ----w:0---- v
		  {0,1}  {1}    {0}

Vertex y is the most saturated. Color y 2.

    {1}   {0,2}   {0}
    t:0----z:1    x
	       |\___  |
		   |    \ |
		   |     \|
		   y:2----w:0---- v
		  {0,1}  {1,2}   {0}

Vertex x and v are the most saturated. Color v 1.

    {1}   {0,2}   {0}
    t:0----z:1    x
	       |\___  |
		   |    \ |
		   |     \|
		   y:2----w:0----v:1
		  {0,1}  {1,2}   {0}

Vertex x is the most saturated. Color x 1.

    {1}   {0,2}   {0}
    t:0----z:1    x:1
	       |\___  |
		   |    \ |
		   |     \|
		   y:2----w:0----v:1
		  {0,1}  {1,2}   {0}

* Create variable to register/stack location mapping:
  We're going to reserve `rax` and `r15` for other purposes,
  and we use `rsp` and `rbp` for maintaining the stack,
  so we have 12 remaining registers to use:

        rbx rcx rdx rsi rdi r8 r9 r10 r11 r12 r13 r14
	
  Map the first 12 colors to the above registers, and map the rest of
  the colors to stack locations (starting with a -8 offset from `rbp`
  and going down in increments of 8 bytes.

		0 -> rbx
		1 -> rcx
		2 -> rdx
        3 -> rsi
        ...
        12 -> -8(%rbp)
        13 -> -16(%rbp)
        14 -> -24(%rbp)
        ...

  So we have the following variable-to-home mapping

		v -> rcx
		w -> rbx
		x -> rcx
		y -> rdx
		z -> rcx
		t -> rbx


* Update the program, replacing variables according to the variable-to-home
    mapping. We also record the number of bytes needed of stack space
    for the local variables, which in this case is 0.

    Recall the example program after instruction selection:

        locals: v w x y z t
        start:
            movq $1, v
            movq $42, w
            movq v, x
            addq $7, x
            movq x, y
            movq x, z
            addq w, z
            movq y, t
            negq t
            movq z, %rax
            addq t, %rax
            jmp conclusion

    Here's the output of register allocation, after applying
    the variable-to-home mapping.

		stack-space: 0
		start:
            movq $1, %rcx
            movq $42, $rbx
            movq %rcx, %rcx
            addq $7, %rcx
            movq %rcx, %rdx
            movq %rcx, %rcx
            addq %rbx, %rcx
            movq %rdx, %rbx
            negq %rbx
            movq %rcx, %rax
            addq %rbx, %rax
            jmp conclusion

