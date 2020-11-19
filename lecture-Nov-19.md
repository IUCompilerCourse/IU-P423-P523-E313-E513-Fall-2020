# Compiling Loops & Liveness Analysis via Dataflow

Example program:

    (let ([sum (vector 0)])
      (let ([_ (for ([x (vector 1 2 3)])
                (vector-set! sum 0 (+ x (vector-ref sum 0))))])
        (vector-ref sum 0)))
    

## Explicate Control

    (assign y (for ([x seq]) body))  cont-label
    ===>
    vec = seq'
    i = 0
    n = (vector-length vec)
    goto loop-label

    loop-label:
      if (eq? i n)
         goto cont-label
      else
         goto body-label

    body-label:
      x = (vector-ref vec i)
      body'
      i = i + 1
      goto loop-label

## Liveness Analysis

Recall that this is a backwards analysis.

The rule for an assignment statement:

            (S - {x}) \/ R(e)
    x = e
            S

state = set of variables

transfer function:

    f(x = e, S) = (S - {x}) \/ R(e)

meet operator: (merge state information)

   meet : set * set -> set

   meet S1 S2 = S1 \/ S2      (set union)

partial order:

   set containment (reverse of subset-or-equal)

1. initialize live-before of each block with empty set
2. apply the transfer function to all the blocks,
   over and over again until the live-before sets
   for the blocks stop changing.

    start:
         {}
      vec = (vector 1 2 3)
         {vec}
      i = 0
         {i,vec}
      n = (vector-length vec)
         {i,n,vec}
      goto loop-label

    loop-label:
         {i,n,vec}
      if (eq? i n)
         {}
         goto conclusion
      else
         {i,n,vec}
         goto body-label

    body-label:
         {i,n,vec}
      x = (vector-ref vec i)
         {x,i,n,vec}
      body'
         {i,n,vec}
      i = i + 1
         {i,n,vec}
      goto loop-label


suppose a function has three variables: x,y,z

lattice of "states"
meet = greatest lower bound

    {}__________              top
    |    \      \
    {x}   {y}    {z}
    |    /   \   / \
    {x,y}    {y,z}   {x,z}
    |      /_________/
    {x,y,z}                   bottom


