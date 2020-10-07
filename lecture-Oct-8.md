## Tuples and Garbage Collection

### Review of the previous lectures
  
* 2-space copying collector
* copy via Cheney's algorithm (BFS with Queue in the ToSpace)
* data representation (root stack, tuple metadata with pointer mask)
* passes:
    * `type-check`: introduce `HasType`
    * `shrink`
    * `expose-allocation` (new): `(vector ...)` becomes collect-allocate-initialize
    * `remove-complex-opera*`

### explicate-control
  
minor changes to handle the new forms
    
### uncover-locals
  
Collect the local variables and their types by inspecting
assignment statements. Store in the info field of Program.
  
### select-instructions (5.3.3)
  
We use `r11` for temporary storage and `r15` for the top of the root
stack, so we remove them from the list of registers used for
register allocation.

Here is where we implement the new operations needed for tuples.

* `vector-ref` turns into a movq with deref in the source
* `vector-set!` turns into movq with a deref in the target
* `(Assign lhs (Allocate len (Vector type ...)))`
   * put the current free_ptr into lhs
   * move the free_ptr forward by 8(len+1)   (room for tag)
   * initialize the tag (use bitwise-ior and arithmetic-shift)
     using the type information for the pointer mask.
* `(Collect bytes)`: turns into a `callq` to the collect function. 
  Pass the top of the root stack (`r15`) in register `rdi` and 
  the number of bytes in `rsi`.
       
### allocate-registers
  
* Spill vector-typed variables to the root stack. Handle this
  in the code for assigning homes (converting colors to
  stack locations and registers.)
* If a vector variable is live during a call to collect,
  make sure to spill it. Do this by adding interference edges
  between the call-live vector variables and the callee-saved
  registers. You'll need to pass the variable-type information
  as another parameter to build-interference.
  
### print-x89

* Move the root stack forward to make room for the vector spills.
* The first call to collect might happen before all the
  slots in the root stack have been initialized.
  So make sure to zero-initialize the root stack in the prelude!
