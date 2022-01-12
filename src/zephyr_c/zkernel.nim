##
##  Copyright (c) 2016, Wind River Systems, Inc.
##
##  SPDX-License-Identifier: Apache-2.0
##
## *
##  @file
##
##  @brief Public kernel APIs.
##

## *
##  @brief Kernel APIs
##  @defgroup kernel_apis Kernel APIs
##  @{
##  @}
##

import zconfs
import zkernel_fixes
import zsys_clock
import zatomic
import zthread

export zconfs
export zkernel_fixes
export zsys_clock
export zatomic
export zthread

const
  K_ANY* = nil
  K_END* = nil

proc K_PRIO_COOP*(x: cint): cint {.importc: "K_PRIO_COOP", header: "kernel.h".}
proc K_PRIO_PREEMPT*(x: cint): cint {.importc: "K_PRIO_PREEMPT", header: "kernel.h".}

var K_HIGHEST_THREAD_PRIO* {.importc: "$1", header: "kernel.h".}: int
var K_LOWEST_THREAD_PRIO* {.importc: "$1", header: "kernel.h".}: int
var K_IDLE_PRIO* {.importc: "$1", header: "kernel.h".}: int
var K_HIGHEST_APPLICATION_THREAD_PRIO* {.importc: "$1", header: "kernel.h".}: int
var K_LOWEST_APPLICATION_THREAD_PRIO* {.importc: "$1", header: "kernel.h".}: int

type
  execution_context_types* {.size: sizeof(cint).} = enum
    K_ISR = 0, K_COOP_THREAD, K_PREEMPT_THREAD


type
  k_thread_user_cb_t* = proc (thread: ptr k_thread; user_data: pointer)

  k_sem* {.importc: "k_sem", header: "kernel.h", incompleteStruct, bycopy.} = object
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    count* {.importc: "count".}: cuint
    limit* {.importc: "limit".}: cuint
    poll_events* {.importc: "poll_events".}: sys_dlist_t ##  _POLL_EVENT;

  k_heap* {.importc: "k_heap", header: "kernel.h", bycopy.} = object
    ##  kernel synchronized heap struct
    heap* {.importc: "heap".}: sys_heap
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    lock* {.importc: "lock".}: k_spinlock

## *
##  @brief Iterate over all the threads in the system.
##
##  This routine iterates over all the threads in the system and
##  calls the user_cb function for each thread.
##
##  @param user_cb Pointer to the user callback function.
##  @param user_data Pointer to user data.
##
##  @note @kconfig{CONFIG_THREAD_MONITOR} must be set for this function
##  to be effective.
##  @note This API uses @ref k_spin_lock to protect the _kernel.threads
##  list which means creation of new threads and terminations of existing
##  threads are blocked until this API returns.
##
##  @return N/A
##
proc k_thread_foreach*(user_cb: k_thread_user_cb_t; user_data: pointer) {.
    importc: "k_thread_foreach", header: "kernel.h".}





## *
##  @brief Iterate over all the threads in the system without locking.
##
##  This routine works exactly the same like @ref k_thread_foreach
##  but unlocks interrupts when user_cb is executed.
##
##  @param user_cb Pointer to the user callback function.
##  @param user_data Pointer to user data.
##
##  @note @kconfig{CONFIG_THREAD_MONITOR} must be set for this function
##  to be effective.
##  @note This API uses @ref k_spin_lock only when accessing the _kernel.threads
##  queue elements. It unlocks it during user callback function processing.
##  If a new task is created when this @c foreach function is in progress,
##  the added new task would not be included in the enumeration.
##  If a task is aborted during this enumeration, there would be a race here
##  and there is a possibility that this aborted task would be included in the
##  enumeration.
##  @note If the task is aborted and the memory occupied by its @c k_thread
##  structure is reused when this @c k_thread_foreach_unlocked is in progress
##  it might even lead to the system behave unstable.
##  This function may never return, as it would follow some @c next task
##  pointers treating given pointer as a pointer to the k_thread structure
##  while it is something different right now.
##  Do not reuse the memory that was occupied by k_thread structure of aborted
##  task if it was aborted after this function was called in any context.
##
proc k_thread_foreach_unlocked*(user_cb: k_thread_user_cb_t; user_data: pointer) {.
    importc: "k_thread_foreach_unlocked", header: "kernel.h".}


## * @}
## *
##  @defgroup thread_apis Thread APIs
##  @ingroup kernel_apis
##  @{
##


##
##  Thread user options. May be needed by assembly code. Common part uses low
##  bits, arch-specific use high bits.
##
## *
##  @brief system thread that must not abort
##

var K_ESSENTIAL* {.importc: "K_ESSENTIAL", header: "kernel.h".}: int


when CONFIG_FPU_SHARING:
  ## *
  ##  @brief FPU registers are managed by context switch
  ##
  ##  @details
  ##  This option indicates that the thread uses the CPU's floating point
  ##  registers. This instructs the kernel to take additional steps to save
  ##  and restore the contents of these registers when scheduling the thread.
  ##  No effect if @kconfig{CONFIG_FPU_SHARING} is not enabled.
  ##
  var K_FP_REGS* {.importc: "K_FP_REGS", header: "kernel.h".}: int


## *
##  @brief user mode thread
##
##  This thread has dropped from supervisor mode to user mode and consequently
##  has additional restrictions
##
var K_USER* {.importc: "K_USER", header: "kernel.h".}: int


## *
##  @brief Inherit Permissions
##
##  @details
##  Indicates that the thread being created should inherit all kernel object
##  permissions from the thread that created it. No effect if
##  @kconfig{CONFIG_USERSPACE} is not enabled.
##
var K_INHERIT_PERMS* {.importc: "K_INHERIT_PERMS", header: "kernel.h".}: int


## *
##  @brief Callback item state
##
##  @details
##  This is a single bit of state reserved for "callback manager"
##  utilities (p4wq initially) who need to track operations invoked
##  from within a user-provided callback they have been invoked.
##  Effectively it serves as a tiny bit of zero-overhead TLS data.
##

var K_CALLBACK_STATE* {.importc: "K_CALLBACK_STATE", header: "kernel.h".}: int


when CONFIG_X86:
  ##  x86 Bitmask definitions for threads user options
  when CONFIG_FPU_SHARING and CONFIG_X86_SSE:
    ## *
    ##  @brief FP and SSE registers are managed by context switch on x86
    ##
    ##  @details
    ##  This option indicates that the thread uses the x86 CPU's floating point
    ##  and SSE registers. This instructs the kernel to take additional steps to
    ##  save and restore the contents of these registers when scheduling
    ##  the thread. No effect if @kconfig{CONFIG_X86_SSE} is not enabled.
    ##
    var K_SSE_REGS* {.importc: "K_SSE_REGS", header: "kernel.h".}: int
##  end - thread options



## *
##  @brief Create a thread.
##
##  This routine initializes a thread, then schedules it for execution.
##
##  The new thread may be scheduled for immediate execution or a delayed start.
##  If the newly spawned thread does not have a delayed start the kernel
##  scheduler may preempt the current thread to allow the new thread to
##  execute.
##
##  Thread options are architecture-specific, and can include K_ESSENTIAL,
##  K_FP_REGS, and K_SSE_REGS. Multiple options may be specified by separating
##  them using "|" (the logical OR operator).
##
##  Stack objects passed to this function must be originally defined with
##  either of these macros in order to be portable:
##
##  - K_THREAD_STACK_DEFINE() - For stacks that may support either user or
##    supervisor threads.
##  - K_KERNEL_STACK_DEFINE() - For stacks that may support supervisor
##    threads only. These stacks use less memory if CONFIG_USERSPACE is
##    enabled.
##
##  The stack_size parameter has constraints. It must either be:
##
##  - The original size value passed to K_THREAD_STACK_DEFINE() or
##    K_KERNEL_STACK_DEFINE()
##  - The return value of K_THREAD_STACK_SIZEOF(stack) if the stack was
##    defined with K_THREAD_STACK_DEFINE()
##  - The return value of K_KERNEL_STACK_SIZEOF(stack) if the stack was
##    defined with K_KERNEL_STACK_DEFINE().
##
##  Using other values, or sizeof(stack) may produce undefined behavior.
##
##  @param new_thread Pointer to uninitialized struct k_thread
##  @param stack Pointer to the stack space.
##  @param stack_size Stack size in bytes.
##  @param entry Thread entry function.
##  @param p1 1st entry point parameter.
##  @param p2 2nd entry point parameter.
##  @param p3 3rd entry point parameter.
##  @param prio Thread priority.
##  @param options Thread options.
##  @param delay Scheduling delay, or K_NO_WAIT (for no delay).
##
##  @return ID of new thread.
##
##
proc k_thread_create*(new_thread: ptr k_thread; stack: ptr k_thread_stack_t;
                      stack_size: csize_t; entry: k_thread_entry_t; p1: pointer;
                      p2: pointer; p3: pointer; prio: cint; options: uint32;
                      delay: k_timeout_t): k_tid_t {.zsyscall,
    importc: "k_thread_create", header: "kernel.h".}






## *
##  @brief Drop a thread's privileges permanently to user mode
##
##  This allows a supervisor thread to be re-used as a user thread.
##  This function does not return, but control will transfer to the provided
##  entry point as if this was a new user thread.
##
##  The implementation ensures that the stack buffer contents are erased.
##  Any thread-local storage will be reverted to a pristine state.
##
##  Memory domain membership, resource pool assignment, kernel object
##  permissions, priority, and thread options are preserved.
##
##  A common use of this function is to re-use the main thread as a user thread
##  once all supervisor mode-only tasks have been completed.
##
##  @param entry Function to start executing from
##  @param p1 1st entry point parameter
##  @param p2 2nd entry point parameter
##  @param p3 3rd entry point parameter
##
proc k_thread_user_mode_enter*(entry: k_thread_entry_t; p1: pointer; p2: pointer;
                              p3: pointer) {.
    importc: "k_thread_user_mode_enter", header: "kernel.h".}





## *
##  @brief Grant a thread access to a set of kernel objects
##
##  This is a convenience function. For the provided thread, grant access to
##  the remaining arguments, which must be pointers to kernel objects.
##
##  The thread object must be initialized (i.e. running). The objects don't
##  need to be.
##  Note that NULL shouldn't be passed as an argument.
##
##  @param thread Thread to grant access to objects
##  @param ... list of kernel object pointers
##
proc k_thread_access_grant*(thread: k_tid_t, args: varargs[ptr k_sem]) {.varargs,
    importc: "k_thread_access_grant", header: "kernel.h".}





## *
##  @brief Assign a resource memory pool to a thread
##
##  By default, threads have no resource pool assigned unless their parent
##  thread has a resource pool, in which case it is inherited. Multiple
##  threads may be assigned to the same memory pool.
##
##  Changing a thread's resource pool will not migrate allocations from the
##  previous pool.
##
##  @param thread Target thread to assign a memory pool for resource requests.
##  @param heap Heap object to use for resources,
##              or NULL if the thread should no longer have a memory pool.
##
proc k_thread_heap_assign*(thread: ptr k_thread; heap: ptr k_heap) {.
    importc: "$1", header: "kernel.h".}


when CONFIG_INIT_STACKS and CONFIG_THREAD_STACK_INFO:
  ## *
  ##  @brief Obtain stack usage information for the specified thread
  ##
  ##  User threads will need to have permission on the target thread object.
  ##
  ##  Some hardware may prevent inspection of a stack buffer currently in use.
  ##  If this API is called from supervisor mode, on the currently running thread,
  ##  on a platform which selects @kconfig{CONFIG_NO_UNUSED_STACK_INSPECTION}, an
  ##  error will be generated.
  ##
  ##  @param thread Thread to inspect stack information
  ##  @param unused_ptr Output parameter, filled in with the unused stack space
  ## 	of the target thread in bytes.
  ##  @return 0 on success
  ##  @return -EBADF Bad thread object (user mode only)
  ##  @return -EPERM No permissions on thread object (user mode only)
  ##  #return -ENOTSUP Forbidden by hardware policy
  ##  @return -EINVAL Thread is uninitialized or exited (user mode only)
  ##  @return -EFAULT Bad memory address for unused_ptr (user mode only)
  ##
  proc k_thread_stack_space_get*(thread: ptr k_thread; unused_ptr: ptr csize_t): cint {.
      zsyscall, importc: "k_thread_stack_space_get", header: "kernel.h".}



## *
##  @brief Assign the system heap as a thread's resource pool
##
##  Similar to z_thread_heap_assign(), but the thread will use
##  the kernel heap to draw memory.
##
##  Use with caution, as a malicious thread could perform DoS attacks on the
##  kernel heap.
##
##  @param thread Target thread to assign the system heap for resource requests
##
##
proc k_thread_system_pool_assign*(thread: ptr k_thread) {.
    importc: "k_thread_system_pool_assign", header: "kernel.h".}





