

import ../zkernel_fixes
import ../zsys_clock


## * @}
## *
##  @cond INTERNAL_HIDDEN
##
# var K_STACK_FLAG_ALLOC* {.importc: "K_STACK_FLAG_ALLOC", header: "kernel.h".}: int

type
  stack_data_t* = pointer

  k_stack* {.importc: "k_stack", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    lock* {.importc: "lock".}: k_spinlock
    base* {.importc: "base".}: ptr stack_data_t
    next* {.importc: "next".}: ptr stack_data_t
    top* {.importc: "top".}: ptr stack_data_t
    flags* {.importc: "flags".}: uint8

# proc Z_STACK_INITIALIZER*(obj: untyped; stack_buffer: untyped;
                        #   stack_num_entries: untyped) {.
    # importc: "Z_STACK_INITIALIZER", header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @defgroup stack_apis Stack APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Initialize a stack.
##
##  This routine initializes a stack object, prior to its first use.
##
##  @param stack Address of the stack.
##  @param buffer Address of array used to hold stacked values.
##  @param num_entries Maximum number of values that can be stacked.
##
##  @return N/A
##
proc k_stack_init*(stack: ptr k_stack; buffer: ptr stack_data_t;
                  num_entries: uint32) {.importc: "k_stack_init",
    header: "kernel.h".}


## *
##  @brief Initialize a stack.
##
##  This routine initializes a stack object, prior to its first use. Internal
##  buffers will be allocated from the calling thread's resource pool.
##  This memory will be released if k_stack_cleanup() is called, or
##  userspace is enabled and the stack object loses all references to it.
##
##  @param stack Address of the stack.
##  @param num_entries Maximum number of values that can be stacked.
##
##  @return -ENOMEM if memory couldn't be allocated
##
proc k_stack_alloc_init*(stack: ptr k_stack; num_entries: uint32): int32 {.
    zsyscall, importc: "k_stack_alloc_init", header: "kernel.h".}


## *
##  @brief Release a stack's allocated buffer
##
##  If a stack object was given a dynamically allocated buffer via
##  k_stack_alloc_init(), this will free it. This function does nothing
##  if the buffer wasn't dynamically allocated.
##
##  @param stack Address of the stack.
##  @retval 0 on success
##  @retval -EAGAIN when object is still in use
##
proc k_stack_cleanup*(stack: ptr k_stack): cint {.importc: "k_stack_cleanup",
    header: "kernel.h".}


## *
##  @brief Push an element onto a stack.
##
##  This routine adds a stack_data_t value @a data to @a stack.
##
##  @funcprops \isr_ok
##
##  @param stack Address of the stack.
##  @param data Value to push onto the stack.
##
##  @retval 0 on success
##  @retval -ENOMEM if stack is full
##
proc k_stack_push*(stack: ptr k_stack; data: stack_data_t): cint {.zsyscall,
    importc: "k_stack_push", header: "kernel.h".}


## *
##  @brief Pop an element from a stack.
##
##  This routine removes a stack_data_t value from @a stack in a "last in,
##  first out" manner and stores the value in @a data.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##
##  @funcprops \isr_ok
##
##  @param stack Address of the stack.
##  @param data Address of area to hold the value popped from the stack.
##  @param timeout Waiting period to obtain a value,
##                 or one of the special values K_NO_WAIT and
##                 K_FOREVER.
##
##  @retval 0 Element popped from stack.
##  @retval -EBUSY Returned without waiting.
##  @retval -EAGAIN Waiting period timed out.
##
proc k_stack_pop*(stack: ptr k_stack; data: ptr stack_data_t; timeout: k_timeout_t): cint {.
    zsyscall, importc: "k_stack_pop", header: "kernel.h".}


## *
##  @brief Statically define and initialize a stack
##
##  The stack can be accessed outside the module where it is defined using:
##
##  @code extern struct k_stack <name>; @endcode
##
##  @param name Name of the stack.
##  @param stack_num_entries Maximum number of values that can be stacked.
##
proc K_STACK_DEFINE*(name: cminvtoken; stack_num_entries: static[int]) {.
    importc: "K_STACK_DEFINE", header: "kernel.h".}
