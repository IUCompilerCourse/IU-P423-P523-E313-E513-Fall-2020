#lang racket
(require "utilities.rkt")
(require "interp-R0.rkt")

;; 42
(define E1 (Int 42))                    

;; (read)
(define E2 (Prim 'read '()))            

;; (- 42)
(define E3 (Prim '- (list E1)))

;; (+ (- 42) 5)
(define E4 (Prim '+ (list E3 (Int 5)))) 

;; (+ (read) (- (read)))
(define E5 (Prim '+ (list E2 (Prim '- (list E2))))) 

(interp-R0 (Program '() E1))
(interp-R0 (Program '() E2))
(interp-R0 (Program '() E3))
(interp-R0 (Program '() E4))
(interp-R0 (Program '() E5))