## *
##  @brief Sleep until a thread exits
##
##  The caller will be put to sleep until the target thread exits, either due
##  to being aborted, self-exiting, or taking a fatal error. This API returns
##  immediately if the thread isn't running.
##
##  This API may only be called from ISRs with a K_NO_WAIT timeout,
##  where it can be useful as a predicate to detect when a thread has
##  aborted.
##
##  @param thread Thread to wait to exit
##  @param timeout upper bound time to wait for the thread to exit.
##  @retval 0 success, target thread has exited or wasn't running
##  @retval -EBUSY returned without waiting
##  @retval -EAGAIN waiting period timed out
##  @retval -EDEADLK target thread is joining on the caller, or target thread
##                   is the caller
##
proc k_thread_join*(thread: ptr k_thread; timeout: k_timeout_t): cint {.zsyscall,
    importc: "k_thread_join", header: "kernel.h".}





## *
##  @brief Put the current thread to sleep.
##
##  This routine puts the current thread to sleep for @a duration,
##  specified as a k_timeout_t object.
##
##  @note if @a timeout is set to K_FOREVER then the thread is suspended.
##
##  @param timeout Desired duration of sleep.
##
##  @return Zero if the requested time has elapsed or the number of milliseconds
##  left to sleep, if thread was woken up by \ref k_wakeup call.
##
proc k_sleep*(timeout: k_timeout_t): int32 {.zsyscall, importc: "k_sleep",
    header: "kernel.h".}





## *
##  @brief Put the current thread to sleep.
##
##  This routine puts the current thread to sleep for @a duration milliseconds.
##
##  @param ms Number of milliseconds to sleep.
##
##  @return Zero if the requested time has elapsed or the number of milliseconds
##  left to sleep, if thread was woken up by \ref k_wakeup call.
##
proc k_msleep*(ms: int32): int32 {.zsyscall, importc: "$1", header: "kernel.h".}


## *
##  @brief Put the current thread to sleep with microsecond resolution.
##
##  This function is unlikely to work as expected without kernel tuning.
##  In particular, because the lower bound on the duration of a sleep is
##  the duration of a tick, @kconfig{CONFIG_SYS_CLOCK_TICKS_PER_SEC} must be
##  adjusted to achieve the resolution desired. The implications of doing
##  this must be understood before attempting to use k_usleep(). Use with
##  caution.
##
##  @param us Number of microseconds to sleep.
##
##  @return Zero if the requested time has elapsed or the number of microseconds
##  left to sleep, if thread was woken up by \ref k_wakeup call.
##
proc k_usleep*(ms: int32): int32 {.zsyscall, importc: "$1", header: "kernel.h".}





## *
##  @brief Cause the current thread to busy wait.
##
##  This routine causes the current thread to execute a "do nothing" loop for
##  @a usec_to_wait microseconds.
##
##  @note The clock used for the microsecond-resolution delay here may
##  be skewed relative to the clock used for system timeouts like
##  k_sleep().  For example k_busy_wait(1000) may take slightly more or
##  less time than k_sleep(K_MSEC(1)), with the offset dependent on
##  clock tolerances.
##
##  @return N/A
##
proc k_busy_wait*(usec_to_wait: uint32) {.zsyscall, importc: "k_busy_wait",
    header: "kernel.h".}





## *
##  @brief Yield the current thread.
##
##  This routine causes the current thread to yield execution to another
##  thread of the same or higher priority. If there are no other ready threads
##  of the same or higher priority, the routine returns immediately.
##
##  @return N/A
##
proc k_yield*() {.zsyscall, importc: "k_yield", header: "kernel.h".}





## *
##  @brief Wake up a sleeping thread.
##
##  This routine prematurely wakes up @a thread from sleeping.
##
##  If @a thread is not currently sleeping, the routine has no effect.
##
##  @param thread ID of thread to wake.
##
##  @return N/A
##
proc k_wakeup*(thread: k_tid_t) {.zsyscall, importc: "k_wakeup", header: "kernel.h".}





## *
##  @brief Get thread ID of the current thread.
##
##  This unconditionally queries the kernel via a system call.
##
##  @return ID of current thread.
##
proc z_current_get*(): k_tid_t {.zsyscall, importc: "z_current_get",
                              header: "kernel.h".}

when CONFIG_THREAD_LOCAL_STORAGE:
  ##  Thread-local cache of current thread ID, set in z_thread_entry()
  var z_tls_current* {.importc: "z_tls_current", header: "kernel.h".}: k_tid_t



## *
##  @brief Get thread ID of the current thread.
##
##  @return ID of current thread.
##
##
proc k_current_get*(): k_tid_t =
  when CONFIG_THREAD_LOCAL_STORAGE:
    return z_tls_current
  else:
    return z_current_get()

## *
##  @brief Abort a thread.
##
##  This routine permanently stops execution of @a thread. The thread is taken
##  off all kernel queues it is part of (i.e. the ready queue, the timeout
##  queue, or a kernel object wait queue). However, any kernel resources the
##  thread might currently own (such as mutexes or memory blocks) are not
##  released. It is the responsibility of the caller of this routine to ensure
##  all necessary cleanup is performed.
##
##  After k_thread_abort() returns, the thread is guaranteed not to be
##  running or to become runnable anywhere on the system.  Normally
##  this is done via blocking the caller (in the same manner as
##  k_thread_join()), but in interrupt context on SMP systems the
##  implementation is required to spin for threads that are running on
##  other CPUs.  Note that as specified, this means that on SMP
##  platforms it is possible for application code to create a deadlock
##  condition by simultaneously aborting a cycle of threads using at
##  least one termination from interrupt context.  Zephyr cannot detect
##  all such conditions.
##
##  @param thread ID of thread to abort.
##
##  @return N/A
##
proc k_thread_abort*(thread: k_tid_t) {.zsyscall, importc: "k_thread_abort",
                                      header: "kernel.h".}





## *
##  @brief Start an inactive thread
##
##  If a thread was created with K_FOREVER in the delay parameter, it will
##  not be added to the scheduling queue until this function is called
##  on it.
##
##  @param thread thread to start
##
proc k_thread_start*(thread: k_tid_t) {.zsyscall, importc: "k_thread_start",
                                      header: "kernel.h".}

proc z_timeout_expires*(timeout: ptr k_priv_timeout): k_ticks_t {.
    importc: "z_timeout_expires", header: "kernel.h".}

proc z_timeout_remaining*(timeout: ptr k_priv_timeout): k_ticks_t {.
    importc: "z_timeout_remaining", header: "kernel.h".}



when CONFIG_SYS_CLOCK_EXISTS:
  ## *
  ##  @brief Get time when a thread wakes up, in system ticks
  ##
  ##  This routine computes the system uptime when a waiting thread next
  ##  executes, in units of system ticks.  If the thread is not waiting,
  ##  it returns current system time.
  ##
  proc k_thread_timeout_expires_ticks*(t: ptr k_thread): k_ticks_t {.zsyscall,
      importc: "k_thread_timeout_expires_ticks", header: "kernel.h".}

  ## *
  ##  @brief Get time remaining before a thread wakes up, in system ticks
  ##
  ##  This routine computes the time remaining before a waiting thread
  ##  next executes, in units of system ticks.  If the thread is not
  ##  waiting, it returns zero.
  ##
  proc k_thread_timeout_remaining_ticks*(t: ptr k_thread): k_ticks_t {.zsyscall,
      importc: "k_thread_timeout_remaining_ticks", header: "kernel.h".}

## *
##  @cond INTERNAL_HIDDEN
##
##  timeout has timed out and is not on _timeout_q anymore
# var _EXPIRED* {.importc: "_EXPIRED", header: "kernel.h".}: int

type
  z_static_thread_data* {.importc: "_static_thread_data", header: "kernel.h", bycopy.} = object
    init_thread* {.importc: "init_thread".}: ptr k_thread
    init_stack* {.importc: "init_stack".}: ptr k_thread_stack_t
    init_stack_size* {.importc: "init_stack_size".}: cuint
    init_entry* {.importc: "init_entry".}: k_thread_entry_t
    init_p1* {.importc: "init_p1".}: pointer
    init_p2* {.importc: "init_p2".}: pointer
    init_p3* {.importc: "init_p3".}: pointer
    init_prio* {.importc: "init_prio".}: cint
    init_options* {.importc: "init_options".}: uint32
    init_delay* {.importc: "init_delay".}: int32
    init_abort* {.importc: "init_abort".}: proc ()
    init_name* {.importc: "init_name".}: cstring

proc Z_THREAD_INITIALIZER*(thread: ptr k_thread;
                           stack: ptr k_thread_stack_t;
                           stack_size: csize_t;
                           entry: k_thread_proc;
                           p1, p2, p3: pointer;
                           prio: cint;
                           options: uint32;
                           delay: k_timeout_t;
                           abort: proc () {.cdecl.};
                           tname: cstring) {.
    importc: "Z_THREAD_INITIALIZER", header: "kernel.h".}



## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @brief Statically define and initialize a thread.
##
##  The thread may be scheduled for immediate execution or a delayed start.
##
##  Thread options are architecture-specific, and can include K_ESSENTIAL,
##  K_FP_REGS, and K_SSE_REGS. Multiple options may be specified by separating
##  them using "|" (the logical OR operator).
##
##  The ID of the thread can be accessed using:
##
##  @code extern const k_tid_t <name>; @endcode
##
##  @param name Name of the thread.
##  @param stack_size Stack size in bytes.
##  @param entry Thread entry function.
##  @param p1 1st entry point parameter.
##  @param p2 2nd entry point parameter.
##  @param p3 3rd entry point parameter.
##  @param prio Thread priority.
##  @param options Thread options.
##  @param delay Scheduling delay (in milliseconds), zero for no delay.
##
##
##  @internal It has been observed that the x86 compiler by default aligns
##  these _static_thread_data structures to 32-byte boundaries, thereby
##  wasting space. To work around this, force a 4-byte alignment.
##
##
# template K_THREAD_DEFINE*(name: untyped;
#                           stack_size: untyped;
#                           entry: untyped;
#                           p1: untyped;
#                           p2: untyped;
#                           p3: untyped;
#                           prio: untyped;
#                           options: untyped;
#                           delay: untyped) =
#   K_THREAD_STACK_DEFINE(`k_thread_stack name`, stack_size)
#   struct k_thread _k_thread_obj_##name;
#   STRUCT_SECTION_ITERABLE(_static_thread_data, _k_thread_data_##name) = \
#     Z_THREAD_INITIALIZER(&_k_thread_obj_##name,		 \
#      _k_thread_stack_##name, stack_size,  \
#      entry, p1, p2, p3, prio, options, delay, \
#      NULL, name);				 	 \
#   const k_tid_t name = (k_tid_t)&_k_thread_obj_##name






## *
##  @brief Get a thread's priority.
##
##  This routine gets the priority of @a thread.
##
##  @param thread ID of thread whose priority is needed.
##
##  @return Priority of @a thread.
##
proc k_thread_priority_get*(thread: k_tid_t): cint {.zsyscall,
    importc: "k_thread_priority_get", header: "kernel.h".}





## *
##  @brief Set a thread's priority.
##
##  This routine immediately changes the priority of @a thread.
##
##  Rescheduling can occur immediately depending on the priority @a thread is
##  set to:
##
##  - If its priority is raised above the priority of the caller of this
##  function, and the caller is preemptible, @a thread will be scheduled in.
##
##  - If the caller operates on itself, it lowers its priority below that of
##  other threads in the system, and the caller is preemptible, the thread of
##  highest priority will be scheduled in.
##
##  Priority can be assigned in the range of -CONFIG_NUM_COOP_PRIORITIES to
##  CONFIG_NUM_PREEMPT_PRIORITIES-1, where -CONFIG_NUM_COOP_PRIORITIES is the
##  highest priority.
##
##  @param thread ID of thread whose priority is to be set.
##  @param prio New priority.
##
##  @warning Changing the priority of a thread currently involved in mutex
##  priority inheritance may result in undefined behavior.
##
##  @return N/A
##
proc k_thread_priority_set*(thread: k_tid_t; prio: cint) {.zsyscall,
    importc: "k_thread_priority_set", header: "kernel.h".}



