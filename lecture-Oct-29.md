# Closure Convertion: Compilation Pass

## Example

    (define (f [x : Integer]) : (Integer -> Integer)
       (let ([y 4])
          (lambda: ([z : Integer]) : Integer
             (+ x (+ y z)))))

    (let ([g (f 5)])
      (let ([h (f 3)])
        (+ (g 11) (h 15))))

From last time:

1. lambda's create closures
   (a vector with function pointer and values of free variables)
2. a function call retrieves the function pointer from the closure 
   and calls it, passing is the closure and the regular arguments. 
3. generate a function definition for each lambda.
   It has an extra parameter for the closure and
   starts with a sequence of let bindings that
   put the values of the free variables (from the closure)
   into variables with the same names as the free variables. 



## Closure Conversion Pass (after reveal-functions)

For lambda:

    (lambda: (ps ...) : rt body)
    ==>
    (vector (fun-ref name) fv_1 ... fv_n)

where

    fv_1 ... fv_n = (free-variables (lambda: (ps ...) : rt body))

    use racket `set` or `hash`

and also generate a top-level function

    (define (name [clos : (Vector _ fvT_1 ... fvT_n)] ps ...)
      (let ([fv_1 (vector-ref clos 1)])
        ...
         (let ([fv_n (vector-ref clos n)])
            body')))

For function references:

    (fun-ref f)
    ==>
    (vector (fun-ref f))

For application:

    (e es ...)
    ==>
    (let ([tmp e'])
      ((vector-ref tmp 0) tmp es' ...))

Types should also be converted:

    (T_1 ... T_n -> T_r)
    ==>
    (Vector ((Vector _) T_1' ... T_n' -> T_r'))

where T_1' ... T_n' and T_r' have been recursively
converted.

Vector types should be recursively converted.

Integers and Booleans do not change.


## Example

After `reveal-functions`, the example is transformed into the
following using `fun-ref` to refer to function `f`.

    (define (f74 [x75 : Integer]) : (Integer -> Integer)
       (let ([y76 4])
          (lambda: ([z77 : Integer]) : Integer
             (+ x75 (+ y76 z77)))))
    
    (define (main) : Integer
       (let ([g78 ((fun-ref f74) 5)])
          (let ([h79 ((fun-ref f74) 3)])
             (+ (g78 11) (h79 15)))))


Closure conversion produces the following:

    (define (f74 [fvs82 : _] [x75 : Integer]) 
            : (Vector ((Vector _) Integer -> Integer))
       (let ([y76 4])
          (vector (fun-ref lambda80) x75 y76)))

    (define (lambda80  [fvs81 : (Vector _ Integer Integer)] 
                       [z77 : Integer]) 
            : Integer
       (let ([x75 (vector-ref fvs81 1)])
          (let ([y76 (vector-ref fvs81 2)])
             (+ x75 (+ y76 z77)))))

    (define (main) : Integer
       (let ([g78 (let ([app83 (vector (fun-ref f74))])
                        ((vector-ref app83 0) app83 5))])
          (let ([h79 (let ([app84 (vector (fun-ref f74))])
                           ((vector-ref app84 0) app84 3))])
             (+ (let ([app85 g78])
                   ((vector-ref app85 0) app85 11))
                 (let ([app86 h79])
                    ((vector-ref app86 0) app86 15))))))


alternative

    (define (main) : Integer
       (let ([j (if (eq? (read) 0) (fun-ref f74) (lambda: ...))])
       (let ([g78 (j 5)])
          (let ([h79 ((fun-ref f74) 3)])
             (+ (g78 11) (h79 15))))))


