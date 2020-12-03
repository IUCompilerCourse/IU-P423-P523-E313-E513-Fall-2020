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

        [(Assign lhs (AllocateClosure len `(Vector ,ts ...) arity))
         (define lhs^ (select-instr-arg lhs))
         ;; Add one quad word for the meta info tag
         (define size (* (add1 len) 8))
         ;;highest 7 bits are unused
         ;;lowest 1 bit is 1 saying this is not a forwarding pointer
         (define is-not-forward-tag 1)
         ;;next 6 lowest bits are the length
         (define length-tag (arithmetic-shift len 1))
         ;;bits [6,56] are a bitmask indicating if [0,50] are pointers
         (define ptr-tag
           (for/fold ([tag 0]) ([t (in-list ts)] [i (in-naturals 7)])
             (bitwise-ior tag (arithmetic-shift (b2i (root-type? t)) i))))
         (define arity-tag ...)
         ;; Combine the tags into a single quad word
         (define tag (bitwise-ior arity-tag ptr-tag length-tag is-not-forward-tag))
         (list (Instr 'movq (list (Global 'free_ptr) (Reg tmp-reg)))
               (Instr 'addq (list (Imm size) (Global 'free_ptr)))
               (Instr 'movq (list (Imm tag) (Deref tmp-reg 0)))
               (Instr 'movq (list (Reg tmp-reg) lhs^))
               )
         ]

* `(Assign lhs (Prim 'procedure-arity (list e)))`

  Extract the arity from the tag of the vector.
  
        (Assign lhs (Prim 'procedure-arity (list e)))
        ===>
        movq e', %r11
        movq 0(%r11), %r11
        sarq $57, %r11
        movq %r11, lhs'

* `(Assign lhs (Prim 'vector-length (list e)))`

  Extract the length from the tag of the vector.

        (Assign lhs (Prim 'vector-length (list e)))
        ===>
        movq e', %r11
        movq 0(%r11), %r11
        andq $126, %r11           // 1111110
        sarq $1, %r11
        movq %r11, lhs'


## `Vectorof`, `vector-ref`, and `vector-set!`

The type checker for R6 treats vector operations differently
if the vector is of type `(Vectorof T)`. 
The index can be an arbitrary expression, e.g.
suppose `vec` has type `(Vectorof T)`. Then
the index could be `(read)`

   (let ([vec1 (vector (inject 1 Integer) (inject 2 Integer))]) ;; vec1 : (Vector Any Any)
     (let ([vec2 (inject vec1 (Vector Any Any))]) ;; vec2 : Any
       (let ([vec3 (project vec2 (Vectorof Any))]) ;; vec3 : (Vectorof Any)
         (vector-ref vec3 (read)))))

and the type of `(vector-ref vec (read))` is `T`.

Recall instruction selection for `vector-ref`:

    (Assign lhs (Prim 'vector-ref (list evec (Int n))))
    ===>
    movq evec', %r11
    movq offset(%r11), lhs'

    where offset is 8(n+1)

If the index is not of the form `(Int i)`, but an arbitrary
expression, then instead of computing the offset `8(n+1)` at compile
time, you can generate the following instructions. Note the use of the
new instruction `imulq`.

    (Assign lhs (Prim 'vector-ref (list evec en)))
    ===>
    movq en', %r11
    addq $1, %r11
    imulq $8, %r11
    addq evec', %r11
    movq 0(%r11) lhs'

The same idea applies to `vector-set!`.


# The R7 Language: Mini Racket (Dynamically Typed)

    exp ::= int | (read) | ... | (lambda (var ...) exp)
          | (vector-ref exp exp) | (vector-set! exp exp exp)
    def ::= (define (var var ...) exp)
    R7 ::= def... exp

# Compiling R7 to R6 by cast insertion

The main invariant is that every subexpression that we generate should
have type `Any`, which we accomplish by using `inject`.

To perform an operation on a value of type `Any`, we `project` it to
the appropriate type for the operation.

Example:
R7:

    (+ #t 42)

R6:

    (inject
       (+ (project (inject #t Boolean) Integer)
          (project (inject 42 Integer) Integer))
       Integer)
    ===>
    x86 code

    
Booleans:

    #t
    ===>
    (inject #t Boolean)

Integer:

    42
    ===>
    (inject 42 Integer)

Arithmetic:

    (+ e_1 e_2)
    ==>
    (inject
       (+ (project e'_1 Integer)
          (project e'_2 Integer))
       Integer)

Variables:

    x
    ===>
    x

Lambda:

    (lambda (x_1 ... x_n) e)
    ===>
    (inject (lambda: ([x_1 : Any] ... [x_n : Any]) : Any e')
        (Any ... Any -> Any))

example:

    (lambda (x y) (+ x y))
    ===>
    (inject (lambda: ([x : Any] [y : Any]) : Any
      (inject (+ (project x Integer) (project y Integer)) Integer))
      (Any Any -> Any))

Application:

    (e_0 e_1 ... e_n)
    ===>
    ((project e'_0 (Any ... Any -> Any)) e'_1 ... e'_n)

Vector Reference:

    (vector-ref e_1 e_2)
    ===>
    (vector-ref (project e'_1 (Vectorof Any)) 
                (project e'_2 Integer))


Vector:

    (vector e1 ... en)
    ===>
    (inject 
       (vector e1' ... en')
       (Vector Any .... Any))

R7:
    (vector 1 #t)      heterogeneous
    
    (inject (vector (inject 1 Integer) (inject #t Boolean)) 
       (Vector Any Any)) : Any

R6: (Vector Int Bool)  heterogeneous
    (Vectorof Int)     homogeneous

actually see:

    (Vector Any Any)
    (Vectorof Any)