when CONFIG_SCHED_DEADLINE:
  ## *
  ##  @brief Set deadline expiration time for scheduler
  ##
  ##  This sets the "deadline" expiration as a time delta from the
  ##  current time, in the same units used by k_cycle_get_32().  The
  ##  scheduler (when deadline scheduling is enabled) will choose the
  ##  next expiring thread when selecting between threads at the same
  ##  static priority.  Threads at different priorities will be scheduled
  ##  according to their static priority.
  ##
  ##  @note Deadlines are stored internally using 32 bit unsigned
  ##  integers.  The number of cycles between the "first" deadline in the
  ##  scheduler queue and the "last" deadline must be less than 2^31 (i.e
  ##  a signed non-negative quantity).  Failure to adhere to this rule
  ##  may result in scheduled threads running in an incorrect deadline
  ##  order.
  ##
  ##  @note Despite the API naming, the scheduler makes no guarantees the
  ##  the thread WILL be scheduled within that deadline, nor does it take
  ##  extra metadata (like e.g. the "runtime" and "period" parameters in
  ##  Linux sched_setattr()) that allows the kernel to validate the
  ##  scheduling for achievability.  Such features could be implemented
  ##  above this call, which is simply input to the priority selection
  ##  logic.
  ##
  ##  @note You should enable @kconfig{CONFIG_SCHED_DEADLINE} in your project
  ##  configuration.
  ##
  ##  @param thread A thread on which to set the deadline
  ##  @param deadline A time delta, in cycle units
  ##
  ##
  proc k_thread_deadline_set*(thread: k_tid_t; deadline: cint) {.zsyscall,
      importc: "k_thread_deadline_set", header: "kernel.h".}



when CONFIG_SCHED_CPU_MASK:
  ## *
  ##  @brief Sets all CPU enable masks to zero
  ##
  ##  After this returns, the thread will no longer be schedulable on any
  ##  CPUs.  The thread must not be currently runnable.
  ##
  ##  @note You should enable @kconfig{CONFIG_SCHED_DEADLINE} in your project
  ##  configuration.
  ##
  ##  @param thread Thread to operate upon
  ##  @return Zero on success, otherwise error code
  ##
  proc k_thread_cpu_mask_clear*(thread: k_tid_t): cint {.
      importc: "k_thread_cpu_mask_clear", header: "kernel.h".}


  ## *
  ##  @brief Sets all CPU enable masks to one
  ##
  ##  After this returns, the thread will be schedulable on any CPU.  The
  ##  thread must not be currently runnable.
  ##
  ##  @note You should enable @kconfig{CONFIG_SCHED_DEADLINE} in your project
  ##  configuration.
  ##
  ##  @param thread Thread to operate upon
  ##  @return Zero on success, otherwise error code
  ##
  proc k_thread_cpu_mask_enable_all*(thread: k_tid_t): cint {.
      importc: "k_thread_cpu_mask_enable_all", header: "kernel.h".}


  ## *
  ##  @brief Enable thread to run on specified CPU
  ##
  ##  The thread must not be currently runnable.
  ##
  ##  @note You should enable @kconfig{CONFIG_SCHED_DEADLINE} in your project
  ##  configuration.
  ##
  ##  @param thread Thread to operate upon
  ##  @param cpu CPU index
  ##  @return Zero on success, otherwise error code
  ##
  proc k_thread_cpu_mask_enable*(thread: k_tid_t; cpu: cint): cint {.
      importc: "k_thread_cpu_mask_enable", header: "kernel.h".}


  ## *
  ##  @brief Prevent thread to run on specified CPU
  ##
  ##  The thread must not be currently runnable.
  ##
  ##  @note You should enable @kconfig{CONFIG_SCHED_DEADLINE} in your project
  ##  configuration.
  ##
  ##  @param thread Thread to operate upon
  ##  @param cpu CPU index
  ##  @return Zero on success, otherwise error code
  ##
  proc k_thread_cpu_mask_disable*(thread: k_tid_t; cpu: cint): cint {.
      importc: "k_thread_cpu_mask_disable", header: "kernel.h".}





## *
##  @brief Suspend a thread.
##
##  This routine prevents the kernel scheduler from making @a thread
##  the current thread. All other internal operations on @a thread are
##  still performed; for example, kernel objects it is waiting on are
##  still handed to it.  Note that any existing timeouts
##  (e.g. k_sleep(), or a timeout argument to k_sem_take() et. al.)
##  will be canceled.  On resume, the thread will begin running
##  immediately and return from the blocked call.
##
##  If @a thread is already suspended, the routine has no effect.
##
##  @param thread ID of thread to suspend.
##
##  @return N/A
##
proc k_thread_suspend*(thread: k_tid_t) {.zsyscall, importc: "k_thread_suspend",
    header: "kernel.h".}





## *
##  @brief Resume a suspended thread.
##
##  This routine allows the kernel scheduler to make @a thread the current
##  thread, when it is next eligible for that role.
##
##  If @a thread is not currently suspended, the routine has no effect.
##
##  @param thread ID of thread to resume.
##
##  @return N/A
##
proc k_thread_resume*(thread: k_tid_t) {.zsyscall, importc: "k_thread_resume",
                                      header: "kernel.h".}





## *
##  @brief Set time-slicing period and scope.
##
##  This routine specifies how the scheduler will perform time slicing of
##  preemptible threads.
##
##  To enable time slicing, @a slice must be non-zero. The scheduler
##  ensures that no thread runs for more than the specified time limit
##  before other threads of that priority are given a chance to execute.
##  Any thread whose priority is higher than @a prio is exempted, and may
##  execute as long as desired without being preempted due to time slicing.
##
##  Time slicing only limits the maximum amount of time a thread may continuously
##  execute. Once the scheduler selects a thread for execution, there is no
##  minimum guaranteed time the thread will execute before threads of greater or
##  equal priority are scheduled.
##
##  When the current thread is the only one of that priority eligible
##  for execution, this routine has no effect; the thread is immediately
##  rescheduled after the slice period expires.
##
##  To disable timeslicing, set both @a slice and @a prio to zero.
##
##  @param slice Maximum time slice length (in milliseconds).
##  @param prio Highest thread priority level eligible for time slicing.
##
##  @return N/A
##
proc k_sched_time_slice_set*(slice: int32; prio: cint) {.
    importc: "k_sched_time_slice_set", header: "kernel.h".}





## * @}
## *
##  @addtogroup isr_apis
##  @{
##
## *
##  @brief Determine if code is running at interrupt level.
##
##  This routine allows the caller to customize its actions, depending on
##  whether it is a thread or an ISR.
##
##  @funcprops \isr_ok
##
##  @return false if invoked by a thread.
##  @return true if invoked by an ISR.
##
proc k_is_in_isr*(): bool {.importc: "k_is_in_isr", header: "kernel.h".}





## *
##  @brief Determine if code is running in a preemptible thread.
##
##  This routine allows the caller to customize its actions, depending on
##  whether it can be preempted by another thread. The routine returns a 'true'
##  value if all of the following conditions are met:
##
##  - The code is running in a thread, not at ISR.
##  - The thread's priority is in the preemptible range.
##  - The thread has not locked the scheduler.
##
##  @funcprops \isr_ok
##
##  @return 0 if invoked by an ISR or by a cooperative thread.
##  @return Non-zero if invoked by a preemptible thread.
##
proc k_is_preempt_thread*(): cint {.zsyscall, importc: "k_is_preempt_thread",
                                  header: "kernel.h".}





## *
##  @brief Test whether startup is in the before-main-task phase.
##
##  This routine allows the caller to customize its actions, depending on
##  whether it being invoked before the kernel is fully active.
##
##  @funcprops \isr_ok
##
##  @return true if invoked before post-kernel initialization
##  @return false if invoked during/after post-kernel initialization
##
proc k_is_pre_kernel*(): bool {.
    importc: "$1", header: "kernel.h".}


## *
##  @}
##
## *
##  @addtogroup thread_apis
##  @{
##
## *
##  @brief Lock the scheduler.
##
##  This routine prevents the current thread from being preempted by another
##  thread by instructing the scheduler to treat it as a cooperative thread.
##  If the thread subsequently performs an operation that makes it unready,
##  it will be context switched out in the normal manner. When the thread
##  again becomes the current thread, its non-preemptible status is maintained.
##
##  This routine can be called recursively.
##
##  @note k_sched_lock() and k_sched_unlock() should normally be used
##  when the operation being performed can be safely interrupted by ISRs.
##  However, if the amount of processing involved is very small, better
##  performance may be obtained by using irq_lock() and irq_unlock().
##
##  @return N/A
##
proc k_sched_lock*() {.importc: "k_sched_lock", header: "kernel.h".}


## *
##  @brief Unlock the scheduler.
##
##  This routine reverses the effect of a previous call to k_sched_lock().
##  A thread must call the routine once for each time it called k_sched_lock()
##  before the thread becomes preemptible.
##
##  @return N/A
##
proc k_sched_unlock*() {.importc: "k_sched_unlock", header: "kernel.h".}


## *
##  @brief Set current thread's custom data.
##
##  This routine sets the custom data for the current thread to @ value.
##
##  Custom data is not used by the kernel itself, and is freely available
##  for a thread to use as it sees fit. It can be used as a framework
##  upon which to build thread-local storage.
##
##  @param value New custom data value.
##
##  @return N/A
##
##
proc k_thread_custom_data_set*(value: pointer) {.zsyscall,
    importc: "k_thread_custom_data_set", header: "kernel.h".}


## *
##  @brief Get current thread's custom data.
##
##  This routine returns the custom data for the current thread.
##
##  @return Current custom data value.
##
proc k_thread_custom_data_get*(): pointer {.zsyscall,
    importc: "k_thread_custom_data_get", header: "kernel.h".}


## *
##  @brief Set current thread name
##
##  Set the name of the thread to be used when @kconfig{CONFIG_THREAD_MONITOR}
##  is enabled for tracing and debugging.
##
##  @param thread Thread to set name, or NULL to set the current thread
##  @param str Name string
##  @retval 0 on success
##  @retval -EFAULT Memory access error with supplied string
##  @retval -ENOSYS Thread name configuration option not enabled
##  @retval -EINVAL Thread name too long
##
proc k_thread_name_set*(thread: k_tid_t; str: cstring): cint {.zsyscall,
    importc: "k_thread_name_set", header: "kernel.h".}




## *
##  @brief Get thread name
##
##  Get the name of a thread
##
##  @param thread Thread ID
##  @retval Thread name, or NULL if configuration not enabled
##
proc k_thread_name_get*(thread: k_tid_t): cstring {.importc: "k_thread_name_get",
    header: "kernel.h".}




## *
##  @brief Copy the thread name into a supplied buffer
##
##  @param thread Thread to obtain name information
##  @param buf Destination buffer
##  @param size Destination buffer size
##  @retval -ENOSPC Destination buffer too small
##  @retval -EFAULT Memory access error
##  @retval -ENOSYS Thread name feature not enabled
##  @retval 0 Success
##
proc k_thread_name_copy*(thread: k_tid_t; buf: cstring; size: csize_t): cint {.
    zsyscall, importc: "k_thread_name_copy", header: "kernel.h".}




## *
##  @brief Get thread state string
##
##  Get the human friendly thread state string
##
##  @param thread_id Thread ID
##  @retval Thread state string, empty if no state flag is set
##
proc k_thread_state_str*(thread_id: k_tid_t): cstring {.
    importc: "k_thread_state_str", header: "kernel.h".}




## *
##  @}
##
## *
##  @addtogroup clock_apis
##  @{
##
## *
##  @brief Generate null timeout delay.
##
##  This macro generates a timeout delay that instructs a kernel API
##  not to wait if the requested operation cannot be performed immediately.
##
##  @return Timeout delay value.
##
proc K_NO_WAIT*(): k_timeout_t {.importc: "K_NO_WAIT", header: "kernel.h".}

## *
##  @brief Generate timeout delay from nanoseconds.
##
##  This macro generates a timeout delay that instructs a kernel API to
##  wait up to @a t nanoseconds to perform the requested operation.
##  Note that timer precision is limited to the tick rate, not the
##  requested value.
##
##  @param t Duration in nanoseconds.
##
##  @return Timeout delay value.
##
proc K_NSEC*(t: int): k_timeout_t {.importc: "K_NSEC", header: "kernel.h".}


## *
##  @brief Generate timeout delay from microseconds.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait up to @a t microseconds to perform the requested operation.
##  Note that timer precision is limited to the tick rate, not the
##  requested value.
##
##  @param t Duration in microseconds.
##
##  @return Timeout delay value.
##
proc K_USEC*(t: int): k_timeout_t {.importc: "K_USEC", header: "kernel.h".}


## *
##  @brief Generate timeout delay from cycles.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait up to @a t cycles to perform the requested operation.
##
##  @param t Duration in cycles.
##
##  @return Timeout delay value.
##
proc K_CYC*(t: int): k_timeout_t {.importc: "K_CYC", header: "kernel.h".}


## *
##  @brief Generate timeout delay from system ticks.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait up to @a t ticks to perform the requested operation.
##
##  @param t Duration in system ticks.
##
##  @return Timeout delay value.
##
proc K_TICKS*(t: int): k_timeout_t {.importc: "K_TICKS", header: "kernel.h".}


## *
##  @brief Generate timeout delay from milliseconds.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait up to @a ms milliseconds to perform the requested operation.
##
##  @param ms Duration in milliseconds.
##
##  @return Timeout delay value.
##
proc K_MSEC*(ms: int): k_timeout_t  {.importc: "K_MSEC", header: "kernel.h".}


