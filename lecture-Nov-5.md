## Compiling R6, Instruction Selection, continued

* `(Exit)`

        (Assign lhs (Exit))
        ===>
        movq $-1, %rdi
        callq exit

* `(Assign lhs (AllocateClosure len ty arity))`

  Treat this just like `Allocate` except that you'll put
  the `arity` into the tag at the front of the vector.
  Use bits 57 and higher for the arity.

* `(Assign lhs (Prim 'procedure-arity (list e)))`

  Extract the arity from the tag of the vector.
  
        (Assign lhs (Prim 'procedure-arity (list e)))
        ===>
        movq e', %r11
        movq (%r11), %r11
        sarq $57, %r11
        movq %r11, lhs'

* `(Assign lhs (Prim 'vector-length (list e)))`

  Extract the length from the tag of the vector.

        (Assign lhs (Prim 'vector-length (list e)))
        ===>
        movq e', %r11
        movq (%r11), %r11
        andq $126, %r11           // 1111110
        sarq $1, %r11
        movq %r11, lhs'


## `Vectorof`, `vector-ref`, and `vector-set!`

The type checker for R6 treats vector operations differently
if the vector is of type `(Vectorof T)`. 
The index can be an arbitrary expression, e.g.
suppose `vec` has type `(Vectorof T)`. Then
the index could be `(read)`

    (vector-ref vec (read))

and the type of `(vector-ref vec (read))` is `T`.

Recall instruction selection for `vector-ref`:

    (Assign lhs (Prim 'vector-ref (list e-vec (Int n))))
    ===>
    movq vec', %r11
    movq 8(n+1)(%r11), lhs'

If the index is not of the form `(Int i)`, but an arbitrary
expression, then instead of computing the offset `8(n+1)` at compile
time, you can generate the following instructions

    (Assign lhs (Prim 'vector-ref (list evec en)))
    ===>
    movq en', %r11
    addq $1, %r11
    imulq $8, %r11
    addq evec', %r11
    movq 0(%r11) lhs'

The same idea applies to `vector-set!`.


# The R7 Language: Mini Racket

    exp ::= int | (read) | ... | (lambda (var ...) exp)
          | (vector-ref exp exp) | (vector-set! exp exp exp)
    def ::= (define (var var ...) exp)
    R7 ::= def... exp

# Compiling R7 to R6 by cast insertion

The main invariant is that every subexpression that we generate should
have type `Any`, which we accomplish by using `inject`.

To perform an operation on a value of type `Any`, we `project` it to
the appropriate type for the operation.

Booleans:

    #t
    ===>
    (inject #t Boolean)

Arithmetic:

    (+ e_1 e_2)
    ==>
    (inject
       (+ (project e'_1 Integer)
          (project e'_2 Integer))
       Integer)
    
Lambda:

    (lambda (x_1 ...) e)
    ===>
    (inject (lambda: ([x_1:Any] ...) : Any e')
        (Any ... Any -> Any))
    
Application:

    (e_0 e_1 ... e_n)
    ===>
    ((project e'_0 (Any ... Any -> Any)) e'_1 ... e'_n)

Vector Reference:

    (vector-ref e_1 e_2)
    ===>
    (vector-ref (project e'_1 (Vectorof Any)) 
                (project e'_2 Integer))
