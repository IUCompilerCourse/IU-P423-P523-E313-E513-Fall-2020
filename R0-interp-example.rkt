#lang racket
(require "utilities.rkt")
(require "interp-R0.rkt")

(define E1 (Int 42))                    ;; 42
(define E2 (Prim 'read '()))            ;; (read)
(define E3 (Prim '- (list E1)))         ;; (- 42)
(define E4 (Prim '+ (list E3 (Int 5)))) ;; (+ (- 42) 5)
(define E5 (Prim '+ (list E2 (Prim '- (list E2))))) ;; (+ (read) (- (read)))

(interp-R0 (Program '() E1))
(interp-R0 (Program '() E2))
(interp-R0 (Program '() E3))
(interp-R0 (Program '() E4))
(interp-R0 (Program '() E5))