August 25
---------

Welcome to Compilers! (P423, P523, E313, E513)

* Instructors: Jeremy and Caner

* Roll call

* What's a compiler?

* Table of Contents of Essentials of Compilation

* Assignments, Quizzes, Exams, Grading, Academic Integrity

* Technology

    * Canvas FA20: COMPILERS: 10222
      Link to real course web page
      Grades

    * Web page:
      https://iucompilercourse.github.io/IU-P423-P523-E313-E513-Fall-2020/

    * Chat: Slack http://iu-compiler-course.slack.com/

    * Email group: Piazza http://piazza.com/iu/fall2020/p423p523e313e513/home

    * Lecture video:
      Zoom Meeting ID 950 3713 8921
      Google Meet https://meet.google.com/pyt-eqtm-pqw

    * Github repository for assignment submission, starter code

* What to do when technology fails

    * Zoom fails during lecture: communicate on slack, switch to Google Meet
    * Github: communicate on slack, wait
    * Technology glitches will not impact grades

* Concrete Syntax, Abstract Syntax Trees, Racket Structures

    * Programs in concrete syntax and in ASTs

            42

            (read)

            (- 10)
        
            (+ (- 10) 5)
        
            (+ (read) (- (read)))

    * Racket structures

            (struct Int (value))
            (struct Prim (op arg*))

    * Grammars
        * Concrete syntax
        
                exp ::= int | (read) | (- exp) | (+ exp exp) | (- exp exp)
                R0 ::= exp
        
        * Abstract syntax
        
                exp ::= (Int int) | (Prim 'read '()) 
                    | (Prim '- (list exp))
                    | (Prim '+ (list exp exp))
                R0 ::= (Program '() exp)


* Pattern Matching and Structural Recursion `R0-height.rkt`