## *
##  @brief Generate timeout delay from seconds.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait up to @a s seconds to perform the requested operation.
##
##  @param s Duration in seconds.
##
##  @return Timeout delay value.
##
proc K_SECONDS*(s: int): k_timeout_t {.importc: "K_SECONDS", header: "kernel.h".}


## *
##  @brief Generate timeout delay from minutes.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait up to @a m minutes to perform the requested operation.
##
##  @param m Duration in minutes.
##
##  @return Timeout delay value.
##
proc K_MINUTES*(m: int): k_timeout_t {.importc: "K_MINUTES", header: "kernel.h".}


## *
##  @brief Generate timeout delay from hours.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait up to @a h hours to perform the requested operation.
##
##  @param h Duration in hours.
##
##  @return Timeout delay value.
##
proc K_HOURS*(h: int): k_timeout_t {.importc: "K_HOURS", header: "kernel.h".}


## *
##  @brief Generate infinite timeout delay.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait as long as necessary to perform the requested operation.
##
##  @return Timeout delay value.
##
var K_FOREVER* {.importc: "K_FOREVER", header: "kernel.h".}: int


when CONFIG_TIMEOUT_64BIT:
  ## *
  ##  @brief Generates an absolute/uptime timeout value from system ticks
  ##
  ##  This macro generates a timeout delay that represents an expiration
  ##  at the absolute uptime value specified, in system ticks.  That is, the
  ##  timeout will expire immediately after the system uptime reaches the
  ##  specified tick count.
  ##
  ##  @param t Tick uptime value
  ##  @return Timeout delay value
  ##
  proc K_TIMEOUT_ABS_TICKS*(t: int64): k_timeout_t {.importc: "K_TIMEOUT_ABS_TICKS",
      header: "kernel.h".}


  ## *
  ##  @brief Generates an absolute/uptime timeout value from milliseconds
  ##
  ##  This macro generates a timeout delay that represents an expiration
  ##  at the absolute uptime value specified, in milliseconds.  That is,
  ##  the timeout will expire immediately after the system uptime reaches
  ##  the specified tick count.
  ##
  ##  @param t Millisecond uptime value
  ##  @return Timeout delay value
  ##
  proc K_TIMEOUT_ABS_MS*(t: uint64) {.importc: "K_TIMEOUT_ABS_MS",
                                    header: "kernel.h".}




  ## *
  ##  @brief Generates an absolute/uptime timeout value from microseconds
  ##
  ##  This macro generates a timeout delay that represents an expiration
  ##  at the absolute uptime value specified, in microseconds.  That is,
  ##  the timeout will expire immediately after the system uptime reaches
  ##  the specified time.  Note that timer precision is limited by the
  ##  system tick rate and not the requested timeout value.
  ##
  ##  @param t Microsecond uptime value
  ##  @return Timeout delay value
  ##
  proc K_TIMEOUT_ABS_US*(t: uint64) {.importc: "K_TIMEOUT_ABS_US",
                                    header: "kernel.h".}




  ## *
  ##  @brief Generates an absolute/uptime timeout value from nanoseconds
  ##
  ##  This macro generates a timeout delay that represents an expiration
  ##  at the absolute uptime value specified, in nanoseconds.  That is,
  ##  the timeout will expire immediately after the system uptime reaches
  ##  the specified time.  Note that timer precision is limited by the
  ##  system tick rate and not the requested timeout value.
  ##
  ##  @param t Nanosecond uptime value
  ##  @return Timeout delay value
  ##
  proc K_TIMEOUT_ABS_NS*(t: uint64) {.importc: "K_TIMEOUT_ABS_NS",
                                    header: "kernel.h".}




  ## *
  ##  @brief Generates an absolute/uptime timeout value from system cycles
  ##
  ##  This macro generates a timeout delay that represents an expiration
  ##  at the absolute uptime value specified, in cycles.  That is, the
  ##  timeout will expire immediately after the system uptime reaches the
  ##  specified time.  Note that timer precision is limited by the system
  ##  tick rate and not the requested timeout value.
  ##
  ##  @param t Cycle uptime value
  ##  @return Timeout delay value
  ##
  proc K_TIMEOUT_ABS_CYC*(t: uint64) {.importc: "K_TIMEOUT_ABS_CYC",
                                      header: "kernel.h".}






## *
##  @}
##
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_timer_cb_t* = proc (timer: ptr k_timer) {.cdecl.}

  k_timer* {.importc: "k_timer", header: "kernel.h", bycopy.} = object
    timeout* {.importc: "timeout".}: k_priv_timeout ##
                                          ##  _timeout structure must be first here if we want to use
                                          ##  dynamic timer allocation. timeout.node is used in the double-linked
                                          ##  list of free timers
                                          ##
    ##  wait queue for the (single) thread waiting on this timer
    wait_q* {.importc: "wait_q".}: z_wait_q_t ##  runs in ISR context
    expiry_fn* {.importc: "expiry_fn".}: k_timer_cb_t ##  runs in the context of the thread that calls k_timer_stop()
    stop_fn* {.importc: "stop_fn".}: k_timer_cb_t ##  timer period
    period* {.importc: "period".}: k_timeout_t ##  timer status
    status* {.importc: "status".}: uint32 ##  user-specific data, also used to support legacy features
    user_data* {.importc: "user_data".}: pointer

