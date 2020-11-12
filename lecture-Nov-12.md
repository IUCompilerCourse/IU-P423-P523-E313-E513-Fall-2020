# Challenge: Optimizing Closures

While closure conversion enables lexical scoping, which is quite
useful, it has the disadvantage of introducing some runtime overhead.
The goal of this challenge assignment is to reduce the overhead in
places where the full generality of closures is not needed.

We'll be going over an algorithm described in *Optimizing Closures in
O(0) time*, by Andrew W. Keep, Alex Hearn, and R. Kent Dybvig (Scheme
and Functional Programming, 2012). The algorithm performs 3 types of
transformations: optimizing direct calls, optimizing known calls, and
eliminating closures.

## Optimize Direct Calls

Replace an application that has a `lambda` in the operator position
with a `let` expression. (This is a particularly simple form of
inlining.)

    ((lambda (x) (+ x 1)) 3)
	
    ==>
	
    (let ([x 3]) (+ x 1))


## Optimize Known Calls

Def. A function is *known at a call site* if it is provable that the
operator expression of the call will alway evaluate to that function.

In this pass we handle the obvious case of a known call in which the
operator of the call is a variable bound to a lambda. We replace the
`vector-ref` with the function's label, so we end up with a direct
call instead of an indirect call.

`lambda_test_9.rkt`

    (let ([y (read)])
      (let ([f (lambda: ([x : Integer]) : Integer
                 (+ x y))])
        (f 21)))
	   
    ==> closure conversion
	
    (define (lambda1 [fvs2 : (Vector _ Integer)] [x9 : Integer]) : Integer
       (let ([y8 (vector-ref fvs2 1)])
          (+ x9 y8)))

    (define (main) : Integer
       (let ([y8 (read)])
          (let ([f0 (Closure 1 (list (fun-ref lambda1) y8))])
             ((vector-ref f0 0) f0 21))))

    ==> optimize known calls

    (define (lambda1  [fvs2 : (Vector _ Integer)] [x9 : Integer]) : Integer
       (let ([y8 (vector-ref fvs2 1)])
          (+ x9 y8)))
          
    (define (main) : Integer
       (let ([y8 (read)])
          (let ([f0 (Closure 1 (list (fun-ref lambda1) y8))])
             ((fun-ref lambda1) f0 21))))

If you update your solution to the partial evaluation challenge
assignment, then the known-call optimization will also work through
multiple `let` bindings.


    (let ([f (lambda: ([x : Integer]) : Integer (+ x 1))])
      (let ([g f])
        (g 41)))

    ==> partial evaluation

    (define (main) : Integer
       (let ([f9 (lambda: ( [x8 : Integer]) : Integer
                        (+ x8 1))])
          (f9 41)))

    ==> closure conversion

    (define (lambda1  [fvs2 : (Vector _)] [x8 : Integer]) : Integer
       (+ x8 1))

    (define (main ) : Integer
       (let ([f9 (Closure 1 (list (fun-ref lambda1)))])
          ((vector-ref f9 0) f9 41)))

    ==> optimize known calls

    (define (main) : Integer
       (let ([f9 (Closure 1 (list (fun-ref lambda1)))])
          ((fun-ref lambda1) f9 41)))

    (define (lambda1  [fvs2 : (Vector _)] [x8 : Integer]) : Integer
       (+ x8 1))


## Eliminating Closures

If a function has no free variables and is only used in calls in which
the function is known (not used in other ways such as passed as a
parameter or stored in a vector), then eliminate the closure.

Def. A function is *well-known* if it is only used at call sites for
which it is known.

Eliminate closures of well-known functions with no free variables.  e.g.

    (define (add [x : Integer] [y : Integer]) : Integer (+ x y))
    (add 40 2)

    ==> closure conversion

    (define (add8 [fvs1 : _] [x9 : Integer] [y0 : Integer]) : Integer
       (+ x9 y0))

    (define (main) : Integer
       (let ([clos2 (Closure 2 (list (fun-ref add8)))])
          ((vector-ref clos2 0) clos2 40 2)))

    ==> optimize known calls

    (define (add8 [fvs1 : _] [x9 : Integer] [y0 : Integer]) : Integer
       (+ x9 y0))

    (define (main) : Integer
       (let ([clos2 (Closure 2 (list (fun-ref add8)))])
          ((fun-ref add8) clos2 40 2)))

    ==> eliminate closures

    (define (add8 [x9 : Integer] [y0 : Integer]) : Integer
       (+ x9 y0))

    (define (main) : Integer
       ((fun-ref add8) 40 2))

The act of eliminating a closure can affect the number of free
variables in another closure, possibly enabling the elimination of
that closure as well.

(let ([f (lambda: ([y : Integer]) : Integer y)])
  (let ([g (lambda: ([x : Integer]) : Integer (f x))])
    (g 42)))

==> closure conversion and elimination on (lambda: ([y : Integer]) ...)

(define (lambda2 [y8 : Integer]) : Integer 
    y8)

(let ([g (lambda: ([x : Integer]) : Integer ((fun-ref lambda2) x))])
  (g 42))
  
==> closure conversion and elimination on (lambda: ([x : Integer]) : Integer ...)

(define (lambda2 [y8 : Integer]) : Integer 
    y8)

(define (lambda4 [x0 : Integer]) : Integer
   ((fun-ref lambda2) x0))

((fun-ref lambda4) 42)


## Algorithm for Closure Conversion and Closure Optimization

1. Mark each call site as either known or unknown.

2. Mark each function (`define` or `lambda`) as well-known or not.

3. Closure and free variable elimination.

    3.1. Compute the free variables for each unprocessed function.
   
    3.2. Eliminate each well-known function with no free variables.
	  
    3.3. Goto step 3.1.

4. Mop-up: apply closure conversion to the remaining functions. 


