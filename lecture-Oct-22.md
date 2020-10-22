# Lambda: Lexically Scoped Functions


## Example

    (define (f [x : Integer]) : (Integer -> Integer)
       (let ([y 4])
          (lambda: ([z : Integer]) : Integer
             (+ x (+ y z)))))

    (let ([g (f 5)])
      (let ([h (f 3)])
        (+ (g 11) (h 15))))


## Syntax

concrete syntax:

    exp ::= ... | (lambda: ([var : type]...) : type exp)
    R5 ::= def* exp

abstract syntax:

    exp ::= ... | (Lambda ([var : type]...) type exp)
    R5 ::= (ProgramDefsExp info def* exp)


(stopped lecture here)


## Interpreter for R5


see `interp-R5.rkt`:

* case for lambda, 
* case for define (mcons), 
* case for application, 
* case for program (backpatching).

## Type Checker for R5

see `type-check-R5`:

The case for lambda.

## Free Variables

Def. A variable is *free with respect to an expression* e if the
variable occurs inside e but does not have an enclosing binding in e.

Use above example to show examples of free variables.

## Closure Representation

Figure 7.3 in book, diagram of g and h from above example.

# Closure Conversion Pass (after reveal-functions)

For lambda:

    (lambda: (ps ...) : rt body)
    ==>
    (vector (function-ref name) fvs ...)

and also generate a top-level function

    (define (name [clos : _] ps ...)
      (let ([fv_1 (vector-ref clos 1)])
        (let ([fv_2 (vector-ref clos 2)])
          ...
          body')))
        
For application:

    (e es ...)
    ==>
    (let ([tmp e'])
      ((vector-ref tmp 0) tmp es' ...))

## Example

    (define (f (x : Integer)) : (Integer -> Integer)
      (let ((y 4))
         (lambda: ((z : Integer)) : Integer
           (+ x (+ y z)))))

     (let ((g ((fun-ref f) 5)))
        (let ((h ((fun-ref f) 3)))
           (+ (g 11) (h 15))))
           
    ==>
    
    (define (f (clos.1 : _) (x : Integer)) : (Vector ((Vector _) Integer -> Integer))
       (let ((y 4))
          (vector (fun-ref lam.1) x y)))
          
    (define (lam.1 (clos.2 : (Vector _ Integer Integer)) (z : Integer)) : Integer
       (let ((x (vector-ref clos.2 1)))
          (let ((y (vector-ref clos.2 2)))
             (+ x (+ y z)))))
             
     (let ((g (let ((t.1 (vector (fun-ref f))))
                ((vector-ref t.1 0) t.1 5))))
        (let ((h (let ((t.2 (vector  (fun-ref f))))
                   ((vector-ref t.2 0) t.2 3))))
           (+ (let ((t.3 g)) ((vector-ref t.3 0) t.3 11))
              (let ((t.4 h)) ((vector-ref t.4 0) t.4 15)))))
