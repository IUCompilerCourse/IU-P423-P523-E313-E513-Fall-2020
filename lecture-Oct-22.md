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

Figure 7.4: case for lambda, case for define (mcons), case for
application, case for program (backpatching).

    (define (interp-exp env)
      (lambda (e)
        (define recur (interp-exp env))
        (verbose "R5/interp-exp" e)
        (match e
          ...
          [`(lambda: ([,xs : ,Ts] ...) : ,rT ,body)
           `(lambda ,xs ,body ,env)]
          [`(,fun ,args ...)
           (define fun-val ((interp-exp env) fun))
           (define arg-vals (map (interp-exp env) args))
           (match fun-val
             [`(lambda (,xs ...) ,body ,lam-env)
              (define new-env (append (map cons xs arg-vals) lam-env))
              ((interp-exp new-env) body)]
             [else (error "interp-exp, expected function, not" fun-val)])]
          [else (error 'interp-exp "unrecognized expression")]
          )))

    (define (interp-def env)
      (lambda (d)
        (match d
          [`(define (,f [,xs : ,ps] ...) : ,rt ,body)
           (mcons f `(lambda ,xs ,body ()))]
          )))

    (define (interp-R5 env)
      (lambda (p)
        (match p
          [(or `(program (type ,_) ,defs ... ,body)
               `(program ,defs ... ,body))
           (let ([top-level (map (interp-def '()) defs)])
             (for/list ([b top-level])
               (set-mcdr! b (match (mcdr b)
                      [`(lambda ,xs ,body ())
                       `(lambda ,xs ,body ,top-level)])))
         ((interp-exp top-level) body))]
          )))

## Type Checker for R5

The case for lambda.


## Free Variables

Def. A variable is *free with respect to an expression* e if the
variable occurs inside e but does not have an enclosing binding in e.

Use above example to show examples of free variables.

## Closure Representation

Figure 7.3 in book, diagram of g and h from above example.