proc Z_TIMER_INITIALIZER*(obj: k_timer; expiry: k_timer_cb_t; stop: k_timer_cb_t) {.
    importc: "Z_TIMER_INITIALIZER", header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @defgroup timer_apis Timer APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @typedef k_timer_expiry_t
##  @brief Timer expiry function type.
##
##  A timer's expiry function is executed by the system clock interrupt handler
##  each time the timer expires. The expiry function is optional, and is only
##  invoked if the timer has been initialized with one.
##
##  @param timer     Address of timer.
##
##  @return N/A
##
type
  k_timer_expiry_t* = proc (timer: ptr k_timer)
## *
##  @typedef k_timer_stop_t
##  @brief Timer stop function type.
##
##  A timer's stop function is executed if the timer is stopped prematurely.
##  The function runs in the context of call that stops the timer.  As
##  k_timer_stop() can be invoked from an ISR, the stop function must be
##  callable from interrupt context (isr-ok).
##
##  The stop function is optional, and is only invoked if the timer has been
##  initialized with one.
##
##  @param timer     Address of timer.
##
##  @return N/A
##
type
  k_timer_stop_t* = proc (timer: ptr k_timer)

# ## *
# ##  @brief Statically define and initialize a timer.
# ##
# ##  The timer can be accessed outside the module where it is defined using:
# ##
# ##  @code extern struct k_timer <name>; @endcode
# ##
# ##  @param name Name of the timer variable.
# ##  @param expiry_fn Function to invoke each time the timer expires.
# ##  @param stop_fn   Function to invoke if the timer is stopped while running.
# ##
# proc K_TIMER_DEFINE*(name: untyped; expiry_fn: untyped; stop_fn: untyped) {.
#     importc: "K_TIMER_DEFINE", header: "kernel.h".}


## *
##  @brief Initialize a timer.
##
##  This routine initializes a timer, prior to its first use.
##
##  @param timer     Address of timer.
##  @param expiry_fn Function to invoke each time the timer expires.
##  @param stop_fn   Function to invoke if the timer is stopped while running.
##
##  @return N/A
##
proc k_timer_init*(timer: ptr k_timer; expiry_fn: k_timer_expiry_t;
                  stop_fn: k_timer_stop_t) {.importc: "k_timer_init",
    header: "kernel.h".}




## *
##  @brief Start a timer.
##
##  This routine starts a timer, and resets its status to zero. The timer
##  begins counting down using the specified duration and period values.
##
##  Attempting to start a timer that is already running is permitted.
##  The timer's status is reset to zero and the timer begins counting down
##  using the new duration and period values.
##
##  @param timer     Address of timer.
##  @param duration  Initial timer duration.
##  @param period    Timer period.
##
##  @return N/A
##
proc k_timer_start*(timer: ptr k_timer; duration: k_timeout_t; period: k_timeout_t) {.
    zsyscall, importc: "k_timer_start", header: "kernel.h".}




## *
##  @brief Stop a timer.
##
##  This routine stops a running timer prematurely. The timer's stop function,
##  if one exists, is invoked by the caller.
##
##  Attempting to stop a timer that is not running is permitted, but has no
##  effect on the timer.
##
##  @note The stop handler has to be callable from ISRs if @a k_timer_stop is to
##  be called from ISRs.
##
##  @funcprops \isr_ok
##
##  @param timer     Address of timer.
##
##  @return N/A
##
proc k_timer_stop*(timer: ptr k_timer) {.zsyscall, importc: "k_timer_stop",
                                      header: "kernel.h".}




## *
##  @brief Read timer status.
##
##  This routine reads the timer's status, which indicates the number of times
##  it has expired since its status was last read.
##
##  Calling this routine resets the timer's status to zero.
##
##  @param timer     Address of timer.
##
##  @return Timer status.
##
proc k_timer_status_get*(timer: ptr k_timer): uint32 {.zsyscall,
    importc: "k_timer_status_get", header: "kernel.h".}




## *
##  @brief Synchronize thread to timer expiration.
##
##  This routine blocks the calling thread until the timer's status is non-zero
##  (indicating that it has expired at least once since it was last examined)
##  or the timer is stopped. If the timer status is already non-zero,
##  or the timer is already stopped, the caller continues without waiting.
##
##  Calling this routine resets the timer's status to zero.
##
##  This routine must not be used by interrupt handlers, since they are not
##  allowed to block.
##
##  @param timer     Address of timer.
##
##  @return Timer status.
##
proc k_timer_status_sync*(timer: ptr k_timer): uint32 {.zsyscall,
    importc: "k_timer_status_sync", header: "kernel.h".}
when CONFIG_SYS_CLOCK_EXISTS:
  ## *
  ##  @brief Get next expiration time of a timer, in system ticks
  ##
  ##  This routine returns the future system uptime reached at the next
  ##  time of expiration of the timer, in units of system ticks.  If the
  ##  timer is not running, current system time is returned.
  ##
  ##  @param timer The timer object
  ##  @return Uptime of expiration, in ticks
  ##
  proc k_timer_expires_ticks*(timer: ptr k_timer): k_ticks_t {.zsyscall,
      importc: "k_timer_expires_ticks", header: "kernel.h".}

  ## *
  ##  @brief Get time remaining before a timer next expires, in system ticks
  ##
  ##  This routine computes the time remaining before a running timer
  ##  next expires, in units of system ticks.  If the timer is not
  ##  running, it returns zero.
  ##
  proc k_timer_remaining_ticks*(timer: ptr k_timer): k_ticks_t {.zsyscall,
      importc: "k_timer_remaining_ticks", header: "kernel.h".}

  ## *
  ##  @brief Get time remaining before a timer next expires.
  ##
  ##  This routine computes the (approximate) time remaining before a running
  ##  timer next expires. If the timer is not running, it returns zero.
  ##
  ##  @param timer     Address of timer.
  ##
  ##  @return Remaining time (in milliseconds).
  ##
  proc k_timer_remaining_get*(timer: ptr k_timer): uint32 {.
      importc: "k_timer_remaining_ticks", header: "kernel.h".}

## *
##  @brief Associate user-specific data with a timer.
##
##  This routine records the @a user_data with the @a timer, to be retrieved
##  later.
##
##  It can be used e.g. in a timer handler shared across multiple subsystems to
##  retrieve data specific to the subsystem this timer is associated with.
##
##  @param timer     Address of timer.
##  @param user_data User data to associate with the timer.
##
##  @return N/A
##
proc k_timer_user_data_set*(timer: ptr k_timer; user_data: pointer) {.zsyscall,
    importc: "k_timer_user_data_set", header: "kernel.h".}




## *
##  @internal
##
proc z_impl_k_timer_user_data_set*(timer: ptr k_timer; user_data: pointer) {.
    importc: "$1", header: "kernel.h".}

## *
##  @brief Retrieve the user-specific data from a timer.
##
##  @param timer     Address of timer.
##
##  @return The user data.
##
proc k_timer_user_data_get*(timer: ptr k_timer): pointer {.zsyscall,
    importc: "k_timer_user_data_get", header: "kernel.h".}

## * @}
## *
##  @addtogroup clock_apis
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Get system uptime, in system ticks.
##
##  This routine returns the elapsed time since the system booted, in
##  ticks (c.f. @kconfig{CONFIG_SYS_CLOCK_TICKS_PER_SEC}), which is the
##  fundamental unit of resolution of kernel timekeeping.
##
##  @return Current uptime in ticks.
##
proc k_uptime_ticks*(): int64 {.zsyscall, importc: "k_uptime_ticks",
                                header: "kernel.h".}




## *
##  @brief Get system uptime.
##
##  This routine returns the elapsed time since the system booted,
##  in milliseconds.
##
##  @note
##     While this function returns time in milliseconds, it does
##     not mean it has millisecond resolution. The actual resolution depends on
##     @kconfig{CONFIG_SYS_CLOCK_TICKS_PER_SEC} config option.
##
##  @return Current uptime in milliseconds.
##
proc k_uptime_get*(): int64 {.
    importc: "k_uptime_get", header: "kernel.h".}

## *
##  @brief Get system uptime (32-bit version).
##
##  This routine returns the lower 32 bits of the system uptime in
##  milliseconds.
##
##  Because correct conversion requires full precision of the system
##  clock there is no benefit to using this over k_uptime_get() unless
##  you know the application will never run long enough for the system
##  clock to approach 2^32 ticks.  Calls to this function may involve
##  interrupt blocking and 64-bit math.
##
##  @note
##     While this function returns time in milliseconds, it does
##     not mean it has millisecond resolution. The actual resolution depends on
##     @kconfig{CONFIG_SYS_CLOCK_TICKS_PER_SEC} config option
##
##  @return The low 32 bits of the current uptime, in milliseconds.
##
proc k_uptime_get_32*(): uint32 {.
    importc: "k_uptime_get_32", header: "kernel.h".}

## *
##  @brief Get elapsed time.
##
##  This routine computes the elapsed time between the current system uptime
##  and an earlier reference time, in milliseconds.
##
##  @param reftime Pointer to a reference time, which is updated to the current
##                 uptime upon return.
##
##  @return Elapsed time.
##
proc k_uptime_delta*(reftime: ptr int64): int64 {.
    importc: "$1", header: "kernel.h".}

## *
##  @brief Read the hardware clock.
##
##  This routine returns the current time, as measured by the system's hardware
##  clock.
##
##  @return Current hardware clock up-counter (in cycles).
##
proc k_cycle_get_32*(): uint32 {.
    importc: "k_cycle_get_32", header: "kernel.h".}

## *
##  @}
##
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_queue* {.importc: "k_queue", header: "kernel.h", incompleteStruct, bycopy.} = object
    data_q* {.importc: "data_q".}: sys_sflist_t
    lock* {.importc: "lock".}: k_spinlock
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    # poll_events* {.importc: "poll_events".}: sys_dlist_t ##  _POLL_EVENT;

proc Z_QUEUE_INITIALIZER*(obj: k_queue) {.importc: "Z_QUEUE_INITIALIZER",
    header: "kernel.h".}

# proc z_queue_node_peek*(node: ptr sys_sfnode_t; needs_free: bool): pointer {.
    # importc: "z_queue_node_peek", header: "kernel.h".}



## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @defgroup queue_apis Queue APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Initialize a queue.
##
##  This routine initializes a queue object, prior to its first use.
##
##  @param queue Address of the queue.
##
##  @return N/A
##
proc k_queue_init*(queue: ptr k_queue) {.zsyscall, importc: "k_queue_init",
                                      header: "kernel.h".}




## *
##  @brief Cancel waiting on a queue.
##
##  This routine causes first thread pending on @a queue, if any, to
##  return from k_queue_get() call with NULL value (as if timeout expired).
##  If the queue is being waited on by k_poll(), it will return with
##  -EINTR and K_POLL_STATE_CANCELLED state (and per above, subsequent
##  k_queue_get() will return NULL).
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##
##  @return N/A
##
proc k_queue_cancel_wait*(queue: ptr k_queue) {.zsyscall,
    importc: "k_queue_cancel_wait", header: "kernel.h".}




## *
##  @brief Append an element to the end of a queue.
##
##  This routine appends a data item to @a queue. A queue data item must be
##  aligned on a word boundary, and the first word of the item is reserved
##  for the kernel's use.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param data Address of the data item.
##
##  @return N/A
##
proc k_queue_append*(queue: ptr k_queue; data: pointer) {.importc: "k_queue_append",
    header: "kernel.h".}




## *
##  @brief Append an element to a queue.
##
##  This routine appends a data item to @a queue. There is an implicit memory
##  allocation to create an additional temporary bookkeeping data structure from
##  the calling thread's resource pool, which is automatically freed when the
##  item is removed. The data itself is not copied.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param data Address of the data item.
##
##  @retval 0 on success
##  @retval -ENOMEM if there isn't sufficient RAM in the caller's resource pool
##
proc k_queue_alloc_append*(queue: ptr k_queue; data: pointer): int32 {.zsyscall,
    importc: "k_queue_alloc_append", header: "kernel.h".}




## *
##  @brief Prepend an element to a queue.
##
##  This routine prepends a data item to @a queue. A queue data item must be
##  aligned on a word boundary, and the first word of the item is reserved
##  for the kernel's use.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param data Address of the data item.
##
##  @return N/A
##
proc k_queue_prepend*(queue: ptr k_queue; data: pointer) {.
    importc: "k_queue_prepend", header: "kernel.h".}




## *
##  @brief Prepend an element to a queue.
##
##  This routine prepends a data item to @a queue. There is an implicit memory
##  allocation to create an additional temporary bookkeeping data structure from
##  the calling thread's resource pool, which is automatically freed when the
##  item is removed. The data itself is not copied.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param data Address of the data item.
##
##  @retval 0 on success
##  @retval -ENOMEM if there isn't sufficient RAM in the caller's resource pool
##
proc k_queue_alloc_prepend*(queue: ptr k_queue; data: pointer): int32 {.zsyscall,
    importc: "k_queue_alloc_prepend", header: "kernel.h".}




## *
##  @brief Inserts an element to a queue.
##
##  This routine inserts a data item to @a queue after previous item. A queue
##  data item must be aligned on a word boundary, and the first word of
##  the item is reserved for the kernel's use.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param prev Address of the previous data item.
##  @param data Address of the data item.
##
##  @return N/A
##
proc k_queue_insert*(queue: ptr k_queue; prev: pointer; data: pointer) {.
    importc: "k_queue_insert", header: "kernel.h".}




## *
##  @brief Atomically append a list of elements to a queue.
##
##  This routine adds a list of data items to @a queue in one operation.
##  The data items must be in a singly-linked list, with the first word
##  in each data item pointing to the next data item; the list must be
##  NULL-terminated.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param head Pointer to first node in singly-linked list.
##  @param tail Pointer to last node in singly-linked list.
##
##  @retval 0 on success
##  @retval -EINVAL on invalid supplied data
##
##
proc k_queue_append_list*(queue: ptr k_queue; head: pointer; tail: pointer): cint {.
    importc: "k_queue_append_list", header: "kernel.h".}




## *
##  @brief Atomically add a list of elements to a queue.
##
##  This routine adds a list of data items to @a queue in one operation.
##  The data items must be in a singly-linked list implemented using a
##  sys_slist_t object. Upon completion, the original list is empty.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param list Pointer to sys_slist_t object.
##
##  @retval 0 on success
##  @retval -EINVAL on invalid data
##
proc k_queue_merge_slist*(queue: ptr k_queue; list: ptr sys_slist_t): cint {.
    importc: "k_queue_merge_slist", header: "kernel.h".}




## *
##  @brief Get an element from a queue.
##
##  This routine removes first data item from @a queue. The first word of the
##  data item is reserved for the kernel's use.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param timeout Non-negative waiting period to obtain a data item
##                 or one of the special values K_NO_WAIT and
##                 K_FOREVER.
##
##  @return Address of the data item if successful; NULL if returned
##  without waiting, or waiting period timed out.
##
proc k_queue_get*(queue: ptr k_queue; timeout: k_timeout_t): pointer {.zsyscall,
    importc: "k_queue_get", header: "kernel.h".}




## *
##  @brief Remove an element from a queue.
##
##  This routine removes data item from @a queue. The first word of the
##  data item is reserved for the kernel's use. Removing elements from k_queue
##  rely on sys_slist_find_and_remove which is not a constant time operation.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param data Address of the data item.
##
##  @return true if data item was removed
##
proc k_queue_remove*(queue: ptr k_queue; data: pointer): bool {.
    importc: "k_queue_remove", header: "kernel.h".}




## *
##  @brief Append an element to a queue only if it's not present already.
##
##  This routine appends data item to @a queue. The first word of the data
##  item is reserved for the kernel's use. Appending elements to k_queue
##  relies on sys_slist_is_node_in_list which is not a constant time operation.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##  @param data Address of the data item.
##
##  @return true if data item was added, false if not
##
proc k_queue_unique_append*(queue: ptr k_queue; data: pointer): bool {.
    importc: "k_queue_unique_append", header: "kernel.h".}




## *
##  @brief Query a queue to see if it has data available.
##
##  Note that the data might be already gone by the time this function returns
##  if other threads are also trying to read from the queue.
##
##  @funcprops \isr_ok
##
##  @param queue Address of the queue.
##
##  @return Non-zero if the queue is empty.
##  @return 0 if data is available.
##
proc k_queue_is_empty*(queue: ptr k_queue): cint {.zsyscall,
    importc: "k_queue_is_empty", header: "kernel.h".}


## *
##  @brief Peek element at the head of queue.
##
##  Return element from the head of queue without removing it.
##
##  @param queue Address of the queue.
##
##  @return Head element, or NULL if queue is empty.
##
proc k_queue_peek_head*(queue: ptr k_queue): pointer {.zsyscall,
    importc: "k_queue_peek_head", header: "kernel.h".}




## *
##  @brief Peek element at the tail of queue.
##
##  Return element from the tail of queue without removing it.
##
##  @param queue Address of the queue.
##
##  @return Tail element, or NULL if queue is empty.
##
proc k_queue_peek_tail*(queue: ptr k_queue): pointer {.zsyscall,
    importc: "k_queue_peek_tail", header: "kernel.h".}




## *
##  @brief Statically define and initialize a queue.
##
##  The queue can be accessed outside the module where it is defined using:
##
##  @code extern struct k_queue <name>; @endcode
##
##  @param name Name of the queue.
##
proc K_QUEUE_DEFINE*(name: cminvtoken) {.importc: "K_QUEUE_DEFINE", header: "kernel.h".}




## * @}
when CONFIG_USERSPACE:
  ## *
  ##  @brief futex structure
  ##
  ##  A k_futex is a lightweight mutual exclusion primitive designed
  ##  to minimize kernel involvement. Uncontended operation relies
  ##  only on atomic access to shared memory. k_futex are tracked as
  ##  kernel objects and can live in user memory so that any access
  ##  bypasses the kernel object permission management mechanism.
  ##
  type
    k_futex* {.importc: "k_futex", header: "kernel.h", bycopy.} = object
      val* {.importc: "val".}: atomic_t

  ## *
  ##  @brief futex kernel data structure
  ##
  ##  z_futex_data are the helper data structure for k_futex to complete
  ##  futex contended operation on kernel side, structure z_futex_data
  ##  of every futex object is invisible in user mode.
  ##
  type
    z_futex_data* {.importc: "z_futex_data", header: "kernel.h", bycopy.} = object
      wait_q* {.importc: "wait_q".}: z_wait_q_t
      lock* {.importc: "lock".}: k_spinlock

  proc Z_FUTEX_DATA_INITIALIZER*(obj: z_futex_data) {.
      importc: "Z_FUTEX_DATA_INITIALIZER", header: "kernel.h".}




  ## *
  ##  @defgroup futex_apis FUTEX APIs
  ##  @ingroup kernel_apis
  ##  @{
  ##
  ## *
  ##  @brief Pend the current thread on a futex
  ##
  ##  Tests that the supplied futex contains the expected value, and if so,
  ##  goes to sleep until some other thread calls k_futex_wake() on it.
  ##
  ##  @param futex Address of the futex.
  ##  @param expected Expected value of the futex, if it is different the caller
  ## 		   will not wait on it.
  ##  @param timeout Non-negative waiting period on the futex, or
  ## 		  one of the special values K_NO_WAIT or K_FOREVER.
  ##  @retval -EACCES Caller does not have read access to futex address.
  ##  @retval -EAGAIN If the futex value did not match the expected parameter.
  ##  @retval -EINVAL Futex parameter address not recognized by the kernel.
  ##  @retval -ETIMEDOUT Thread woke up due to timeout and not a futex wakeup.
  ##  @retval 0 if the caller went to sleep and was woken up. The caller
  ## 	     should check the futex's value on wakeup to determine if it needs
  ## 	     to block again.
  ##
  proc k_futex_wait*(futex: ptr k_futex; expected: cint; timeout: k_timeout_t): cint {.
      zsyscall, importc: "k_futex_wait", header: "kernel.h".}




  ## *
  ##  @brief Wake one/all threads pending on a futex
  ##
  ##  Wake up the highest priority thread pending on the supplied futex, or
  ##  wakeup all the threads pending on the supplied futex, and the behavior
  ##  depends on wake_all.
  ##
  ##  @param futex Futex to wake up pending threads.
  ##  @param wake_all If true, wake up all pending threads; If false,
  ##                  wakeup the highest priority thread.
  ##  @retval -EACCES Caller does not have access to the futex address.
  ##  @retval -EINVAL Futex parameter address not recognized by the kernel.
  ##  @retval Number of threads that were woken up.
  ##
  proc k_futex_wake*(futex: ptr k_futex; wake_all: bool): cint {.zsyscall,
      importc: "k_futex_wake", header: "kernel.h".}




  ## * @}
type
  k_fifo* {.importc: "k_fifo", header: "kernel.h", bycopy.} = object
    z_queue* {.importc: "_queue".}: k_queue

## *
##  @cond INTERNAL_HIDDEN
##
proc Z_FIFO_INITIALIZER*(obj: k_fifo) {.importc: "Z_FIFO_INITIALIZER",
                                      header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @defgroup fifo_apis FIFO APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Initialize a FIFO queue.
##
##  This routine initializes a FIFO queue, prior to its first use.
##
##  @param fifo Address of the FIFO queue.
##
##  @return N/A
##
proc k_fifo_init*(fifo: k_fifo) {.importc: "k_fifo_init", header: "kernel.h".}


## *
##  @brief Cancel waiting on a FIFO queue.
##
##  This routine causes first thread pending on @a fifo, if any, to
##  return from k_fifo_get() call with NULL value (as if timeout
##  expired).
##
##  @funcprops \isr_ok
##
##  @param fifo Address of the FIFO queue.
##
##  @return N/A
##
proc k_fifo_cancel_wait*(fifo: k_fifo) {.importc: "k_fifo_cancel_wait",
    header: "kernel.h".}


## *
##  @brief Add an element to a FIFO queue.
##
##  This routine adds a data item to @a fifo. A FIFO data item must be
##  aligned on a word boundary, and the first word of the item is reserved
##  for the kernel's use.
##
##  @funcprops \isr_ok
##
##  @param fifo Address of the FIFO.
##  @param data Address of the data item.
##
##  @return N/A
##
proc k_fifo_put*(fifo: k_fifo; data: pointer) {.importc: "k_fifo_put",
    header: "kernel.h".}


## *
##  @brief Add an element to a FIFO queue.
##
##  This routine adds a data item to @a fifo. There is an implicit memory
##  allocation to create an additional temporary bookkeeping data structure from
##  the calling thread's resource pool, which is automatically freed when the
##  item is removed. The data itself is not copied.
##
##  @funcprops \isr_ok
##
##  @param fifo Address of the FIFO.
##  @param data Address of the data item.
##
##  @retval 0 on success
##  @retval -ENOMEM if there isn't sufficient RAM in the caller's resource pool
##
proc k_fifo_alloc_put*(fifo: k_fifo; data: pointer) {.importc: "k_fifo_alloc_put",
    header: "kernel.h".}


## *
##  @brief Atomically add a list of elements to a FIFO.
##
##  This routine adds a list of data items to @a fifo in one operation.
##  The data items must be in a singly-linked list, with the first word of
##  each data item pointing to the next data item; the list must be
##  NULL-terminated.
##
##  @funcprops \isr_ok
##
##  @param fifo Address of the FIFO queue.
##  @param head Pointer to first node in singly-linked list.
##  @param tail Pointer to last node in singly-linked list.
##
##  @return N/A
##
proc k_fifo_put_list*(fifo: k_fifo; head: ptr sys_slist_t; tail: ptr sys_slist_t) {.
    importc: "k_fifo_put_list", header: "kernel.h".}


## *
##  @brief Atomically add a list of elements to a FIFO queue.
##
##  This routine adds a list of data items to @a fifo in one operation.
##  The data items must be in a singly-linked list implemented using a
##  sys_slist_t object. Upon completion, the sys_slist_t object is invalid
##  and must be re-initialized via sys_slist_init().
##
##  @funcprops \isr_ok
##
##  @param fifo Address of the FIFO queue.
##  @param list Pointer to sys_slist_t object.
##
##  @return N/A
##
proc k_fifo_put_slist*(fifo: k_fifo; list: ptr sys_slist_t) {.importc: "k_fifo_put_slist",
    header: "kernel.h".}


## *
##  @brief Get an element from a FIFO queue.
##
##  This routine removes a data item from @a fifo in a "first in, first out"
##  manner. The first word of the data item is reserved for the kernel's use.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##
##  @funcprops \isr_ok
##
##  @param fifo Address of the FIFO queue.
##  @param timeout Waiting period to obtain a data item,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @return Address of the data item if successful; NULL if returned
##  without waiting, or waiting period timed out.
##
proc k_fifo_get*(fifo: k_fifo; timeout: k_timeout_t) {.importc: "k_fifo_get",
    header: "kernel.h".}


## *
##  @brief Query a FIFO queue to see if it has data available.
##
##  Note that the data might be already gone by the time this function returns
##  if other threads is also trying to read from the FIFO.
##
##  @funcprops \isr_ok
##
##  @param fifo Address of the FIFO queue.
##
##  @return Non-zero if the FIFO queue is empty.
##  @return 0 if data is available.
##
proc k_fifo_is_empty*(fifo: k_fifo) {.importc: "k_fifo_is_empty",
                                    header: "kernel.h".}


## *
##  @brief Peek element at the head of a FIFO queue.
##
##  Return element from the head of FIFO queue without removing it. A usecase
##  for this is if elements of the FIFO object are themselves containers. Then
##  on each iteration of processing, a head container will be peeked,
##  and some data processed out of it, and only if the container is empty,
##  it will be completely remove from the FIFO queue.
##
##  @param fifo Address of the FIFO queue.
##
##  @return Head element, or NULL if the FIFO queue is empty.
##
proc k_fifo_peek_head*(fifo: k_fifo) {.importc: "k_fifo_peek_head",
                                      header: "kernel.h".}


## *
##  @brief Peek element at the tail of FIFO queue.
##
##  Return element from the tail of FIFO queue (without removing it). A usecase
##  for this is if elements of the FIFO queue are themselves containers. Then
##  it may be useful to add more data to the last container in a FIFO queue.
##
##  @param fifo Address of the FIFO queue.
##
##  @return Tail element, or NULL if a FIFO queue is empty.
##
proc k_fifo_peek_tail*(fifo: k_fifo) {.importc: "k_fifo_peek_tail",
                                      header: "kernel.h".}


## *
##  @brief Statically define and initialize a FIFO queue.
##
##  The FIFO queue can be accessed outside the module where it is defined using:
##
##  @code extern struct k_fifo <name>; @endcode
##
##  @param name Name of the FIFO queue.
##
proc K_FIFO_DEFINE*(name: k_fifo) {.importc: "K_FIFO_DEFINE", header: "kernel.h".}


## * @}
type
  k_lifo* {.importc: "k_lifo", header: "kernel.h", bycopy.} = object
    z_queue* {.importc: "_queue".}: k_queue


## *
##  @defgroup lifo_apis LIFO APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Initialize a LIFO queue.
##
##  This routine initializes a LIFO queue object, prior to its first use.
##
##  @param lifo Address of the LIFO queue.
##
##  @return N/A
##
proc k_lifo_init*(lifo: k_lifo) {.importc: "k_lifo_init", header: "kernel.h".}


## *
##  @brief Add an element to a LIFO queue.
##
##  This routine adds a data item to @a lifo. A LIFO queue data item must be
##  aligned on a word boundary, and the first word of the item is
##  reserved for the kernel's use.
##
##  @funcprops \isr_ok
##
##  @param lifo Address of the LIFO queue.
##  @param data Address of the data item.
##
##  @return N/A
##
proc k_lifo_put*(lifo: k_lifo; data: pointer) {.importc: "k_lifo_put",
    header: "kernel.h".}


## *
##  @brief Add an element to a LIFO queue.
##
##  This routine adds a data item to @a lifo. There is an implicit memory
##  allocation to create an additional temporary bookkeeping data structure from
##  the calling thread's resource pool, which is automatically freed when the
##  item is removed. The data itself is not copied.
##
##  @funcprops \isr_ok
##
##  @param lifo Address of the LIFO.
##  @param data Address of the data item.
##
##  @retval 0 on success
##  @retval -ENOMEM if there isn't sufficient RAM in the caller's resource pool
##
proc k_lifo_alloc_put*(lifo: k_lifo; data: pointer) {.importc: "k_lifo_alloc_put",
    header: "kernel.h".}


## *
##  @brief Get an element from a LIFO queue.
##
##  This routine removes a data item from @a LIFO in a "last in, first out"
##  manner. The first word of the data item is reserved for the kernel's use.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##
##  @funcprops \isr_ok
##
##  @param lifo Address of the LIFO queue.
##  @param timeout Waiting period to obtain a data item,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @return Address of the data item if successful; NULL if returned
##  without waiting, or waiting period timed out.
##
proc k_lifo_get*(lifo: k_lifo; timeout: k_timeout_t) {.importc: "k_lifo_get",
    header: "kernel.h".}


## *
##  @brief Statically define and initialize a LIFO queue.
##
##  The LIFO queue can be accessed outside the module where it is defined using:
##
##  @code extern struct k_lifo <name>; @endcode
##
##  @param name Name of the fifo.
##
proc K_LIFO_DEFINE*(name: cminvtoken) {.importc: "K_LIFO_DEFINE", header: "kernel.h".}


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


## * @}
## *
##  @cond INTERNAL_HIDDEN
##
# var k_sys_work_q* {.importc: "k_sys_work_q", header: "kernel.h".}: k_work_q

## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @defgroup mutex_apis Mutex APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  Mutex Structure
##  @ingroup mutex_apis
##
type
  k_mutex* {.importc: "k_mutex", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: z_wait_q_t ## * Mutex wait queue
    ## * Mutex owner
    owner* {.importc: "owner".}: ptr k_thread ## * Current lock count
    lock_count* {.importc: "lock_count".}: uint32 ## * Original thread priority
    owner_orig_prio* {.importc: "owner_orig_prio".}: cint

## *
##  @cond INTERNAL_HIDDEN
##
# proc Z_MUTEX_INITIALIZER*(obj: untyped) {.importc: "Z_MUTEX_INITIALIZER",
    # header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @brief Statically define and initialize a mutex.
##
##  The mutex can be accessed outside the module where it is defined using:
##
##  @code extern struct k_mutex <name>; @endcode
##
##  @param name Name of the mutex.
##
proc K_MUTEX_DEFINE*(name: cminvtoken) {.importc: "K_MUTEX_DEFINE", header: "kernel.h".}


## *
##  @brief Initialize a mutex.
##
##  This routine initializes a mutex object, prior to its first use.
##
##  Upon completion, the mutex is available and does not have an owner.
##
##  @param mutex Address of the mutex.
##
##  @retval 0 Mutex object created
##
##
proc k_mutex_init*(mutex: ptr k_mutex): cint {.zsyscall, importc: "k_mutex_init",
    header: "kernel.h".}


## *
##  @brief Lock a mutex.
##
##  This routine locks @a mutex. If the mutex is locked by another thread,
##  the calling thread waits until the mutex becomes available or until
##  a timeout occurs.
##
##  A thread is permitted to lock a mutex it has already locked. The operation
##  completes immediately and the lock count is increased by 1.
##
##  Mutexes may not be locked in ISRs.
##
##  @param mutex Address of the mutex.
##  @param timeout Waiting period to lock the mutex,
##                 or one of the special values K_NO_WAIT and
##                 K_FOREVER.
##
##  @retval 0 Mutex locked.
##  @retval -EBUSY Returned without waiting.
##  @retval -EAGAIN Waiting period timed out.
##
proc k_mutex_lock*(mutex: ptr k_mutex; timeout: k_timeout_t): cint {.zsyscall,
    importc: "k_mutex_lock", header: "kernel.h".}


## *
##  @brief Unlock a mutex.
##
##  This routine unlocks @a mutex. The mutex must already be locked by the
##  calling thread.
##
##  The mutex cannot be claimed by another thread until it has been unlocked by
##  the calling thread as many times as it was previously locked by that
##  thread.
##
##  Mutexes may not be unlocked in ISRs, as mutexes must only be manipulated
##  in thread context due to ownership and priority inheritance semantics.
##
##  @param mutex Address of the mutex.
##
##  @retval 0 Mutex unlocked.
##  @retval -EPERM The current thread does not own the mutex
##  @retval -EINVAL The mutex is not locked
##
##
proc k_mutex_unlock*(mutex: ptr k_mutex): cint {.zsyscall, importc: "k_mutex_unlock",
    header: "kernel.h".}


## *
##  @}
##


type
  k_condvar* {.importc: "k_condvar", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: z_wait_q_t

proc Z_CONDVAR_INITIALIZER*(obj: k_condvar) {.importc: "Z_CONDVAR_INITIALIZER",
    header: "kernel.h".}

## *
##  @defgroup condvar_apis Condition Variables APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Initialize a condition variable
##
##  @param condvar pointer to a @p k_condvar structure
##  @retval 0 Condition variable created successfully
##
proc k_condvar_init*(condvar: ptr k_condvar): cint {.zsyscall,
    importc: "k_condvar_init", header: "kernel.h".}


## *
##  @brief Signals one thread that is pending on the condition variable
##
##  @param condvar pointer to a @p k_condvar structure
##  @retval 0 On success
##
proc k_condvar_signal*(condvar: ptr k_condvar): cint {.zsyscall,
    importc: "k_condvar_signal", header: "kernel.h".}


## *
##  @brief Unblock all threads that are pending on the condition
##  variable
##
##  @param condvar pointer to a @p k_condvar structure
##  @return An integer with number of woken threads on success
##
proc k_condvar_broadcast*(condvar: ptr k_condvar): cint {.zsyscall,
    importc: "k_condvar_broadcast", header: "kernel.h".}


## *
##  @brief Waits on the condition variable releasing the mutex lock
##
##  Automically releases the currently owned mutex, blocks the current thread
##  waiting on the condition variable specified by @a condvar,
##  and finally acquires the mutex again.
##
##  The waiting thread unblocks only after another thread calls
##  k_condvar_signal, or k_condvar_broadcast with the same condition variable.
##
##  @param condvar pointer to a @p k_condvar structure
##  @param mutex Address of the mutex.
##  @param timeout Waiting period for the condition variable
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##  @retval 0 On success
##  @retval -EAGAIN Waiting period timed out.
##
proc k_condvar_wait*(condvar: ptr k_condvar; mutex: ptr k_mutex; timeout: k_timeout_t): cint {.
    zsyscall, importc: "k_condvar_wait", header: "kernel.h".}


## *
##  @brief Statically define and initialize a condition variable.
##
##  The condition variable can be accessed outside the module where it is
##  defined using:
##
##  @code extern struct k_condvar <name>; @endcode
##
##  @param name Name of the condition variable.
##
proc K_CONDVAR_DEFINE*(name: cminvtoken) {.importc: "K_CONDVAR_DEFINE",
                                      header: "kernel.h".}


## *
##  @}
##
## *
##  @cond INTERNAL_HIDDEN
##

proc Z_SEM_INITIALIZER*(obj: k_sem; initial_count: static[int]; count_limit: static[int]) {.
    importc: "Z_SEM_INITIALIZER", header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *

##  @defgroup semaphore_apis Semaphore APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Maximum limit value allowed for a semaphore.
##
##  This is intended for use when a semaphore does not have
##  an explicit maximum limit, and instead is just used for
##  counting purposes.
##
##
var K_SEM_MAX_LIMIT* {.importc: "K_SEM_MAX_LIMIT", header: "kernel.h".}: int
## *
##  @brief Initialize a semaphore.
##
##  This routine initializes a semaphore object, prior to its first use.
##
##  @param sem Address of the semaphore.
##  @param initial_count Initial semaphore count.
##  @param limit Maximum permitted semaphore count.
##
##  @see K_SEM_MAX_LIMIT
##
##  @retval 0 Semaphore created successfully
##  @retval -EINVAL Invalid values
##
##
proc k_sem_init*(sem: ptr k_sem; initial_count: cuint; limit: cuint): cint {.zsyscall,
    importc: "k_sem_init", header: "kernel.h".}


## *
##  @brief Take a semaphore.
##
##  This routine takes @a sem.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##
##  @funcprops \isr_ok
##
##  @param sem Address of the semaphore.
##  @param timeout Waiting period to take the semaphore,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @retval 0 Semaphore taken.
##  @retval -EBUSY Returned without waiting.
##  @retval -EAGAIN Waiting period timed out,
## 			or the semaphore was reset during the waiting period.
##
proc k_sem_take*(sem: ptr k_sem; timeout: k_timeout_t): cint {.zsyscall,
    importc: "k_sem_take", header: "kernel.h".}


## *
##  @brief Give a semaphore.
##
##  This routine gives @a sem, unless the semaphore is already at its maximum
##  permitted count.
##
##  @funcprops \isr_ok
##
##  @param sem Address of the semaphore.
##
##  @return N/A
##
proc k_sem_give*(sem: ptr k_sem) {.zsyscall, importc: "k_sem_give", header: "kernel.h".}


## *
##  @brief Resets a semaphore's count to zero.
##
##  This routine sets the count of @a sem to zero.
##  Any outstanding semaphore takes will be aborted
##  with -EAGAIN.
##
##  @param sem Address of the semaphore.
##
##  @return N/A
##
proc k_sem_reset*(sem: ptr k_sem) {.zsyscall, importc: "k_sem_reset",
                                header: "kernel.h".}


## *
##  @brief Get a semaphore's count.
##
##  This routine returns the current count of @a sem.
##
##  @param sem Address of the semaphore.
##
##  @return Current semaphore count.
##
proc k_sem_count_get*(sem: ptr k_sem): cuint {.zsyscall, importc: "k_sem_count_get",
    header: "kernel.h".}


## *
##  @internal
##
proc z_impl_k_sem_count_get*(sem: ptr k_sem): cuint {.
    importc: "$1", header: "kernel.h".}

## *
##  @brief Statically define and initialize a semaphore.
##
##  The semaphore can be accessed outside the module where it is defined using:
##
##  @code extern struct k_sem <name>; @endcode
##
##  @param name Name of the semaphore.
##  @param initial_count Initial semaphore count.
##  @param count_limit Maximum permitted semaphore count.
##
proc K_SEM_DEFINE*(name: cminvtoken; initial_count: static[int]; count_limit: static[int]) {.
    importc: "K_SEM_DEFINE", header: "kernel.h".}


## * @}

## *
##  @cond INTERNAL_HIDDEN
##

## * @}



## * @}
## *


## * @}
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_mem_slab* {.importc: "k_mem_slab", header: "kernel.h", incompleteStruct, bycopy.} = object
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    lock* {.importc: "lock".}: k_spinlock
    num_blocks* {.importc: "num_blocks".}: uint32
    block_size* {.importc: "block_size".}: csize_t
    buffer* {.importc: "buffer".}: cstring
    free_list* {.importc: "free_list".}: cstring
    num_used* {.importc: "num_used".}: uint32
    when CONFIG_MEM_SLAB_TRACE_MAX_UTILIZATION:
      max_used* {.importc: "max_used".}: uint32

# proc Z_MEM_SLAB_INITIALIZER*(obj: untyped; slab_buffer: untyped;
                            # slab_block_size: untyped; slab_num_blocks: untyped) {.
    # importc: "Z_MEM_SLAB_INITIALIZER", header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @defgroup mem_slab_apis Memory Slab APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Statically define and initialize a memory slab.
##
##  The memory slab's buffer contains @a slab_num_blocks memory blocks
##  that are @a slab_block_size bytes long. The buffer is aligned to a
##  @a slab_align -byte boundary. To ensure that each memory block is similarly
##  aligned to this boundary, @a slab_block_size must also be a multiple of
##  @a slab_align.
##
##  The memory slab can be accessed outside the module where it is defined
##  using:
##
##  @code extern struct k_mem_slab <name>; @endcode
##
##  @param name Name of the memory slab.
##  @param slab_block_size Size of each memory block (in bytes).
##  @param slab_num_blocks Number memory blocks.
##  @param slab_align Alignment of the memory slab's buffer (power of 2).
##
# proc K_MEM_SLAB_DEFINE*(name: cminvtoken; slab_block_size: untyped;
                        # slab_num_blocks: untyped; slab_align: untyped) {.
    # importc: "K_MEM_SLAB_DEFINE", header: "kernel.h".}


## *
##  @brief Initialize a memory slab.
##
##  Initializes a memory slab, prior to its first use.
##
##  The memory slab's buffer contains @a slab_num_blocks memory blocks
##  that are @a slab_block_size bytes long. The buffer must be aligned to an
##  N-byte boundary matching a word boundary, where N is a power of 2
##  (i.e. 4 on 32-bit systems, 8, 16, ...).
##  To ensure that each memory block is similarly aligned to this boundary,
##  @a slab_block_size must also be a multiple of N.
##
##  @param slab Address of the memory slab.
##  @param buffer Pointer to buffer used for the memory blocks.
##  @param block_size Size of each memory block (in bytes).
##  @param num_blocks Number of memory blocks.
##
##  @retval 0 on success
##  @retval -EINVAL invalid data supplied
##
##
proc k_mem_slab_init*(slab: ptr k_mem_slab; buffer: pointer; block_size: csize_t;
                      num_blocks: uint32): cint {.importc: "k_mem_slab_init",
    header: "kernel.h".}


## *
##  @brief Allocate memory from a memory slab.
##
##  This routine allocates a memory block from a memory slab.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##  @note When CONFIG_MULTITHREADING=n any @a timeout is treated as K_NO_WAIT.
##
##  @funcprops \isr_ok
##
##  @param slab Address of the memory slab.
##  @param mem Pointer to block address area.
##  @param timeout Non-negative waiting period to wait for operation to complete.
##         Use K_NO_WAIT to return without waiting,
##         or K_FOREVER to wait as long as necessary.
##
##  @retval 0 Memory allocated. The block address area pointed at by @a mem
##          is set to the starting address of the memory block.
##  @retval -ENOMEM Returned without waiting.
##  @retval -EAGAIN Waiting period timed out.
##  @retval -EINVAL Invalid data supplied
##
proc k_mem_slab_alloc*(slab: ptr k_mem_slab; mem: ptr pointer; timeout: k_timeout_t): cint {.
    importc: "k_mem_slab_alloc", header: "kernel.h".}


## *
##  @brief Free memory allocated from a memory slab.
##
##  This routine releases a previously allocated memory block back to its
##  associated memory slab.
##
##  @param slab Address of the memory slab.
##  @param mem Pointer to block address area (as set by k_mem_slab_alloc()).
##
##  @return N/A
##
proc k_mem_slab_free*(slab: ptr k_mem_slab; mem: ptr pointer) {.
    importc: "k_mem_slab_free", header: "kernel.h".}


## *
##  @brief Get the number of used blocks in a memory slab.
##
##  This routine gets the number of memory blocks that are currently
##  allocated in @a slab.
##
##  @param slab Address of the memory slab.
##
##  @return Number of allocated memory blocks.
##
proc k_mem_slab_num_used_get*(slab: ptr k_mem_slab): uint32 {.
    importc: "$1", header: "kernel.h".}

## *
##  @brief Get the number of maximum used blocks so far in a memory slab.
##
##  This routine gets the maximum number of memory blocks that were
##  allocated in @a slab.
##
##  @param slab Address of the memory slab.
##
##  @return Maximum number of allocated memory blocks.
##
proc k_mem_slab_max_used_get*(slab: ptr k_mem_slab): uint32 {.
    importc: "$1", header: "kernel.h".}

## *
##  @brief Get the number of unused blocks in a memory slab.
##
##  This routine gets the number of memory blocks that are currently
##  unallocated in @a slab.
##
##  @param slab Address of the memory slab.
##
##  @return Number of unallocated memory blocks.
##
proc k_mem_slab_num_free_get*(slab: ptr k_mem_slab): uint32 {.
    importc: "$1", header: "kernel.h".}

## * @}
## *
##  @addtogroup heap_apis
##  @{
##

## *
##  @brief Initialize a k_heap
##
##  This constructs a synchronized k_heap object over a memory region
##  specified by the user.  Note that while any alignment and size can
##  be passed as valid parameters, internal alignment restrictions
##  inside the inner sys_heap mean that not all bytes may be usable as
##  allocated memory.
##
##  @param h Heap struct to initialize
##  @param mem Pointer to memory.
##  @param bytes Size of memory region, in bytes
##
proc k_heap_init*(h: ptr k_heap; mem: pointer; bytes: csize_t) {.
    importc: "k_heap_init", header: "kernel.h".}


## * @brief Allocate aligned memory from a k_heap
##
##  Behaves in all ways like k_heap_alloc(), except that the returned
##  memory (if available) will have a starting address in memory which
##  is a multiple of the specified power-of-two alignment value in
##  bytes.  The resulting memory can be returned to the heap using
##  k_heap_free().
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##  @note When CONFIG_MULTITHREADING=n any @a timeout is treated as K_NO_WAIT.
##
##  @funcprops \isr_ok
##
##  @param h Heap from which to allocate
##  @param align Alignment in bytes, must be a power of two
##  @param bytes Number of bytes requested
##  @param timeout How long to wait, or K_NO_WAIT
##  @return Pointer to memory the caller can now use
##
proc k_heap_aligned_alloc*(h: ptr k_heap; align: csize_t; bytes: csize_t;
                          timeout: k_timeout_t): pointer {.
    importc: "k_heap_aligned_alloc", header: "kernel.h".}


## *
##  @brief Allocate memory from a k_heap
##
##  Allocates and returns a memory buffer from the memory region owned
##  by the heap.  If no memory is available immediately, the call will
##  block for the specified timeout (constructed via the standard
##  timeout API, or K_NO_WAIT or K_FOREVER) waiting for memory to be
##  freed.  If the allocation cannot be performed by the expiration of
##  the timeout, NULL will be returned.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##  @note When CONFIG_MULTITHREADING=n any @a timeout is treated as K_NO_WAIT.
##
##  @funcprops \isr_ok
##
##  @param h Heap from which to allocate
##  @param bytes Desired size of block to allocate
##  @param timeout How long to wait, or K_NO_WAIT
##  @return A pointer to valid heap memory, or NULL
##
proc k_heap_alloc*(h: ptr k_heap; bytes: csize_t; timeout: k_timeout_t): pointer {.
    importc: "k_heap_alloc", header: "kernel.h".}


## *
##  @brief Free memory allocated by k_heap_alloc()
##
##  Returns the specified memory block, which must have been returned
##  from k_heap_alloc(), to the heap for use by other callers.  Passing
##  a NULL block is legal, and has no effect.
##
##  @param h Heap to which to return the memory
##  @param mem A valid memory block, or NULL
##
proc k_heap_free*(h: ptr k_heap; mem: pointer) {.importc: "k_heap_free",
    header: "kernel.h".}
##  Hand-calculated minimum heap sizes needed to return a successful
##  1-byte allocation.  See details in lib/os/heap.[ch]
##
var Z_HEAP_MIN_SIZE* {.importc: "Z_HEAP_MIN_SIZE", header: "kernel.h".}: int
## *
##  @brief Define a static k_heap in the specified linker section
##
##  This macro defines and initializes a static memory region and
##  k_heap of the requested size in the specified linker section.
##  After kernel start, &name can be used as if k_heap_init() had
##  been called.
##
##  Note that this macro enforces a minimum size on the memory region
##  to accommodate metadata requirements.  Very small heaps will be
##  padded to fit.
##
##  @param name Symbol name for the struct k_heap object
##  @param bytes Size of memory region, in bytes
##  @param in_section __attribute__((section(name))
##
# proc Z_HEAP_DEFINE_IN_SECT*(name: cminvtoken; bytes: static[int]; in_section: cminvtoken) {.
    # importc: "Z_HEAP_DEFINE_IN_SECT", header: "kernel.h".}


## *
##  @brief Define a static k_heap
##
##  This macro defines and initializes a static memory region and
##  k_heap of the requested size.  After kernel start, &name can be
##  used as if k_heap_init() had been called.
##
##  Note that this macro enforces a minimum size on the memory region
##  to accommodate metadata requirements.  Very small heaps will be
##  padded to fit.
##
##  @param name Symbol name for the struct k_heap object
##  @param bytes Size of memory region, in bytes
##
proc K_HEAP_DEFINE*(name: cminvtoken; bytes: static[int]) {.importc: "K_HEAP_DEFINE",
    header: "kernel.h".}


## *
##  @brief Define a static k_heap in uncached memory
##
##  This macro defines and initializes a static memory region and
##  k_heap of the requested size in uncache memory.  After kernel
##  start, &name can be used as if k_heap_init() had been called.
##
##  Note that this macro enforces a minimum size on the memory region
##  to accommodate metadata requirements.  Very small heaps will be
##  padded to fit.
##
##  @param name Symbol name for the struct k_heap object
##  @param bytes Size of memory region, in bytes
##
proc K_HEAP_DEFINE_NOCACHE*(name: cminvtoken; bytes: static[int]) {.
    importc: "K_HEAP_DEFINE_NOCACHE", header: "kernel.h".}


## *
##  @}
##
## *
##  @defgroup heap_apis Heap APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Allocate memory from the heap with a specified alignment.
##
##  This routine provides semantics similar to aligned_alloc(); memory is
##  allocated from the heap with a specified alignment. However, one minor
##  difference is that k_aligned_alloc() accepts any non-zero @p size,
##  wherase aligned_alloc() only accepts a @p size that is an integral
##  multiple of @p align.
##
##  Above, aligned_alloc() refers to:
##  C11 standard (ISO/IEC 9899:2011): 7.22.3.1
##  The aligned_alloc function (p: 347-348)
##
##  @param align Alignment of memory requested (in bytes).
##  @param size Amount of memory requested (in bytes).
##
##  @return Address of the allocated memory if successful; otherwise NULL.
##
proc k_aligned_alloc*(align: csize_t; size: csize_t): pointer {.
    importc: "k_aligned_alloc", header: "kernel.h".}


## *
##  @brief Allocate memory from the heap.
##
##  This routine provides traditional malloc() semantics. Memory is
##  allocated from the heap memory pool.
##
##  @param size Amount of memory requested (in bytes).
##
##  @return Address of the allocated memory if successful; otherwise NULL.
##
proc k_malloc*(size: csize_t): pointer {.importc: "k_malloc", header: "kernel.h".}


## *
##  @brief Free memory allocated from heap.
##
##  This routine provides traditional free() semantics. The memory being
##  returned must have been allocated from the heap memory pool or
##  k_mem_pool_malloc().
##
##  If @a ptr is NULL, no operation is performed.
##
##  @param ptr Pointer to previously allocated memory.
##
##  @return N/A
##
proc k_free*(`ptr`: pointer) {.importc: "k_free", header: "kernel.h".}


## *
##  @brief Allocate memory from heap, array style
##
##  This routine provides traditional calloc() semantics. Memory is
##  allocated from the heap memory pool and zeroed.
##
##  @param nmemb Number of elements in the requested array
##  @param size Size of each array element (in bytes).
##
##  @return Address of the allocated memory if successful; otherwise NULL.
##
proc k_calloc*(nmemb: csize_t; size: csize_t): pointer {.importc: "k_calloc",
    header: "kernel.h".}



## *
##  @internal
##
proc z_handle_obj_poll_events*(events: ptr sys_dlist_t; state: uint32) {.
    importc: "z_handle_obj_poll_events", header: "kernel.h".}


## * @}
## *
##  @defgroup cpu_idle_apis CPU Idling APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Make the CPU idle.
##
##  This function makes the CPU idle until an event wakes it up.
##
##  In a regular system, the idle thread should be the only thread responsible
##  for making the CPU idle and triggering any type of power management.
##  However, in some more constrained systems, such as a single-threaded system,
##  the only thread would be responsible for this if needed.
##
##  @note In some architectures, before returning, the function unmasks interrupts
##  unconditionally.
##
##  @return N/A
##
proc k_cpu_idle*() {.importc:"k_cpu_idle", header: "kernel.h".} 

## *
##  @brief Make the CPU idle in an atomic fashion.
##
##  Similar to k_cpu_idle(), but must be called with interrupts locked.
##
##  Enabling interrupts and entering a low-power mode will be atomic,
##  i.e. there will be no period of time where interrupts are enabled before
##  the processor enters a low-power mode.
##
##  After waking up from the low-power mode, the interrupt lockout state will
##  be restored as if by irq_unlock(key).
##
##  @param key Interrupt locking key obtained from irq_lock().
##
##  @return N/A
##
proc k_cpu_atomic_idle*(key: cuint) {.importc:"k_cpu_idle", header: "kernel.h".} 

## *
##  @}
##
## *
##  @internal
##
when defined(ARCH_EXCEPT):
  ##  This architecture has direct support for triggering a CPU exception
  proc z_except_reason*(reason: untyped) {.importc: "z_except_reason",
      header: "kernel.h".}
else:
  discard """
   NOTE: This is the implementation for arches that do not implement
   ARCH_EXCEPT() to generate a real CPU exception.
  
   We won't have a real exception frame to determine the PC value when
   the oops occurred, so print file and line number before we jump into
   the fatal error handler.
  
  """

## *
##  @brief Fatally terminate a thread
##
##  This should be called when a thread has encountered an unrecoverable
##  runtime condition and needs to terminate. What this ultimately
##  means is determined by the _fatal_error_handler() implementation, which
##  will be called will reason code K_ERR_KERNEL_OOPS.
##
##  If this is called from ISR context, the default system fatal error handler
##  will treat it as an unrecoverable system error, just like k_panic().
##
## *
##  @brief Fatally terminate the system
##
##  This should be called when the Zephyr kernel has encountered an
##  unrecoverable runtime condition and needs to terminate. What this ultimately
##  means is determined by the _fatal_error_handler() implementation, which
##  will be called will reason code K_ERR_KERNEL_PANIC.
##
##
##  private APIs that are utilized by one or more public APIs
##
## *
##  @internal
##
proc z_init_thread_base*(thread_base: ptr z_thread_base; priority: cint;
                        initial_state: uint32; options: cuint) {.
    importc: "z_init_thread_base", header: "kernel.h".}

proc z_init_static_threads*() {.importc: "z_init_static_threads",
                                header: "kernel.h".}


## *
##  @internal
##
proc z_is_thread_essential*(): bool {.importc: "z_is_thread_essential",
                                    header: "kernel.h".}

when CONFIG_SMP:
  proc z_smp_thread_init*(arg: pointer; thread: ptr k_thread) {.
      importc: "z_smp_thread_init", header: "kernel.h".}
  proc z_smp_thread_swap*() {.importc: "z_smp_thread_swap", header: "kernel.h".}


## *
##  @internal
##
proc z_timer_expiration_handler*(t: ptr k_priv_timeout) {.
    importc: "z_timer_expiration_handler", header: "kernel.h".}

when CONFIG_PRINTK:
  ## *
  ##  @brief Emit a character buffer to the console device
  ##
  ##  @param c String of characters to print
  ##  @param n The length of the string
  ##
  ##
  proc k_str_out*(c: cstring; n: csize_t) {.zsyscall, importc: "k_str_out",
      header: "kernel.h".}


## *
##  @brief Disable preservation of floating point context information.
##
##  This routine informs the kernel that the specified thread
##  will no longer be using the floating point registers.
##
##  @warning
##  Some architectures apply restrictions on how the disabling of floating
##  point preservation may be requested, see arch_float_disable.
##
##  @warning
##  This routine should only be used to disable floating point support for
##  a thread that currently has such support enabled.
##
##  @param thread ID of thread.
##
##  @retval 0        On success.
##  @retval -ENOTSUP If the floating point disabling is not implemented.
##          -EINVAL  If the floating point disabling could not be performed.
##
proc k_float_disable*(thread: ptr k_thread): cint {.zsyscall,
    importc: "k_float_disable", header: "kernel.h".}


## *
##  @brief Enable preservation of floating point context information.
##
##  This routine informs the kernel that the specified thread
##  will use the floating point registers.
##
##  Invoking this routine initializes the thread's floating point context info
##  to that of an FPU that has been reset. The next time the thread is scheduled
##  by z_swap() it will either inherit an FPU that is guaranteed to be in a
##  "sane" state (if the most recent user of the FPU was cooperatively swapped
##  out) or the thread's own floating point context will be loaded (if the most
##  recent user of the FPU was preempted, or if this thread is the first user
##  of the FPU). Thereafter, the kernel will protect the thread's FP context
##  so that it is not altered during a preemptive context switch.
##
##  The @a options parameter indicates which floating point register sets will
##  be used by the specified thread.
##
##  For x86 options:
##
##  - K_FP_REGS  indicates x87 FPU and MMX registers only
##  - K_SSE_REGS indicates SSE registers (and also x87 FPU and MMX registers)
##
##  @warning
##  Some architectures apply restrictions on how the enabling of floating
##  point preservation may be requested, see arch_float_enable.
##
##  @warning
##  This routine should only be used to enable floating point support for
##  a thread that currently has such support enabled.
##
##  @param thread  ID of thread.
##  @param options architecture dependent options
##
##  @retval 0        On success.
##  @retval -ENOTSUP If the floating point enabling is not implemented.
##          -EINVAL  If the floating point enabling could not be performed.
##
proc k_float_enable*(thread: ptr k_thread; options: cuint): cint {.zsyscall,
    importc: "k_float_enable", header: "kernel.h".}

when CONFIG_THREAD_RUNTIME_STATS:
  ## *
  ##  @brief Get the runtime statistics of a thread
  ##
  ##  @param thread ID of thread.
  ##  @param stats Pointer to struct to copy statistics into.
  ##  @return -EINVAL if null pointers, otherwise 0
  ##
  proc k_thread_runtime_stats_get*(thread: k_tid_t;
                                  stats: ptr k_thread_runtime_stats_t): cint {.
      importc: "k_thread_runtime_stats_get", header: "kernel.h".}


  ## *
  ##  @brief Get the runtime statistics of all threads
  ##
  ##  @param stats Pointer to struct to copy statistics into.
  ##  @return -EINVAL if null pointers, otherwise 0
  ##
  proc k_thread_runtime_stats_all_get*(stats: ptr k_thread_runtime_stats_t): cint {.
      importc: "k_thread_runtime_stats_all_get", header: "kernel.h".}