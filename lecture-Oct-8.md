## Tuples and Garbage Collection

### Review of the previous lectures
  
* 2-space copying collector
* copy via Cheney's algorithm (BFS with Queue in the ToSpace)
* data representation (root stack, tuple metadata with pointer mask)
* running example:

        (let ([v (vector 42)])
           (let ([w (vector v)])
              (let ([v^ (vector-ref w 0)])
                 (vector-ref v^ 0))))

* review passes from last time
    * `type-check`: introduce `HasType`
    * `shrink`: update to generate `HasType`
    * `expose-allocation` (new): 
       `(vector ...)` becomes collect-allocate-initialize
    * `remove-complex-opera*`:
        * `collect`, `allocate`, and `global-value` are complex
        * careful not to separate `Prim` from its surrounding `HasType`

### explicate-control
  
minor changes to handle the new forms
    
### uncover-locals
  
Collect the local variables and their types by inspecting
assignment statements. Store in the info field of Program.
  
### select-instructions (5.3.3)
  
Here is where we implement the new operations needed for tuples.

example: block9056

* `vector-set!` turns into movq with a deref in the target

        lhs = (vector-set! vec n arg);
        
    becomes
    
        movq vec', %r11
        movq arg', 8(n+1)(%r11)
        movq $0, lhs'

    what if we use rax instead:

        movq vec', %rax
        movq -16(%rbp), 8(n+1)(%rax)
        movq $0, lhs'

        movq vec', %rax
        movq -16(%rbp), %rax
        movq %rax, 8(n+1)(%rax)
        movq $0, lhs'


    We use `r11` for temporary storage, so we remove it from the list
    of registers used for register allocation.

* `vector-ref` turns into a movq with deref in the source

        lhs = (vector-ref vec n);
        
    becomes
    
        movq vec', %r11
        movq 8(n+1)(%r11), lhs'

* `allocate`

   1. put the current free_ptr into lhs
   2. move the free_ptr forward by 8(len+1)   (room for tag)
   3. initialize the tag (use bitwise-ior and arithmetic-shift)
     using the type information for the pointer mask.

   So

        lhs = (allocate len (Vector type ...));

    becomes
    
        movq free_ptr(%rip), lhs'
        addq 8(len+1), free_ptr(%rip)
        movq lhs', %r11
        movq $tag, 0(%r11)
     
* `collect` turns into a `callq` to the collect function. 

    Pass the top of the root stack (`r15`) in register `rdi` and 
    the number of bytes in `rsi`.

        (collect bytes)
        
    becomes
    
        movq %r15, %rdi
        movq $bytes, %rsi
        callq collect
       
### allocate-registers
  
* Spill vector-typed variables to the root stack. Handle this
  in the code for assigning homes (converting colors to
  stack locations and registers.)
  
  Use r15 for the top of the root stack. Remove it from consideration
  by the register allocator.

* If a vector variable is live during a call to collect,
  make sure to spill it. Do this by adding interference edges
  between the call-live vector variables and the callee-saved
  registers. You'll need to pass the variable-type information
  as another parameter to build-interference.

  example: block9059: define vecinit9047
           -> block9058: collect
           -> block9056: use vecinit9047


### print-x89

* Move the root stack forward to make room for the vector spills.

* The first call to collect might happen before all the
  slots in the root stack have been initialized.
  So make sure to zero-initialize the root stack in the prelude!
