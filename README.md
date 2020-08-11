## Course Webpage for Compilers (P423, P523, E313, and E513)

Indiana University, Fall 2020


High-level programming languages like Racket make programming a
breeze, but how do they work? There's a big gap between Racket and
machine instructions for modern computers. Learn how to translate
Racket (a dialect of Scheme) programs all the way to Intel x86
assembly language.

Traditionally, compiler courses teach one phase of the compiler at a
time, such as parsing, semantic analysis, and register allocation. The
problem with that approach is it is difficult to understand how the
whole compiler fits together and why each phase is designed the way it
is. Instead, each week we implement a successively larger subset of
the Racket language. The very first subset is a tiny language of
integer arithmetic, and by the time we are done the language includes
first-class functions.

**Prerequisites:** B521 or C311. Fluency in Racket is highly recommended
as students will do a lot of programming in Racket. Prior knowledge of
an assembly language helps, but is not required.

**Textbook:** The notes for the course are available
[here](https://www.dropbox.com/s/ktdw8j0adcc44r0/book.pdf?dl=1). If
you have suggestions for improvement, please either send an email to
Jeremy or, even better, make edits to a branch of the book and perform
a pull request. The book is at the following location on github:

    https://github.com/IUCompilerCourse/Essentials-of-Compilation

**Lecture:** Tuesday and Thursday, 3:15pm to 4:30pm, on Zoom Meeting ID
  962 056 0998. (See the Piazza announcement for the passcode.)


**Office hours** with Jeremy Siek (jsiek): TBD

**Topics:**

* Instruction Selection

* Register Allocation

* Static type checking

* Conditional control flow

* Mutable data

* Garbage collection

* Procedures and calling conventions

* First-class functions and closure conversion

* Dynamic typing

* Generics

* High-level optimization (inlining, constant folding, copy
  propagation, etc.)

**Grading:**

Course grades are based on the following items. For the weighting, see
the Canvas panel on the right-hand side of this web page.

* Participation
    * Class attendance
    * Piazza questions and answers
    * Office hours attendance
* Assignments
* Midterm Exam (in class)
* Final Exam

**Assignments:**

Organize into teams of 2-4 students. Assignments will be due bi-weekly
on Mondays at 11:59pm. Teams that include one or more graduate
students are required to complete the challenge exercises. Turn in
your assignments by creating a github repository and giving access to
Jeremy. Assignments will be graded based on how many test cases they
pass. The test suite used for grading will be made available on Sunday
night, one day prior to the due date. The testing will be done on the
silo machine (linux). The testing will include both new tests and all
of the tests from prior assignments. Assignments may be turned in up
to one week late with a penalty of one letter grade. Students are
responsible for understanding the entire assignment and all of the
code that their team produces. The midterm and final exam are designed
to test a student's understanding of the assignments. The Final
Project is due Dec. 4 and may be turned in late up to Dec. 11.

**Email Discussion Group:** on [Piazza](piazza.com/iu/fall2020/p423p523e313e513)

**Resources:**

* [Racket](https://download.racket-lang.org/)
* [Racket Documentation](https://docs.racket-lang.org/)
* [Intel x86 Manual](http://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-manual-325462.pdf?_ga=1.200286509.2020252148.1452195021)
* [System V Application Binary Interface](https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf)
* [Github repository for utility code and test suites is here](https://github.com/IUCompilerCourse/public-student-support-code)
* [Uniprocessor Garbage Collection Techniques](https://iu.instructure.com/courses/1735985/files/82131907/download?wrap=1) by Wilson. 
* [Fast and Effective Procedure Inlining](https://www.cs.indiana.edu/~dyb/pubs/inlining.pdf) by Waddell and Dybvig.

