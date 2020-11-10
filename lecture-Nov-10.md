# Code Review of Functions


## Shrink

Changes `ProgramDefsExp` to `ProgramDefs` by adding a definition for
the `main` function.


## Reveal Functions

Changes `(Var f)` to `(FunRef f)` when `f` is the name of a function.


## Limit Functions

For functions with more than 6 parameters, reduce the number of
parameters to 6 by packing parameter 6 and higher into a vector.

* `Def` pass parameter 6 and higher in a vector
* `Var` replace some parameters with vector-refs


## Remove Complex Operands

`Apply` and `FunRef` are complex.

New auxiliary function `rco-def`.


## Explicate Control

Add cases for `Apply` and `FunRef`.

New auxiliary function `explicate-control-def`.


## Instruction Selection

* `FunRef` to `leaq`

* `Call` move arguments into registers, indirect call, move rax to lhs

* `TailCall` move arguments into registers, `TailJmp`
   (see `functions_tests_21.rkt`)

* `Return` as usual, jump to `conclusion` but need to
   add function name to `conclusion` label.

New auxiliary function `select-instr-def`.

* `Def` remove parameters, initial them from registers

* Add function name to `start` label


## Uncover Live

* Update `free-vars` to handle `FunRef`.

* Update `read-vars` and `write-vars` to handle
  `IndirectCallq`, `TailJmp`, and `leaq`.


## Build Interference

* `Callq` and `IndirectCallq`, add edges between live vectors and
   callee-saved registers


## Allocate Registers

New auxiliary function `allocate-registers-def`.

* `Def`

Perform register allocation separately for each function definition.
Adapt the code for `Program` in the past assignments.


## Patch Instructions

* `leaq` destination in a register

* `TailJmp` target in `rax`

New auxiliary function `patch-instr-def`.

## Print x86

### `FunRef` to PC-relative address

### `IndirectCallq` to `callq *`

### `TailJmp`

   insert conclusion
   indirect jump
  (see `functions_tests_21.s`)

### New auxiliary function `print-x86-def`, for `Def`

prelude:

1. Start with `.global` and `.align` directives followed
  by the label for the function.
2. Push `rbp` to the stack and set `rbp` to current stack
  pointer.
3. Push to the stack all of the callee-saved registers that were
  used for register allocation.
4. Move the stack pointer `rsp` down by the size of the stack
  frame for this function, which depends on the number of regular
  spills. (Aligned to 16 bytes.)
5. Move the root stack pointer `r15` up by the size of the
  root-stack frame for this function, which depends on the number of
  spilled vectors.
6. Initialize to zero all of the entries in the root-stack frame.
7. Jump to the start block.

The prelude of the `main` function has one additional task: call the
`initialize` function to set up the garbage collector and move the
value of the global `rootstack_begin` in `r15`. This should happen
before step 5 above, which depends on `r15`.

conclusion:

1. Move the stack pointer back up by the size of the stack frame
  for this function.
2. Restore the callee-saved registers by popping them from the
  stack.
3. Move the root stack pointer back down by the size of the
  root-stack frame for this function.
4. Restore `rbp` by popping it from the stack.
5. Return to the caller with the `retq` instruction.
