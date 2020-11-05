
We'll implement a dynamically-typed language called R7, a subset of
Racket, in two stages.

1. Extend our typed language with a new type `Any` that is equiped
   with the operations `inject` and `project` that convert a value
   of any other type to `Any` and back again. This language is R6.

   (let ([x (inject (Int 42) 'Integer)])  ;; create an Any from an integer
     (project x 'Integer) ;; extract the integer from the Any

   (let ([x (inject (Bool #t) 'Boolean)])  ;; create an Any from an Boolean
     (project x 'Integer) ;; extract the integer from the Any

2. Create a new pass that translates from R7 to R6 that uses
   `Any` as the type for just about everying and that 
   inserts `inject` and `project` in lots of places.

Example

    (not (if (eq? (read) 1) #f 0))



# The R6 Language: Any

    type ::= ... | Any
    ftype ::= Integer | Boolean | (Vector Any ...) | (Vectorof Any) | (Any ... -> Any)
    exp ::= ... | (inject exp ftype) | (project exp ftype) |
          | (boolean? exp) | (integer? exp) | (vector? exp)
          | (procedure? exp) | (void? exp)

The `Vectorof` type is for homogeneous vectors of arbitrary length.
That is, their elements are all of the same type and the length is
determined at runtime.

* type checking R6

* interpreting R6

Another example:

    (let ([v (inject (vector (inject 42 Integer)) 
                     (Vector Any))])
       (let ([w (project v (Vector Any))])
          (let ([x (vector-ref w 0)])
             (project x Integer))))



# Compiling R6

The runtime representation of a value of type `Any` is a 64 bit value
whose 3 least-significant bits (right-most) encode the runtime type,
which we call a *tag*.
  
    tagof(Integer)        = 001
    tagof(Boolean)        = 100
    tagof((Vector ...))   = 010
    tagof((Vectorof ...)) = 010
    tagof((... -> ...))   = 011
    tagof(Void)           = 101

If the value is an integer or Boolean, then the other 61 bits store
that value. (Shifted by 3.)

If the value is a vector or function, then the 64 bits is an
address. All our values are 8-byte aligned, so we don't need the
bottom 3 bits. To obtain the address from an `Any` value, just write
000 to the rightmost 3 bits.

## Shrink

* Compiling `Project` to `tag-of-any`, `value-of-any`, and `exit`.

  If `ty` is `Boolean` or `Integer`:
    
        (project e ty)
        ===>
        (let ([tmp e])
          (if (eq? (tag-of-any tmp) tag)
              (value-of-any tmp ty)
              (exit))))
              
        where tag is tagof(ty)

  If `ty` is a function or vector, you also need to check the vector
  length or procedure arity. Those two operations be added as two new
  primitives. Use the primitives:
  
  `vector-length`
  `procedure-arity`


* Compile `Inject` to `make-any`

        (inject e ty)
        ===>
        (make-any e tag)

        where tag is the result of tagof(ty)

* Abstract syntax for the new forms:
  
        exp ::= ... | (Prim 'tag-of-any (list exp))
             | (Prim 'make-any (list exp (Int tag)))
             | (ValueOf exp type)
             | (Exit)


## Reveal Functions

Old way:

    (Var f)
    ===>
    (FunRef f)

To support `procedure-arity`, we'll need to record the arity of a
function in `FunRefArity`.

    (Var f)
    ===>
    (FunRefArity f n)

Which means when processing the `ProgramDefs` form, we need to build
an alist mapping function names to their arity.

## Closure Convertion

To support `procedure-arity`, we use a special purpose
`Closure` form instead of the primitive `vector`,
both in the case for `Lambda` and `FunRefArity`.

## Expose Allocation

Add a case for `Closure` that is similar to the one for `vector`
except that it uses `AllocateClosure` instead of `Allocate`, so that
it can pass along the arity.

## Remove Complex Operands

Add case for `AllocateClosure`.

## Explicate Control

Add case for `AllocateClosure`.

## Instruction Selection

* `(Prim 'make-any (list e (Int tag)))`

  For tag of an Integer or Boolean: (Void too?)

        (Assign lhs (Prim 'make-any (list e (Int tag)))
        ===>
        movq e', lhs'
        salq $3, lhs'
        orq tag, lhs'

  where `3` is the length of the tag.

  For other types (vectors and functions):

        (Assign lhs (Prim 'make-any (list e (Int tag))))
        ===>
        movq e', lhs'
        orq tag, lhs'

* `(Prim 'tag-of-any (list e))`

        (Assign lhs (Prim 'tag-of-any (list e)))
        ===>
        movq e', lhs
        andq $7, lhs

  where `7` is the binary number `111`.

* `(ValueOf e ty)`

  If `ty` is an Integer, Boolean, Void:

        (Assign lhs (ValueOf e ty))
        ==>
        movq e', lhs'
        sarq $3, lhs

  where `3` is the length of the tag.
  
  If `ty` is a vector or procedure (a pointer):

        (Assign lhs (ValueOf e ty))
        ==>
        movq $7, lhs
        notq lhs
        andq e', lhs

  where `7` is the binary number `111`.
  Instead: precompute the `11111....111000` instead of doing the movq 7 and notq


To be continued next lecture...

