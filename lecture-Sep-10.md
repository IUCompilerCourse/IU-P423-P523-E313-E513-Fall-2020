# Register Allocation

Main ideas:

* Put as many variables in registers as possible, and *spill* the rest
  to the stack.

* Variables that are not in use at the same time can be assigned to
  the same register.

## Registers and Calling Conventions

* caller-save registers

        rax rdx rcx rsi rdi r8 r9 r10 r11
	

* callee-save registers

    	rsp rbp rbx r12 r13 r14 r15

## Running Example

    (let ([v 1])
      (let ([w 42])
        (let ([x (+ v 7)])
          (let ([y x])
            (let ([z (+ x w)])
              (+ z (- y)))))))


After instruction selection:

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

## Liveness Analysis

Goal: figure out the program regions where a variable is in use.

Def. A variable is *live* at a program point if the value in the
variable is used at some later point in the program.

The following equations compute the live before/after sets
for each instruction.
The instructions of the program are numbered 1 to n.

    L_after(k) = L_before(k + 1)
	L_after(n) = {}
	
	L_before(k) = (L_after(k) - W(k)) U R(k)
	
Here's the program with the live-after set next to each instruction.
Compute them from bottom to top.

                       {}
    movq $1, v
                       {v}
    movq $42, w
                       {v,w}
    movq v, x
                       {w,x}
    addq $7, x
                       {w,x}
    movq x, y
                       {w,x,y}
    movq x, z
                       {w,y,z}
    addq w, z
                       {y,z}
    movq y, t
                       {t,z}
    negq t
                       {t,z}
    movq z, %rax
                       {t}
    addq t, %rax
                       {}
    jmp conclusion
                       {}


## Build the Interference Graph

Def. An *interference graph* is an undirected graph whose vertices
represent variables and whose edges represent conflicts, i.e., when
two vertices are live at the same time.

A naive approach: inspect each live-after set, and
add an edge between every pair of variables.

Down sides:
* It is O(n^2) per instruction (for n variables)
* If one variable is assigned to another,then they have the same value 
  and can be stored in the same register, but the naive approach
  would mark them as conflicting.
  Example: consider the instruction from the above program

        movq x, y         {w,x,y}

  Both x and y are live at this point, so the naive approach
  would mark them as conflicting. But because of this assignment
  they hold the same value, so they could share the same register.

The better approach focuses on writes: it creates an edge between the
variable being written-to by the current instruction and all the
*other* live variables. (One should not create self edges.) For a call
instruction, all caller-save register must be considered as
written-to. For the move instruction, we skip adding an edge between a
live variable and the destination variable if the live variable
matches the source of the move, as per point 2 above.  So we have
the followng three rules.

1. For an arithmetic instructions, such as (addq s d)
     for each v in L_after,
	    if v != d then
		    add edge (d,v)

2. For a call instruction (callq label),
     for each v in L_after,
	    for each r in caller-save registers
			if r != v then
				add edge (r,v)
				
3. For a move instruction (movq s d), 
     for each v in L_after,
        if v != d and v != s then 
		    add edge (d,v)

Let us walk through the running example, proceeding top to bottom,
apply the three rules to build the interference graph.

                       {}
	movq $1, v                    rule 3: no interference (v=v)
                       {v}
	movq $42, w                   rule 3: edge w-v
                       {v,w}
	movq v, x                     rule 3: edge x-w
                       {w,x}
	addq $7, x                    rule 1: edge x-w (dup.)
                       {w,x}
	movq x, y                     rule 3: edge y-w, no edge y-x
                       {w,x,y}
	movq x, z                     rule 3: edge z-w, edge z-y
                       {w,y,z}
	addq w, z                     rule 1: edge z-y (dup.)
                       {y,z}
	movq y, t                     rule 3: edge t-z
                       {t,z}
	negq t.1                      rule 1: edge t-z (dup)
                       {t,z}
	movq z, %rax                  rule 2: but ignore rax
                       {t}
	addq t, $rax                  rule 1: but ignore rax
                       {}
	jmp conclusion
                       {}
	  
So the interference graph looks as follows:

    t ---- z      x
	       |\___  |
		   |    \ |
		   |     \|
		   y ---- w ---- v


