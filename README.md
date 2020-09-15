## Course Webpage for Compilers (P423, P523, E313, and E513)

Indiana University, Fall 2020


High-level programming languages like Racket make it easier to program
relative to low-level languages such as x86 assembly code. But how do
high-level languages work? There's a big gap between Racket and
machine instructions for modern computers. In this class you learn how
to translate Racket programs (a dialect of Scheme) all the way to x86
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
  950 3713 8921. (See the Piazza announcement for the password.)


**Lecture Notes and Recordings:**

* August 25 [Notes](./lecture-Aug-25.md), [Video](https://iu.mediaspace.kaltura.com/media/Compiler+Course/1_hwlujpzd): Introduction, Concrete and Abstract Syntax, Racket Structures, Grammars, 

* August 27 [Notes](./lecture-Aug-27.md), [Video](https://iu.mediaspace.kaltura.com/media/Compiler+Course%2C+August+27%2C+2020/0_pmzfbou3): Interpreters, Compiler Correctness, R1 Language, x86

* September 1 [Notes](./lecture-Sep-1.md), [Video](https://iu.mediaspace.kaltura.com/media/Compiler+Course%2C+September+1%2C+2020/1_7o6702no): Uniquify, Remove Complex Operands, Explicate Control

* September 3 [Notes](./lecture-Sep-3.md), [Video](https://iu.mediaspace.kaltura.com/media/Compiler+Course%2C+September+3%2C+2020/1_sqpe15y2): Select Instructions, Assign Homes, Path Instructions, Print x86

* September 8 [Notes](./lecture-Sep-8.md), [Video](https://iu.mediaspace.kaltura.com/media/Compiler+Course/1_vizyqbn0): Code Review

* September 10 [Notes](./lecture-Sep-10.md), [Video](https://iu.mediaspace.kaltura.com/media/Compiler+Course/1_cui0st1f): Register Allocation (Liveness Analysis, Build Interference Graph)

* September 15 [Notes](./lecture-Sep-15.md): Register Allocation (Graph Coloring)

**Office hours**

* Jeremy Siek (jsiek): Tuesdays 2-3pm, Thursdays 4:30-5:30pm.
  Zoom Meeting ID: 949 1594 8290.

* Caner Derici (cderici): Mondays 11am-12pm, Wednesdays 11am-12pm.
  Zoom Meeting ID: 774 5516 2736.

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
the Canvas panel on the right-hand side of this web page.  Grading
will take into account any technology problems that arrise, i.e., you
won't fail the class because your internet went out.

* Assignments
* Quizzes
* Midterm Exam (in class)
* Final Exam

**Assignments:**

Organize into teams of 2-4 students. Assignments will be due bi-weekly
on Mondays at 11:59pm. Teams that include one or more graduate
students are required to complete the challenge exercises.

Turn in your assignments by creating a github repository and giving
access to Jeremy (jsiek) and Caner (cderici).

Assignments will be graded based on how many test cases they succeed on.
Partial credit will be given for each "pass" of the compiler.
Some of the tests are in the public support code (see Resources below)
and the rest of the tests will be made available on Sunday night, one
day prior to the due date. The testing will be done on the linux
machine kj.luddy.indiana.edu named
after [Katherine
Johnson](https://en.wikipedia.org/wiki/Katherine_Johnson) of NASA
fame. The testing will include both new tests and all of the tests
from prior assignments.

You may request feedback on your assignments prior to the due date.
Just commit your work to github and send us email.

Students are responsible for understanding the entire assignment and
all of the code that their team produces. The midterm and final exam
are designed to test a student's understanding of the assignments.

Students are free to discuss and get help on the assignments from
anyone or anywhere. When posting questions on Piazza, it is OK to post
your code.

In contrast, for quizzes and exams, students are asked to work
alone. The quizzes and exams are closed book.  We will be using
Respondus Monitor for online proctoring.  

The Final Project is due Dec. 4 and may be turned in late up to
Dec. 11.

**Late assignment policy:** Assignments may be turned in up to one
week late with a penalty of 10%.


* **Assignment: Integers and Variables. Due Sep. 7.**

    Implement a compiler for the R1 language by completing the
    exercises in Chapter 2 of the course notes.
    The compiler should be in a file named `compiler.rkt`
    and it should include the following functions with exactly
    these names:

    * `uniquify`
    * `remove-complex-opera*`
    * `explicate-control`
    * `select-instructions`
    * `assign-homes`
    * `patch-instructions`
    * `print-x86`

    If there is a graduate student on your team, also complete the
    challenge exercises in Chapter 2, in which you implement a partial
    evaluator for the R1 language. The pass should be named
    ```partial-eval```.
    

* **Assignment: Register Allocation. Due Sep. 21.**


**Email Discussion Group:** on [Piazza](http://piazza.com/iu/fall2020/p423p523e313e513)

**Slack Chat/Messaging:**
  [Workspace](http://iu-compiler-course.slack.com/) (see invitation
  link on Piazza or
  [signup](https://join.slack.com/t/iu-compiler-course/signup?x=x-p1325281886868-1312364974614-1331891515409)
  using your iu email address).

**Resources:**

* [Github repository for support code and test suites is here](https://github.com/IUCompilerCourse/public-student-support-code)
* [Racket](https://download.racket-lang.org/)
* [Racket Documentation](https://docs.racket-lang.org/)
* [Intel x86 Manual](http://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-manual-325462.pdf?_ga=1.200286509.2020252148.1452195021)
* [System V Application Binary Interface](https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf)
* [Uniprocessor Garbage Collection Techniques](https://iu.instructure.com/courses/1735985/files/82131907/download?wrap=1) by Wilson. 
* [Fast and Effective Procedure Inlining](https://www.cs.indiana.edu/~dyb/pubs/inlining.pdf) by Waddell and Dybvig.

**Bias-Based Incident Reporting.**

Bias-based incident reports can be made by students, faculty and
staff. Any act of discrimination or harassment based on race,
ethnicity, religious affiliation, gender, gender identity, sexual
orientation or disability can be reported through any of the options:

1) email biasincident@indiana.edu or incident@indiana.edu;

2) call the Dean of Students Office at (812) 855-8188 or

3) use the IU mobile App (m.iu.edu). Reports can be made anonymously.

**Dean on Call.**

The Dean of Students office provides support for students dealing with
serious or emergency situations after 5 p.m. in which an immediate
response is needed and which cannot wait until the next business
day. Faculty or staff who are concerned about a student’s welfare
should feel free to call the Dean on Call at (812) 856-7774. This
number is not to be given to students or families but is for internal
campus use only. If someone is in immediate danger or experiencing an
emergency, call 911.

**Boost.**

Indiana University has developed an award-winning smartphone app to
help students stay on top of their schoolwork in Canvas. The app is
called “Boost,” it is available for free to all IU students, and it
integrates with Canvas to provide reminders about deadlines and other
helpful notifications. For more information, see
https://kb.iu.edu/d/atud.

**Counseling and Psychological Services.**

CAPS has expanded their services. For information about the variety of
services offered to students by CAPS visit:
http://healthcenter.indiana.edu/counseling/index.shtml.


**Disability Services for Students (DSS).**

The process to establish accommodations for a student with a
disability is a responsibility shared by the student and the DSS
Office. Only DSS approved accommodations should be utilized in the
classroom. After the student has met with DSS, it is the student’s
responsibility to share their accommodations with the faculty
member. For information about support services or accommodations
available to students with disabilities and for the procedures to be
followed by students and instructors, please visit:
https://studentaffairs.indiana.edu/disability-services-students/.

**Reporting Conduct and Student Wellness Concerns.**

All members of the IU community including faculty and staff may report
student conduct and wellness concerns to the Division of Student
Affairs using an online form located at
https://studentaffairs.indiana.edu/dean-students/student-concern/index.shtml.

**Students needing additional financial or other assistance.**

The Student Advocates Office (SAO) can help students work through
personal and academic problems as well as financial difficulties and
concerns. SAO also assists students working through grade appeals and
withdrawals from all classes. SAO also has emergency funds for IU
students experiencing emergency financial crisis
https://studentaffairs.indiana.edu/student- advocates/.

**Disruptive Students.**

If instructors are confronted by threatening behaviors from students
their first obligation is to insure the immediate safety of the
classroom. When in doubt, call IU Police at 9-911 from any campus
phone or call (812) 855-4111 from off-campus for immediate or
emergency situations. You may also contact the Dean of Students Office
at (812) 855-8188. For additional guidance in dealing with difficult
student situations:
https://ufc.iu.edu/doc/policies/disruptive-students.pdf.

**Academic Misconduct.**

If you suspect that a student has cheated, plagiarized or otherwise committed academic misconduct, refer to the Code of Student Rights, Responsibilities and Conduct:
http://studentcode.iu.edu/.

**Sexual Misconduct.**

As your instructor, one of my responsibilities is to create a positive
learning environment for all students. Title IX and IU’s Sexual
Misconduct Policy prohibit sexual misconduct in any form, including
sexual harassment, sexual assault, stalking, and dating and domestic
violence. If you have experienced sexual misconduct, or know someone
who has, the University can help.

If you are seeking help and would like to speak to someone
confidentially, you can make an appointment with:

* The Sexual Assault Crisis Services (SACS) at (812) 855-8900
  (counseling services)

* Confidential Victim Advocates (CVA) at (812) 856-2469 (advocacy and
  advice services)

* IU Health Center at (812) 855-4011 (health and medical services)

It is also important that you know that Title IX and University policy
require me to share any information brought to my attention about
potential sexual misconduct, with the campus Deputy Title IX
Coordinator or IU’s Title IX Coordinator. In that event, those
individuals will work to ensure that appropriate measures are taken
and resources are made available. Protecting student privacy is of
utmost concern, and information will only be shared with those that
need to know to ensure the University can respond and assist.  I
encourage you to visit
stopsexualviolence.iu.edu to learn more.
