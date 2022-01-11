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

import zthread

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


## *
##  @addtogroup thread_apis
##  @{
##
type
  k_thread_user_cb_t* = proc (thread: ptr k_thread; user_data: pointer)


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


when defined(CONFIG_FPU_SHARING):
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


when defined(CONFIG_X86):
  ##  x86 Bitmask definitions for threads user options
  when defined(CONFIG_FPU_SHARING) and defined(CONFIG_X86_SSE):
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
                      p2: pointer; p3: pointer; prio: cint; options: uint32_t;
                      delay: k_timeout_t): k_tid_t {.syscall,
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
proc k_thread_access_grant*(thread: untyped) {.varargs,
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
proc k_thread_heap_assign*(thread: ptr k_thread; heap: ptr k_heap) {.inline.} =
  thread.resource_pool = heap

when defined(CONFIG_INIT_STACKS) and defined(CONFIG_THREAD_STACK_INFO):
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
      syscall, importc: "k_thread_stack_space_get", header: "kernel.h".}
when (CONFIG_HEAP_MEM_POOL_SIZE > 0):
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
proc k_thread_join*(thread: ptr k_thread; timeout: k_timeout_t): cint {.syscall,
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
proc k_sleep*(timeout: k_timeout_t): int32_t {.syscall, importc: "k_sleep",
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
proc k_msleep*(ms: int32_t): int32_t {.inline.} =
  return k_sleep(Z_TIMEOUT_MS(ms))

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
proc k_usleep*(us: int32_t): int32_t {.syscall, importc: "k_usleep",
                                    header: "kernel.h".}
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
proc k_busy_wait*(usec_to_wait: uint32_t) {.syscall, importc: "k_busy_wait",
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
proc k_yield*() {.syscall, importc: "k_yield", header: "kernel.h".}
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
proc k_wakeup*(thread: k_tid_t) {.syscall, importc: "k_wakeup", header: "kernel.h".}
## *
##  @brief Get thread ID of the current thread.
##
##  This unconditionally queries the kernel via a system call.
##
##  @return ID of current thread.
##
proc z_current_get*(): k_tid_t {.syscall, importc: "z_current_get",
                              header: "kernel.h".}
when defined(CONFIG_THREAD_LOCAL_STORAGE):
  ##  Thread-local cache of current thread ID, set in z_thread_entry()
  var z_tls_current* {.importc: "z_tls_current", header: "kernel.h".}: k_tid_t
## *
##  @brief Get thread ID of the current thread.
##
##  @return ID of current thread.
##
##
proc k_current_get*(): k_tid_t =
  when defined(CONFIG_THREAD_LOCAL_STORAGE):
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
proc k_thread_abort*(thread: k_tid_t) {.syscall, importc: "k_thread_abort",
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
proc k_thread_start*(thread: k_tid_t) {.syscall, importc: "k_thread_start",
                                      header: "kernel.h".}
proc z_timeout_expires*(timeout: ptr _timeout): k_ticks_t {.
    importc: "z_timeout_expires", header: "kernel.h".}
proc z_timeout_remaining*(timeout: ptr _timeout): k_ticks_t {.
    importc: "z_timeout_remaining", header: "kernel.h".}
when defined(CONFIG_SYS_CLOCK_EXISTS):
  ## *
  ##  @brief Get time when a thread wakes up, in system ticks
  ##
  ##  This routine computes the system uptime when a waiting thread next
  ##  executes, in units of system ticks.  If the thread is not waiting,
  ##  it returns current system time.
  ##
  proc k_thread_timeout_expires_ticks*(t: ptr k_thread): k_ticks_t {.syscall,
      importc: "k_thread_timeout_expires_ticks", header: "kernel.h".}
  proc z_impl_k_thread_timeout_expires_ticks*(t: ptr k_thread): k_ticks_t {.inline.} =
    return z_timeout_expires(addr(t.base.timeout))

  ## *
  ##  @brief Get time remaining before a thread wakes up, in system ticks
  ##
  ##  This routine computes the time remaining before a waiting thread
  ##  next executes, in units of system ticks.  If the thread is not
  ##  waiting, it returns zero.
  ##
  proc k_thread_timeout_remaining_ticks*(t: ptr k_thread): k_ticks_t {.syscall,
      importc: "k_thread_timeout_remaining_ticks", header: "kernel.h".}
  proc z_impl_k_thread_timeout_remaining_ticks*(t: ptr k_thread): k_ticks_t {.
      inline.} =
    return z_timeout_remaining(addr(t.base.timeout))

## *
##  @cond INTERNAL_HIDDEN
##
##  timeout has timed out and is not on _timeout_q anymore
var _EXPIRED* {.importc: "_EXPIRED", header: "kernel.h".}: int
type
  _static_thread_data* {.importc: "_static_thread_data", header: "kernel.h", bycopy.} = object
    init_thread* {.importc: "init_thread".}: ptr k_thread
    init_stack* {.importc: "init_stack".}: ptr k_thread_stack_t
    init_stack_size* {.importc: "init_stack_size".}: cuint
    init_entry* {.importc: "init_entry".}: k_thread_entry_t
    init_p1* {.importc: "init_p1".}: pointer
    init_p2* {.importc: "init_p2".}: pointer
    init_p3* {.importc: "init_p3".}: pointer
    init_prio* {.importc: "init_prio".}: cint
    init_options* {.importc: "init_options".}: uint32_t
    init_delay* {.importc: "init_delay".}: int32_t
    init_abort* {.importc: "init_abort".}: proc ()
    init_name* {.importc: "init_name".}: cstring

proc Z_THREAD_INITIALIZER*(thread: untyped; stack: untyped; stack_size: untyped;
                          entry: untyped; p1: untyped; p2: untyped; p3: untyped;
                          prio: untyped; options: untyped; delay: untyped;
                          abort: untyped; tname: untyped) {.
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
proc K_THREAD_DEFINE*(name: untyped; stack_size: untyped; entry: untyped;
                      p1: untyped; p2: untyped; p3: untyped; prio: untyped;
                      options: untyped; delay: untyped) {.
    importc: "K_THREAD_DEFINE", header: "kernel.h".}
## *
##  @brief Get a thread's priority.
##
##  This routine gets the priority of @a thread.
##
##  @param thread ID of thread whose priority is needed.
##
##  @return Priority of @a thread.
##
proc k_thread_priority_get*(thread: k_tid_t): cint {.syscall,
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
proc k_thread_priority_set*(thread: k_tid_t; prio: cint) {.syscall,
    importc: "k_thread_priority_set", header: "kernel.h".}
when defined(CONFIG_SCHED_DEADLINE):
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
  proc k_thread_deadline_set*(thread: k_tid_t; deadline: cint) {.syscall,
      importc: "k_thread_deadline_set", header: "kernel.h".}
when defined(CONFIG_SCHED_CPU_MASK):
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
proc k_thread_suspend*(thread: k_tid_t) {.syscall, importc: "k_thread_suspend",
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
proc k_thread_resume*(thread: k_tid_t) {.syscall, importc: "k_thread_resume",
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
proc k_sched_time_slice_set*(slice: int32_t; prio: cint) {.
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
proc k_is_preempt_thread*(): cint {.syscall, importc: "k_is_preempt_thread",
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
proc k_is_pre_kernel*(): bool {.inline.} =
  var z_sys_post_kernel: bool
  ##  in init.c
  return not z_sys_post_kernel

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
proc k_thread_custom_data_set*(value: pointer) {.syscall,
    importc: "k_thread_custom_data_set", header: "kernel.h".}
## *
##  @brief Get current thread's custom data.
##
##  This routine returns the custom data for the current thread.
##
##  @return Current custom data value.
##
proc k_thread_custom_data_get*(): pointer {.syscall,
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
proc k_thread_name_set*(thread: k_tid_t; str: cstring): cint {.syscall,
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
    syscall, importc: "k_thread_name_copy", header: "kernel.h".}
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
var K_NO_WAIT* {.importc: "K_NO_WAIT", header: "kernel.h".}: int
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
proc K_NSEC*(t: untyped) {.importc: "K_NSEC", header: "kernel.h".}
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
proc K_USEC*(t: untyped) {.importc: "K_USEC", header: "kernel.h".}
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
proc K_CYC*(t: untyped) {.importc: "K_CYC", header: "kernel.h".}
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
proc K_TICKS*(t: untyped) {.importc: "K_TICKS", header: "kernel.h".}
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
proc K_MSEC*(ms: untyped) {.importc: "K_MSEC", header: "kernel.h".}
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
proc K_SECONDS*(s: untyped) {.importc: "K_SECONDS", header: "kernel.h".}
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
proc K_MINUTES*(m: untyped) {.importc: "K_MINUTES", header: "kernel.h".}
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
proc K_HOURS*(h: untyped) {.importc: "K_HOURS", header: "kernel.h".}
## *
##  @brief Generate infinite timeout delay.
##
##  This macro generates a timeout delay that instructs a kernel API
##  to wait as long as necessary to perform the requested operation.
##
##  @return Timeout delay value.
##
var K_FOREVER* {.importc: "K_FOREVER", header: "kernel.h".}: int
when defined(CONFIG_TIMEOUT_64BIT):
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
  proc K_TIMEOUT_ABS_TICKS*(t: untyped) {.importc: "K_TIMEOUT_ABS_TICKS",
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
  proc K_TIMEOUT_ABS_MS*(t: untyped) {.importc: "K_TIMEOUT_ABS_MS",
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
  proc K_TIMEOUT_ABS_US*(t: untyped) {.importc: "K_TIMEOUT_ABS_US",
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
  proc K_TIMEOUT_ABS_NS*(t: untyped) {.importc: "K_TIMEOUT_ABS_NS",
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
  proc K_TIMEOUT_ABS_CYC*(t: untyped) {.importc: "K_TIMEOUT_ABS_CYC",
                                      header: "kernel.h".}
## *
##  @}
##
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_timer* {.importc: "k_timer", header: "kernel.h", bycopy.} = object
    timeout* {.importc: "timeout".}: _timeout ##
                                          ##  _timeout structure must be first here if we want to use
                                          ##  dynamic timer allocation. timeout.node is used in the double-linked
                                          ##  list of free timers
                                          ##
    ##  wait queue for the (single) thread waiting on this timer
    wait_q* {.importc: "wait_q".}: _wait_q_t ##  runs in ISR context
    expiry_fn* {.importc: "expiry_fn".}: proc (timer: ptr k_timer) ##  runs in the context of the thread that calls k_timer_stop()
    stop_fn* {.importc: "stop_fn".}: proc (timer: ptr k_timer) ##  timer period
    period* {.importc: "period".}: k_timeout_t ##  timer status
    status* {.importc: "status".}: uint32_t ##  user-specific data, also used to support legacy features
    user_data* {.importc: "user_data".}: pointer

proc Z_TIMER_INITIALIZER*(obj: untyped; expiry: untyped; stop: untyped) {.
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
## *
##  @brief Statically define and initialize a timer.
##
##  The timer can be accessed outside the module where it is defined using:
##
##  @code extern struct k_timer <name>; @endcode
##
##  @param name Name of the timer variable.
##  @param expiry_fn Function to invoke each time the timer expires.
##  @param stop_fn   Function to invoke if the timer is stopped while running.
##
proc K_TIMER_DEFINE*(name: untyped; expiry_fn: untyped; stop_fn: untyped) {.
    importc: "K_TIMER_DEFINE", header: "kernel.h".}
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
    syscall, importc: "k_timer_start", header: "kernel.h".}
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
proc k_timer_stop*(timer: ptr k_timer) {.syscall, importc: "k_timer_stop",
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
proc k_timer_status_get*(timer: ptr k_timer): uint32_t {.syscall,
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
proc k_timer_status_sync*(timer: ptr k_timer): uint32_t {.syscall,
    importc: "k_timer_status_sync", header: "kernel.h".}
when defined(CONFIG_SYS_CLOCK_EXISTS):
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
  proc k_timer_expires_ticks*(timer: ptr k_timer): k_ticks_t {.syscall,
      importc: "k_timer_expires_ticks", header: "kernel.h".}
  proc z_impl_k_timer_expires_ticks*(timer: ptr k_timer): k_ticks_t {.inline.} =
    return z_timeout_expires(addr(timer.timeout))

  ## *
  ##  @brief Get time remaining before a timer next expires, in system ticks
  ##
  ##  This routine computes the time remaining before a running timer
  ##  next expires, in units of system ticks.  If the timer is not
  ##  running, it returns zero.
  ##
  proc k_timer_remaining_ticks*(timer: ptr k_timer): k_ticks_t {.syscall,
      importc: "k_timer_remaining_ticks", header: "kernel.h".}
  proc z_impl_k_timer_remaining_ticks*(timer: ptr k_timer): k_ticks_t {.inline.} =
    return z_timeout_remaining(addr(timer.timeout))

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
  proc k_timer_remaining_get*(timer: ptr k_timer): uint32_t {.inline.} =
    return k_ticks_to_ms_floor32(k_timer_remaining_ticks(timer))

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
proc k_timer_user_data_set*(timer: ptr k_timer; user_data: pointer) {.syscall,
    importc: "k_timer_user_data_set", header: "kernel.h".}
## *
##  @internal
##
proc z_impl_k_timer_user_data_set*(timer: ptr k_timer; user_data: pointer) {.inline.} =
  timer.user_data = user_data

## *
##  @brief Retrieve the user-specific data from a timer.
##
##  @param timer     Address of timer.
##
##  @return The user data.
##
proc k_timer_user_data_get*(timer: ptr k_timer): pointer {.syscall,
    importc: "k_timer_user_data_get", header: "kernel.h".}
proc z_impl_k_timer_user_data_get*(timer: ptr k_timer): pointer {.inline.} =
  return timer.user_data

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
proc k_uptime_ticks*(): int64_t {.syscall, importc: "k_uptime_ticks",
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
proc k_uptime_get*(): int64_t {.inline.} =
  return k_ticks_to_ms_floor64(k_uptime_ticks())

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
proc k_uptime_get_32*(): uint32_t {.inline.} =
  return cast[uint32_t](k_uptime_get())

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
proc k_uptime_delta*(reftime: ptr int64_t): int64_t {.inline.} =
  var
    uptime: int64_t
    delta: int64_t
  uptime = k_uptime_get()
  delta = uptime - reftime[]
  reftime[] = uptime
  return delta

## *
##  @brief Read the hardware clock.
##
##  This routine returns the current time, as measured by the system's hardware
##  clock.
##
##  @return Current hardware clock up-counter (in cycles).
##
proc k_cycle_get_32*(): uint32_t {.inline.} =
  return arch_k_cycle_get_32()

## *
##  @}
##
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_queue* {.importc: "k_queue", header: "kernel.h", bycopy.} = object
    data_q* {.importc: "data_q".}: sys_sflist_t
    lock* {.importc: "lock".}: k_spinlock
    wait_q* {.importc: "wait_q".}: _wait_q_t
    poll_events* {.importc: "poll_events".}: sys_dlist_t ##  _POLL_EVENT;

proc Z_QUEUE_INITIALIZER*(obj: untyped) {.importc: "Z_QUEUE_INITIALIZER",
    header: "kernel.h".}
proc z_queue_node_peek*(node: ptr sys_sfnode_t; needs_free: bool): pointer {.
    importc: "z_queue_node_peek", header: "kernel.h".}
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
proc k_queue_init*(queue: ptr k_queue) {.syscall, importc: "k_queue_init",
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
proc k_queue_cancel_wait*(queue: ptr k_queue) {.syscall,
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
proc k_queue_alloc_append*(queue: ptr k_queue; data: pointer): int32_t {.syscall,
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
proc k_queue_alloc_prepend*(queue: ptr k_queue; data: pointer): int32_t {.syscall,
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
proc k_queue_get*(queue: ptr k_queue; timeout: k_timeout_t): pointer {.syscall,
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
proc k_queue_is_empty*(queue: ptr k_queue): cint {.syscall,
    importc: "k_queue_is_empty", header: "kernel.h".}
proc z_impl_k_queue_is_empty*(queue: ptr k_queue): cint {.inline.} =
  return cast[cint](sys_sflist_is_empty(addr(queue.data_q)))

## *
##  @brief Peek element at the head of queue.
##
##  Return element from the head of queue without removing it.
##
##  @param queue Address of the queue.
##
##  @return Head element, or NULL if queue is empty.
##
proc k_queue_peek_head*(queue: ptr k_queue): pointer {.syscall,
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
proc k_queue_peek_tail*(queue: ptr k_queue): pointer {.syscall,
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
proc K_QUEUE_DEFINE*(name: untyped) {.importc: "K_QUEUE_DEFINE", header: "kernel.h".}
## * @}
when defined(CONFIG_USERSPACE):
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
      wait_q* {.importc: "wait_q".}: _wait_q_t
      lock* {.importc: "lock".}: k_spinlock

  proc Z_FUTEX_DATA_INITIALIZER*(obj: untyped) {.
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
      syscall, importc: "k_futex_wait", header: "kernel.h".}
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
  proc k_futex_wake*(futex: ptr k_futex; wake_all: bool): cint {.syscall,
      importc: "k_futex_wake", header: "kernel.h".}
  ## * @}
type
  k_fifo* {.importc: "k_fifo", header: "kernel.h", bycopy.} = object
    _queue* {.importc: "_queue".}: k_queue

## *
##  @cond INTERNAL_HIDDEN
##
proc Z_FIFO_INITIALIZER*(obj: untyped) {.importc: "Z_FIFO_INITIALIZER",
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
proc k_fifo_init*(fifo: untyped) {.importc: "k_fifo_init", header: "kernel.h".}
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
proc k_fifo_cancel_wait*(fifo: untyped) {.importc: "k_fifo_cancel_wait",
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
proc k_fifo_put*(fifo: untyped; data: untyped) {.importc: "k_fifo_put",
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
proc k_fifo_alloc_put*(fifo: untyped; data: untyped) {.importc: "k_fifo_alloc_put",
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
proc k_fifo_put_list*(fifo: untyped; head: untyped; tail: untyped) {.
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
proc k_fifo_put_slist*(fifo: untyped; list: untyped) {.importc: "k_fifo_put_slist",
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
proc k_fifo_get*(fifo: untyped; timeout: untyped) {.importc: "k_fifo_get",
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
proc k_fifo_is_empty*(fifo: untyped) {.importc: "k_fifo_is_empty",
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
proc k_fifo_peek_head*(fifo: untyped) {.importc: "k_fifo_peek_head",
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
proc k_fifo_peek_tail*(fifo: untyped) {.importc: "k_fifo_peek_tail",
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
proc K_FIFO_DEFINE*(name: untyped) {.importc: "K_FIFO_DEFINE", header: "kernel.h".}
## * @}
type
  k_lifo* {.importc: "k_lifo", header: "kernel.h", bycopy.} = object
    _queue* {.importc: "_queue".}: k_queue

## *
##  @cond INTERNAL_HIDDEN
##
proc Z_LIFO_INITIALIZER*(obj: untyped) {.importc: "Z_LIFO_INITIALIZER",
                                      header: "kernel.h".}
## *
##  INTERNAL_HIDDEN @endcond
##
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
proc k_lifo_init*(lifo: untyped) {.importc: "k_lifo_init", header: "kernel.h".}
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
proc k_lifo_put*(lifo: untyped; data: untyped) {.importc: "k_lifo_put",
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
proc k_lifo_alloc_put*(lifo: untyped; data: untyped) {.importc: "k_lifo_alloc_put",
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
proc k_lifo_get*(lifo: untyped; timeout: untyped) {.importc: "k_lifo_get",
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
proc K_LIFO_DEFINE*(name: untyped) {.importc: "K_LIFO_DEFINE", header: "kernel.h".}
## * @}
## *
##  @cond INTERNAL_HIDDEN
##
var K_STACK_FLAG_ALLOC* {.importc: "K_STACK_FLAG_ALLOC", header: "kernel.h".}: int
type
  stack_data_t* = uintptr_t
type
  k_stack* {.importc: "k_stack", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: _wait_q_t
    lock* {.importc: "lock".}: k_spinlock
    base* {.importc: "base".}: ptr stack_data_t
    next* {.importc: "next".}: ptr stack_data_t
    top* {.importc: "top".}: ptr stack_data_t
    flags* {.importc: "flags".}: uint8_t

proc Z_STACK_INITIALIZER*(obj: untyped; stack_buffer: untyped;
                          stack_num_entries: untyped) {.
    importc: "Z_STACK_INITIALIZER", header: "kernel.h".}
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
                  num_entries: uint32_t) {.importc: "k_stack_init",
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
proc k_stack_alloc_init*(stack: ptr k_stack; num_entries: uint32_t): int32_t {.
    syscall, importc: "k_stack_alloc_init", header: "kernel.h".}
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
proc k_stack_push*(stack: ptr k_stack; data: stack_data_t): cint {.syscall,
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
    syscall, importc: "k_stack_pop", header: "kernel.h".}
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
proc K_STACK_DEFINE*(name: untyped; stack_num_entries: untyped) {.
    importc: "K_STACK_DEFINE", header: "kernel.h".}
## * @}
## *
##  @cond INTERNAL_HIDDEN
##
discard "forward decl of k_work"
discard "forward decl of k_work_q"
discard "forward decl of k_work_queue_config"
discard "forward decl of k_delayed_work"
var k_sys_work_q* {.importc: "k_sys_work_q", header: "kernel.h".}: k_work_q
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
    wait_q* {.importc: "wait_q".}: _wait_q_t ## * Mutex wait queue
    ## * Mutex owner
    owner* {.importc: "owner".}: ptr k_thread ## * Current lock count
    lock_count* {.importc: "lock_count".}: uint32_t ## * Original thread priority
    owner_orig_prio* {.importc: "owner_orig_prio".}: cint

## *
##  @cond INTERNAL_HIDDEN
##
proc Z_MUTEX_INITIALIZER*(obj: untyped) {.importc: "Z_MUTEX_INITIALIZER",
    header: "kernel.h".}
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
proc K_MUTEX_DEFINE*(name: untyped) {.importc: "K_MUTEX_DEFINE", header: "kernel.h".}
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
proc k_mutex_init*(mutex: ptr k_mutex): cint {.syscall, importc: "k_mutex_init",
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
proc k_mutex_lock*(mutex: ptr k_mutex; timeout: k_timeout_t): cint {.syscall,
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
proc k_mutex_unlock*(mutex: ptr k_mutex): cint {.syscall, importc: "k_mutex_unlock",
    header: "kernel.h".}
## *
##  @}
##
type
  k_condvar* {.importc: "k_condvar", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: _wait_q_t

proc Z_CONDVAR_INITIALIZER*(obj: untyped) {.importc: "Z_CONDVAR_INITIALIZER",
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
proc k_condvar_init*(condvar: ptr k_condvar): cint {.syscall,
    importc: "k_condvar_init", header: "kernel.h".}
## *
##  @brief Signals one thread that is pending on the condition variable
##
##  @param condvar pointer to a @p k_condvar structure
##  @retval 0 On success
##
proc k_condvar_signal*(condvar: ptr k_condvar): cint {.syscall,
    importc: "k_condvar_signal", header: "kernel.h".}
## *
##  @brief Unblock all threads that are pending on the condition
##  variable
##
##  @param condvar pointer to a @p k_condvar structure
##  @return An integer with number of woken threads on success
##
proc k_condvar_broadcast*(condvar: ptr k_condvar): cint {.syscall,
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
    syscall, importc: "k_condvar_wait", header: "kernel.h".}
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
proc K_CONDVAR_DEFINE*(name: untyped) {.importc: "K_CONDVAR_DEFINE",
                                      header: "kernel.h".}
## *
##  @}
##
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_sem* {.importc: "k_sem", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: _wait_q_t
    count* {.importc: "count".}: cuint
    limit* {.importc: "limit".}: cuint
    poll_events* {.importc: "poll_events".}: sys_dlist_t ##  _POLL_EVENT;

proc Z_SEM_INITIALIZER*(obj: untyped; initial_count: untyped; count_limit: untyped) {.
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
proc k_sem_init*(sem: ptr k_sem; initial_count: cuint; limit: cuint): cint {.syscall,
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
proc k_sem_take*(sem: ptr k_sem; timeout: k_timeout_t): cint {.syscall,
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
proc k_sem_give*(sem: ptr k_sem) {.syscall, importc: "k_sem_give", header: "kernel.h".}
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
proc k_sem_reset*(sem: ptr k_sem) {.syscall, importc: "k_sem_reset",
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
proc k_sem_count_get*(sem: ptr k_sem): cuint {.syscall, importc: "k_sem_count_get",
    header: "kernel.h".}
## *
##  @internal
##
proc z_impl_k_sem_count_get*(sem: ptr k_sem): cuint {.inline.} =
  return sem.count

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
proc K_SEM_DEFINE*(name: untyped; initial_count: untyped; count_limit: untyped) {.
    importc: "K_SEM_DEFINE", header: "kernel.h".}
## * @}
## *
##  @cond INTERNAL_HIDDEN
##
discard "forward decl of k_work_delayable"
discard "forward decl of k_work_sync"
type
  k_work_handler_t* = proc (work: ptr k_work)
## * @brief Initialize a (non-delayable) work structure.
##
##  This must be invoked before submitting a work structure for the first time.
##  It need not be invoked again on the same work structure.  It can be
##  re-invoked to change the associated handler, but this must be done when the
##  work item is idle.
##
##  @funcprops \isr_ok
##
##  @param work the work structure to be initialized.
##
##  @param handler the handler to be invoked by the work item.
##
proc k_work_init*(work: ptr k_work; handler: k_work_handler_t) {.
    importc: "k_work_init", header: "kernel.h".}
## * @brief Busy state flags from the work item.
##
##  A zero return value indicates the work item appears to be idle.
##
##  @note This is a live snapshot of state, which may change before the result
##  is checked.  Use locks where appropriate.
##
##  @funcprops \isr_ok
##
##  @param work pointer to the work item.
##
##  @return a mask of flags K_WORK_DELAYED, K_WORK_QUEUED,
##  K_WORK_RUNNING, and K_WORK_CANCELING.
##
proc k_work_busy_get*(work: ptr k_work): cint {.importc: "k_work_busy_get",
    header: "kernel.h".}
## * @brief Test whether a work item is currently pending.
##
##  Wrapper to determine whether a work item is in a non-idle dstate.
##
##  @note This is a live snapshot of state, which may change before the result
##  is checked.  Use locks where appropriate.
##
##  @funcprops \isr_ok
##
##  @param work pointer to the work item.
##
##  @return true if and only if k_work_busy_get() returns a non-zero value.
##
proc k_work_is_pending*(work: ptr k_work): bool {.inline,
    importc: "k_work_is_pending", header: "kernel.h".}
## * @brief Submit a work item to a queue.
##
##  @param queue pointer to the work queue on which the item should run.  If
##  NULL the queue from the most recent submission will be used.
##
##  @funcprops \isr_ok
##
##  @param work pointer to the work item.
##
##  @retval 0 if work was already submitted to a queue
##  @retval 1 if work was not submitted and has been queued to @p queue
##  @retval 2 if work was running and has been queued to the queue that was
##  running it
##  @retval -EBUSY
##  * if work submission was rejected because the work item is cancelling; or
##  * @p queue is draining; or
##  * @p queue is plugged.
##  @retval -EINVAL if @p queue is null and the work item has never been run.
##  @retval -ENODEV if @p queue has not been started.
##
proc k_work_submit_to_queue*(queue: ptr k_work_q; work: ptr k_work): cint {.
    importc: "k_work_submit_to_queue", header: "kernel.h".}
## * @brief Submit a work item to the system queue.
##
##  @funcprops \isr_ok
##
##  @param work pointer to the work item.
##
##  @return as with k_work_submit_to_queue().
##
proc k_work_submit*(work: ptr k_work): cint {.importc: "k_work_submit",
    header: "kernel.h".}
## * @brief Wait for last-submitted instance to complete.
##
##  Resubmissions may occur while waiting, including chained submissions (from
##  within the handler).
##
##  @note Be careful of caller and work queue thread relative priority.  If
##  this function sleeps it will not return until the work queue thread
##  completes the tasks that allow this thread to resume.
##
##  @note Behavior is undefined if this function is invoked on @p work from a
##  work queue running @p work.
##
##  @param work pointer to the work item.
##
##  @param sync pointer to an opaque item containing state related to the
##  pending cancellation.  The object must persist until the call returns, and
##  be accessible from both the caller thread and the work queue thread.  The
##  object must not be used for any other flush or cancel operation until this
##  one completes.  On architectures with CONFIG_KERNEL_COHERENCE the object
##  must be allocated in coherent memory.
##
##  @retval true if call had to wait for completion
##  @retval false if work was already idle
##
proc k_work_flush*(work: ptr k_work; sync: ptr k_work_sync): bool {.
    importc: "k_work_flush", header: "kernel.h".}
## * @brief Cancel a work item.
##
##  This attempts to prevent a pending (non-delayable) work item from being
##  processed by removing it from the work queue.  If the item is being
##  processed, the work item will continue to be processed, but resubmissions
##  are rejected until cancellation completes.
##
##  If this returns zero cancellation is complete, otherwise something
##  (probably a work queue thread) is still referencing the item.
##
##  See also k_work_cancel_sync().
##
##  @funcprops \isr_ok
##
##  @param work pointer to the work item.
##
##  @return the k_work_busy_get() status indicating the state of the item after all
##  cancellation steps performed by this call are completed.
##
proc k_work_cancel*(work: ptr k_work): cint {.importc: "k_work_cancel",
    header: "kernel.h".}
## * @brief Cancel a work item and wait for it to complete.
##
##  Same as k_work_cancel() but does not return until cancellation is complete.
##  This can be invoked by a thread after k_work_cancel() to synchronize with a
##  previous cancellation.
##
##  On return the work structure will be idle unless something submits it after
##  the cancellation was complete.
##
##  @note Be careful of caller and work queue thread relative priority.  If
##  this function sleeps it will not return until the work queue thread
##  completes the tasks that allow this thread to resume.
##
##  @note Behavior is undefined if this function is invoked on @p work from a
##  work queue running @p work.
##
##  @param work pointer to the work item.
##
##  @param sync pointer to an opaque item containing state related to the
##  pending cancellation.  The object must persist until the call returns, and
##  be accessible from both the caller thread and the work queue thread.  The
##  object must not be used for any other flush or cancel operation until this
##  one completes.  On architectures with CONFIG_KERNEL_COHERENCE the object
##  must be allocated in coherent memory.
##
##  @retval true if work was pending (call had to wait for cancellation of a
##  running handler to complete, or scheduled or submitted operations were
##  cancelled);
##  @retval false otherwise
##
proc k_work_cancel_sync*(work: ptr k_work; sync: ptr k_work_sync): bool {.
    importc: "k_work_cancel_sync", header: "kernel.h".}
## * @brief Initialize a work queue structure.
##
##  This must be invoked before starting a work queue structure for the first time.
##  It need not be invoked again on the same work queue structure.
##
##  @funcprops \isr_ok
##
##  @param queue the queue structure to be initialized.
##
proc k_work_queue_init*(queue: ptr k_work_q) {.importc: "k_work_queue_init",
    header: "kernel.h".}
## * @brief Initialize a work queue.
##
##  This configures the work queue thread and starts it running.  The function
##  should not be re-invoked on a queue.
##
##  @param queue pointer to the queue structure. It must be initialized
##         in zeroed/bss memory or with @ref k_work_queue_init before
##         use.
##
##  @param stack pointer to the work thread stack area.
##
##  @param stack_size size of the the work thread stack area, in bytes.
##
##  @param prio initial thread priority
##
##  @param cfg optional additional configuration parameters.  Pass @c
##  NULL if not required, to use the defaults documented in
##  k_work_queue_config.
##
proc k_work_queue_start*(queue: ptr k_work_q; stack: ptr k_thread_stack_t;
                        stack_size: csize_t; prio: cint;
                        cfg: ptr k_work_queue_config) {.
    importc: "k_work_queue_start", header: "kernel.h".}
## * @brief Access the thread that animates a work queue.
##
##  This is necessary to grant a work queue thread access to things the work
##  items it will process are expected to use.
##
##  @param queue pointer to the queue structure.
##
##  @return the thread associated with the work queue.
##
proc k_work_queue_thread_get*(queue: ptr k_work_q): k_tid_t {.inline,
    importc: "k_work_queue_thread_get", header: "kernel.h".}
## * @brief Wait until the work queue has drained, optionally plugging it.
##
##  This blocks submission to the work queue except when coming from queue
##  thread, and blocks the caller until no more work items are available in the
##  queue.
##
##  If @p plug is true then submission will continue to be blocked after the
##  drain operation completes until k_work_queue_unplug() is invoked.
##
##  Note that work items that are delayed are not yet associated with their
##  work queue.  They must be cancelled externally if a goal is to ensure the
##  work queue remains empty.  The @p plug feature can be used to prevent
##  delayed items from being submitted after the drain completes.
##
##  @param queue pointer to the queue structure.
##
##  @param plug if true the work queue will continue to block new submissions
##  after all items have drained.
##
##  @retval 1 if call had to wait for the drain to complete
##  @retval 0 if call did not have to wait
##  @retval negative if wait was interrupted or failed
##
proc k_work_queue_drain*(queue: ptr k_work_q; plug: bool): cint {.
    importc: "k_work_queue_drain", header: "kernel.h".}
## * @brief Release a work queue to accept new submissions.
##
##  This releases the block on new submissions placed when k_work_queue_drain()
##  is invoked with the @p plug option enabled.  If this is invoked before the
##  drain completes new items may be submitted as soon as the drain completes.
##
##  @funcprops \isr_ok
##
##  @param queue pointer to the queue structure.
##
##  @retval 0 if successfully unplugged
##  @retval -EALREADY if the work queue was not plugged.
##
proc k_work_queue_unplug*(queue: ptr k_work_q): cint {.
    importc: "k_work_queue_unplug", header: "kernel.h".}
## * @brief Initialize a delayable work structure.
##
##  This must be invoked before scheduling a delayable work structure for the
##  first time.  It need not be invoked again on the same work structure.  It
##  can be re-invoked to change the associated handler, but this must be done
##  when the work item is idle.
##
##  @funcprops \isr_ok
##
##  @param dwork the delayable work structure to be initialized.
##
##  @param handler the handler to be invoked by the work item.
##
proc k_work_init_delayable*(dwork: ptr k_work_delayable; handler: k_work_handler_t) {.
    importc: "k_work_init_delayable", header: "kernel.h".}
## *
##  @brief Get the parent delayable work structure from a work pointer.
##
##  This function is necessary when a @c k_work_handler_t function is passed to
##  k_work_schedule_for_queue() and the handler needs to access data from the
##  container of the containing `k_work_delayable`.
##
##  @param work Address passed to the work handler
##
##  @return Address of the containing @c k_work_delayable structure.
##
proc k_work_delayable_from_work*(work: ptr k_work): ptr k_work_delayable {.inline,
    importc: "k_work_delayable_from_work", header: "kernel.h".}
## * @brief Busy state flags from the delayable work item.
##
##  @funcprops \isr_ok
##
##  @note This is a live snapshot of state, which may change before the result
##  can be inspected.  Use locks where appropriate.
##
##  @param dwork pointer to the delayable work item.
##
##  @return a mask of flags K_WORK_DELAYED, K_WORK_QUEUED, K_WORK_RUNNING, and
##  K_WORK_CANCELING.  A zero return value indicates the work item appears to
##  be idle.
##
proc k_work_delayable_busy_get*(dwork: ptr k_work_delayable): cint {.
    importc: "k_work_delayable_busy_get", header: "kernel.h".}
## * @brief Test whether a delayed work item is currently pending.
##
##  Wrapper to determine whether a delayed work item is in a non-idle state.
##
##  @note This is a live snapshot of state, which may change before the result
##  can be inspected.  Use locks where appropriate.
##
##  @funcprops \isr_ok
##
##  @param dwork pointer to the delayable work item.
##
##  @return true if and only if k_work_delayable_busy_get() returns a non-zero
##  value.
##
proc k_work_delayable_is_pending*(dwork: ptr k_work_delayable): bool {.inline,
    importc: "k_work_delayable_is_pending", header: "kernel.h".}
## * @brief Get the absolute tick count at which a scheduled delayable work
##  will be submitted.
##
##  @note This is a live snapshot of state, which may change before the result
##  can be inspected.  Use locks where appropriate.
##
##  @funcprops \isr_ok
##
##  @param dwork pointer to the delayable work item.
##
##  @return the tick count when the timer that will schedule the work item will
##  expire, or the current tick count if the work is not scheduled.
##
proc k_work_delayable_expires_get*(dwork: ptr k_work_delayable): k_ticks_t {.
    inline, importc: "k_work_delayable_expires_get", header: "kernel.h".}
## * @brief Get the number of ticks until a scheduled delayable work will be
##  submitted.
##
##  @note This is a live snapshot of state, which may change before the result
##  can be inspected.  Use locks where appropriate.
##
##  @funcprops \isr_ok
##
##  @param dwork pointer to the delayable work item.
##
##  @return the number of ticks until the timer that will schedule the work
##  item will expire, or zero if the item is not scheduled.
##
proc k_work_delayable_remaining_get*(dwork: ptr k_work_delayable): k_ticks_t {.
    inline, importc: "k_work_delayable_remaining_get", header: "kernel.h".}
## * @brief Submit an idle work item to a queue after a delay.
##
##  Unlike k_work_reschedule_for_queue() this is a no-op if the work item is
##  already scheduled or submitted, even if @p delay is @c K_NO_WAIT.
##
##  @funcprops \isr_ok
##
##  @param queue the queue on which the work item should be submitted after the
##  delay.
##
##  @param dwork pointer to the delayable work item.
##
##  @param delay the time to wait before submitting the work item.  If @c
##  K_NO_WAIT and the work is not pending this is equivalent to
##  k_work_submit_to_queue().
##
##  @retval 0 if work was already scheduled or submitted.
##  @retval 1 if work has been scheduled.
##  @retval -EBUSY if @p delay is @c K_NO_WAIT and
##          k_work_submit_to_queue() fails with this code.
##  @retval -EINVAL if @p delay is @c K_NO_WAIT and
##          k_work_submit_to_queue() fails with this code.
##  @retval -ENODEV if @p delay is @c K_NO_WAIT and
##          k_work_submit_to_queue() fails with this code.
##
proc k_work_schedule_for_queue*(queue: ptr k_work_q; dwork: ptr k_work_delayable;
                                delay: k_timeout_t): cint {.
    importc: "k_work_schedule_for_queue", header: "kernel.h".}
## * @brief Submit an idle work item to the system work queue after a
##  delay.
##
##  This is a thin wrapper around k_work_schedule_for_queue(), with all the API
##  characteristcs of that function.
##
##  @param dwork pointer to the delayable work item.
##
##  @param delay the time to wait before submitting the work item.  If @c
##  K_NO_WAIT this is equivalent to k_work_submit_to_queue().
##
##  @return as with k_work_schedule_for_queue().
##
proc k_work_schedule*(dwork: ptr k_work_delayable; delay: k_timeout_t): cint {.
    importc: "k_work_schedule", header: "kernel.h".}
## * @brief Reschedule a work item to a queue after a delay.
##
##  Unlike k_work_schedule_for_queue() this function can change the deadline of
##  a scheduled work item, and will schedule a work item that isn't idle
##  (e.g. is submitted or running).  This function does not affect ("unsubmit")
##  a work item that has been submitted to a queue.
##
##  @funcprops \isr_ok
##
##  @param queue the queue on which the work item should be submitted after the
##  delay.
##
##  @param dwork pointer to the delayable work item.
##
##  @param delay the time to wait before submitting the work item.  If @c
##  K_NO_WAIT this is equivalent to k_work_submit_to_queue() after canceling
##  any previous scheduled submission.
##
##  @note If delay is @c K_NO_WAIT ("no delay") the return values are as with
##  k_work_submit_to_queue().
##
##  @retval 0 if delay is @c K_NO_WAIT and work was already on a queue
##  @retval 1 if
##  * delay is @c K_NO_WAIT and work was not submitted but has now been queued
##    to @p queue; or
##  * delay not @c K_NO_WAIT and work has been scheduled
##  @retval 2 if delay is @c K_NO_WAIT and work was running and has been queued
##  to the queue that was running it
##  @retval -EBUSY if @p delay is @c K_NO_WAIT and
##          k_work_submit_to_queue() fails with this code.
##  @retval -EINVAL if @p delay is @c K_NO_WAIT and
##          k_work_submit_to_queue() fails with this code.
##  @retval -ENODEV if @p delay is @c K_NO_WAIT and
##          k_work_submit_to_queue() fails with this code.
##
proc k_work_reschedule_for_queue*(queue: ptr k_work_q;
                                  dwork: ptr k_work_delayable; delay: k_timeout_t): cint {.
    importc: "k_work_reschedule_for_queue", header: "kernel.h".}
## * @brief Reschedule a work item to the system work queue after a
##  delay.
##
##  This is a thin wrapper around k_work_reschedule_for_queue(), with all the
##  API characteristcs of that function.
##
##  @param dwork pointer to the delayable work item.
##
##  @param delay the time to wait before submitting the work item.
##
##  @return as with k_work_reschedule_for_queue().
##
proc k_work_reschedule*(dwork: ptr k_work_delayable; delay: k_timeout_t): cint {.
    importc: "k_work_reschedule", header: "kernel.h".}
## * @brief Flush delayable work.
##
##  If the work is scheduled, it is immediately submitted.  Then the caller
##  blocks until the work completes, as with k_work_flush().
##
##  @note Be careful of caller and work queue thread relative priority.  If
##  this function sleeps it will not return until the work queue thread
##  completes the tasks that allow this thread to resume.
##
##  @note Behavior is undefined if this function is invoked on @p dwork from a
##  work queue running @p dwork.
##
##  @param dwork pointer to the delayable work item.
##
##  @param sync pointer to an opaque item containing state related to the
##  pending cancellation.  The object must persist until the call returns, and
##  be accessible from both the caller thread and the work queue thread.  The
##  object must not be used for any other flush or cancel operation until this
##  one completes.  On architectures with CONFIG_KERNEL_COHERENCE the object
##  must be allocated in coherent memory.
##
##  @retval true if call had to wait for completion
##  @retval false if work was already idle
##
proc k_work_flush_delayable*(dwork: ptr k_work_delayable; sync: ptr k_work_sync): bool {.
    importc: "k_work_flush_delayable", header: "kernel.h".}
## * @brief Cancel delayable work.
##
##  Similar to k_work_cancel() but for delayable work.  If the work is
##  scheduled or submitted it is canceled.  This function does not wait for the
##  cancellation to complete.
##
##  @note The work may still be running when this returns.  Use
##  k_work_flush_delayable() or k_work_cancel_delayable_sync() to ensure it is
##  not running.
##
##  @note Canceling delayable work does not prevent rescheduling it.  It does
##  prevent submitting it until the cancellation completes.
##
##  @funcprops \isr_ok
##
##  @param dwork pointer to the delayable work item.
##
##  @return the k_work_delayable_busy_get() status indicating the state of the
##  item after all cancellation steps performed by this call are completed.
##
proc k_work_cancel_delayable*(dwork: ptr k_work_delayable): cint {.
    importc: "k_work_cancel_delayable", header: "kernel.h".}
## * @brief Cancel delayable work and wait.
##
##  Like k_work_cancel_delayable() but waits until the work becomes idle.
##
##  @note Canceling delayable work does not prevent rescheduling it.  It does
##  prevent submitting it until the cancellation completes.
##
##  @note Be careful of caller and work queue thread relative priority.  If
##  this function sleeps it will not return until the work queue thread
##  completes the tasks that allow this thread to resume.
##
##  @note Behavior is undefined if this function is invoked on @p dwork from a
##  work queue running @p dwork.
##
##  @param dwork pointer to the delayable work item.
##
##  @param sync pointer to an opaque item containing state related to the
##  pending cancellation.  The object must persist until the call returns, and
##  be accessible from both the caller thread and the work queue thread.  The
##  object must not be used for any other flush or cancel operation until this
##  one completes.  On architectures with CONFIG_KERNEL_COHERENCE the object
##  must be allocated in coherent memory.
##
##  @retval true if work was not idle (call had to wait for cancellation of a
##  running handler to complete, or scheduled or submitted operations were
##  cancelled);
##  @retval false otherwise
##
proc k_work_cancel_delayable_sync*(dwork: ptr k_work_delayable;
                                  sync: ptr k_work_sync): bool {.
    importc: "k_work_cancel_delayable_sync", header: "kernel.h".}
const ## *
      ##  @cond INTERNAL_HIDDEN
      ##
      ##  The atomic API is used for all work and queue flags fields to
      ##  enforce sequential consistency in SMP environments.
      ##
      ##  Bits that represent the work item states.  At least nine of the
      ##  combinations are distinct valid stable states.
      ##
  K_WORK_RUNNING_BIT* = 0
  K_WORK_CANCELING_BIT* = 1
  K_WORK_QUEUED_BIT* = 2
  K_WORK_DELAYED_BIT* = 3
  K_WORK_MASK* = BIT(K_WORK_DELAYED_BIT) or BIT(K_WORK_QUEUED_BIT) or
      BIT(K_WORK_RUNNING_BIT) or BIT(K_WORK_CANCELING_BIT) ##  Static work flags
  K_WORK_DELAYABLE_BIT* = 8
  K_WORK_DELAYABLE* = BIT(K_WORK_DELAYABLE_BIT) ##  Dynamic work queue flags
  K_WORK_QUEUE_STARTED_BIT* = 0
  K_WORK_QUEUE_STARTED* = BIT(K_WORK_QUEUE_STARTED_BIT)
  K_WORK_QUEUE_BUSY_BIT* = 1
  K_WORK_QUEUE_BUSY* = BIT(K_WORK_QUEUE_BUSY_BIT)
  K_WORK_QUEUE_DRAIN_BIT* = 2
  K_WORK_QUEUE_DRAIN* = BIT(K_WORK_QUEUE_DRAIN_BIT)
  K_WORK_QUEUE_PLUGGED_BIT* = 3
  K_WORK_QUEUE_PLUGGED* = BIT(K_WORK_QUEUE_PLUGGED_BIT) ##  Static work queue flags
  K_WORK_QUEUE_NO_YIELD_BIT* = 8
  K_WORK_QUEUE_NO_YIELD* = BIT(K_WORK_QUEUE_NO_YIELD_BIT) ## *
                                                        ##  INTERNAL_HIDDEN @endcond
                                                        ##
                                                        ##  Transient work flags
                                                        ## * @brief Flag indicating a work item that is running under a work
                                                        ##  queue thread.
                                                        ##
                                                        ##  Accessed via k_work_busy_get().  May co-occur with other flags.
                                                        ##
  K_WORK_RUNNING* = BIT(K_WORK_RUNNING_BIT) ## * @brief Flag indicating a work item that is being canceled.
                                          ##
                                          ##  Accessed via k_work_busy_get().  May co-occur with other flags.
                                          ##
  K_WORK_CANCELING* = BIT(K_WORK_CANCELING_BIT) ## * @brief Flag indicating a work item that has been submitted to a
                                              ##  queue but has not started running.
                                              ##
                                              ##  Accessed via k_work_busy_get().  May co-occur with other flags.
                                              ##
  K_WORK_QUEUED* = BIT(K_WORK_QUEUED_BIT) ## * @brief Flag indicating a delayed work item that is scheduled for
                                        ##  submission to a queue.
                                        ##
                                        ##  Accessed via k_work_busy_get().  May co-occur with other flags.
                                        ##
  K_WORK_DELAYED* = BIT(K_WORK_DELAYED_BIT)
## * @brief A structure used to submit work.
type
  k_work* {.importc: "k_work", header: "kernel.h", bycopy.} = object
    node* {.importc: "node".}: sys_snode_t ##  All fields are protected by the work module spinlock.  No fields
                                        ##  are to be accessed except through kernel API.
                                        ##
                                        ##  Node to link into k_work_q pending list.
    ##  The function to be invoked by the work queue thread.
    handler* {.importc: "handler".}: k_work_handler_t ##  The queue on which the work item was last submitted.
    queue* {.importc: "queue".}: ptr k_work_q ##  State of the work item.
                                          ##
                                          ##  The item can be DELAYED, QUEUED, and RUNNING simultaneously.
                                          ##
                                          ##  It can be RUNNING and CANCELING simultaneously.
                                          ##
    flags* {.importc: "flags".}: uint32_t

proc Z_WORK_INITIALIZER*(work_handler: untyped) {.importc: "Z_WORK_INITIALIZER",
    header: "kernel.h".}
## * @brief A structure used to submit work after a delay.
type
  k_work_delayable* {.importc: "k_work_delayable", header: "kernel.h", bycopy.} = object
    work* {.importc: "work".}: k_work ##  The work item.
    ##  Timeout used to submit work after a delay.
    timeout* {.importc: "timeout".}: _timeout ##  The queue to which the work should be submitted.
    queue* {.importc: "queue".}: ptr k_work_q

proc Z_WORK_DELAYABLE_INITIALIZER*(work_handler: untyped) {.
    importc: "Z_WORK_DELAYABLE_INITIALIZER", header: "kernel.h".}
## *
##  @brief Initialize a statically-defined delayable work item.
##
##  This macro can be used to initialize a statically-defined delayable
##  work item, prior to its first use. For example,
##
##  @code static K_WORK_DELAYABLE_DEFINE(<dwork>, <work_handler>); @endcode
##
##  Note that if the runtime dependencies support initialization with
##  k_work_init_delayable() using that will eliminate the initialized
##  object in ROM that is produced by this macro and copied in at
##  system startup.
##
##  @param work Symbol name for delayable work item object
##  @param work_handler Function to invoke each time work item is processed.
##
proc K_WORK_DELAYABLE_DEFINE*(work: untyped; work_handler: untyped) {.
    importc: "K_WORK_DELAYABLE_DEFINE", header: "kernel.h".}
## *
##  @cond INTERNAL_HIDDEN
##
##  Record used to wait for work to flush.
##
##  The work item is inserted into the queue that will process (or is
##  processing) the item, and will be processed as soon as the item
##  completes.  When the flusher is processed the semaphore will be
##  signaled, releasing the thread waiting for the flush.
##
type
  z_work_flusher* {.importc: "z_work_flusher", header: "kernel.h", bycopy.} = object
    work* {.importc: "work".}: k_work
    sem* {.importc: "sem".}: k_sem

##  Record used to wait for work to complete a cancellation.
##
##  The work item is inserted into a global queue of pending cancels.
##  When a cancelling work item goes idle any matching waiters are
##  removed from pending_cancels and are woken.
##
type
  z_work_canceller* {.importc: "z_work_canceller", header: "kernel.h", bycopy.} = object
    node* {.importc: "node".}: sys_snode_t
    work* {.importc: "work".}: ptr k_work
    sem* {.importc: "sem".}: k_sem

## *
##  INTERNAL_HIDDEN @endcond
##
## * @brief A structure holding internal state for a pending synchronous
##  operation on a work item or queue.
##
##  Instances of this type are provided by the caller for invocation of
##  k_work_flush(), k_work_cancel_sync() and sibling flush and cancel APIs.  A
##  referenced object must persist until the call returns, and be accessible
##  from both the caller thread and the work queue thread.
##
##  @note If CONFIG_KERNEL_COHERENCE is enabled the object must be allocated in
##  coherent memory; see arch_mem_coherent().  The stack on these architectures
##  is generally not coherent.  be stack-allocated.  Violations are detected by
##  runtime assertion.
##
type
  INNER_C_UNION_kernel_0* {.importc: "no_name", header: "kernel.h", bycopy, union.} = object
    flusher* {.importc: "flusher".}: z_work_flusher
    canceller* {.importc: "canceller".}: z_work_canceller

type
  k_work_sync* {.importc: "k_work_sync", header: "kernel.h", bycopy.} = object
    ano_kernel_1* {.importc: "ano_kernel_1".}: INNER_C_UNION_kernel_0

## * @brief A structure holding optional configuration items for a work
##  queue.
##
##  This structure, and values it references, are not retained by
##  k_work_queue_start().
##
type
  k_work_queue_config* {.importc: "k_work_queue_config", header: "kernel.h", bycopy.} = object
    name* {.importc: "name".}: cstring ## * The name to be given to the work queue thread.
                                    ##
                                    ##  If left null the thread will not have a name.
                                    ##
    ## * Control whether the work queue thread should yield between
    ##  items.
    ##
    ##  Yielding between items helps guarantee the work queue
    ##  thread does not starve other threads, including cooperative
    ##  ones released by a work item.  This is the default behavior.
    ##
    ##  Set this to @c true to prevent the work queue thread from
    ##  yielding between items.  This may be appropriate when a
    ##  sequence of items should complete without yielding
    ##  control.
    ##
    no_yield* {.importc: "no_yield".}: bool

## * @brief A structure used to hold work until it can be processed.
type
  k_work_q* {.importc: "k_work_q", header: "kernel.h", bycopy.} = object
    thread* {.importc: "thread".}: k_thread ##  The thread that animates the work.
    ##  All the following fields must be accessed only while the
    ##  work module spinlock is held.
    ##
    ##  List of k_work items to be worked.
    pending* {.importc: "pending".}: sys_slist_t ##  Wait queue for idle work thread.
    notifyq* {.importc: "notifyq".}: _wait_q_t ##  Wait queue for threads waiting for the queue to drain.
    drainq* {.importc: "drainq".}: _wait_q_t ##  Flags describing queue state.
    flags* {.importc: "flags".}: uint32_t

##  Provide the implementation for inline functions declared above
proc k_work_is_pending*(work: ptr k_work): bool {.inline.} =
  return k_work_busy_get(work) != 0

proc k_work_delayable_from_work*(work: ptr k_work): ptr k_work_delayable {.inline.} =
  return CONTAINER_OF(work, struct, k_work_delayable, work)

proc k_work_delayable_is_pending*(dwork: ptr k_work_delayable): bool {.inline.} =
  return k_work_delayable_busy_get(dwork) != 0

proc k_work_delayable_expires_get*(dwork: ptr k_work_delayable): k_ticks_t {.inline.} =
  return z_timeout_expires(addr(dwork.timeout))

proc k_work_delayable_remaining_get*(dwork: ptr k_work_delayable): k_ticks_t {.
    inline.} =
  return z_timeout_remaining(addr(dwork.timeout))

proc k_work_queue_thread_get*(queue: ptr k_work_q): k_tid_t {.inline.} =
  return addr(queue.thread)

discard "forward decl of k_work_user"
type
  k_work_user_handler_t* = proc (work: ptr k_work_user)
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_work_user_q* {.importc: "k_work_user_q", header: "kernel.h", bycopy.} = object
    queue* {.importc: "queue".}: k_queue
    thread* {.importc: "thread".}: k_thread

const
  K_WORK_USER_STATE_PENDING* = 0 ##  Work item pending state
type
  k_work_user* {.importc: "k_work_user", header: "kernel.h", bycopy.} = object
    _reserved* {.importc: "_reserved".}: pointer ##  Used by k_queue implementation.
    handler* {.importc: "handler".}: k_work_user_handler_t
    flags* {.importc: "flags".}: atomic_t

## *
##  INTERNAL_HIDDEN @endcond
##
proc Z_WORK_USER_INITIALIZER*(work_handler: untyped) {.
    importc: "Z_WORK_USER_INITIALIZER", header: "kernel.h".}
## *
##  @brief Initialize a statically-defined user work item.
##
##  This macro can be used to initialize a statically-defined user work
##  item, prior to its first use. For example,
##
##  @code static K_WORK_USER_DEFINE(<work>, <work_handler>); @endcode
##
##  @param work Symbol name for work item object
##  @param work_handler Function to invoke each time work item is processed.
##
proc K_WORK_USER_DEFINE*(work: untyped; work_handler: untyped) {.
    importc: "K_WORK_USER_DEFINE", header: "kernel.h".}
## *
##  @brief Initialize a userspace work item.
##
##  This routine initializes a user workqueue work item, prior to its
##  first use.
##
##  @param work Address of work item.
##  @param handler Function to invoke each time work item is processed.
##
##  @return N/A
##
proc k_work_user_init*(work: ptr k_work_user; handler: k_work_user_handler_t) {.
    inline.} =
  work[] = cast[k_work_user](Z_WORK_USER_INITIALIZER(handler))

## *
##  @brief Check if a userspace work item is pending.
##
##  This routine indicates if user work item @a work is pending in a workqueue's
##  queue.
##
##  @note Checking if the work is pending gives no guarantee that the
##        work will still be pending when this information is used. It is up to
##        the caller to make sure that this information is used in a safe manner.
##
##  @funcprops \isr_ok
##
##  @param work Address of work item.
##
##  @return true if work item is pending, or false if it is not pending.
##
proc k_work_user_is_pending*(work: ptr k_work_user): bool {.inline.} =
  return atomic_test_bit(addr(work.flags), K_WORK_USER_STATE_PENDING)

## *
##  @brief Submit a work item to a user mode workqueue
##
##  Submits a work item to a workqueue that runs in user mode. A temporary
##  memory allocation is made from the caller's resource pool which is freed
##  once the worker thread consumes the k_work item. The workqueue
##  thread must have memory access to the k_work item being submitted. The caller
##  must have permission granted on the work_q parameter's queue object.
##
##  @funcprops \isr_ok
##
##  @param work_q Address of workqueue.
##  @param work Address of work item.
##
##  @retval -EBUSY if the work item was already in some workqueue
##  @retval -ENOMEM if no memory for thread resource pool allocation
##  @retval 0 Success
##
proc k_work_user_submit_to_queue*(work_q: ptr k_work_user_q; work: ptr k_work_user): cint {.
    inline.} =
  var ret: cint
  if not atomic_test_and_set_bit(addr(work.flags), K_WORK_USER_STATE_PENDING):
    ret = k_queue_alloc_append(addr(work_q.queue), work)
    ##  Couldn't insert into the queue. Clear the pending bit
    ##  so the work item can be submitted again
    ##
    if ret != 0:
      atomic_clear_bit(addr(work.flags), K_WORK_USER_STATE_PENDING)
  return ret

## *
##  @brief Start a workqueue in user mode
##
##  This works identically to k_work_queue_start() except it is callable from
##  user mode, and the worker thread created will run in user mode.  The caller
##  must have permissions granted on both the work_q parameter's thread and
##  queue objects, and the same restrictions on priority apply as
##  k_thread_create().
##
##  @param work_q Address of workqueue.
##  @param stack Pointer to work queue thread's stack space, as defined by
## 		K_THREAD_STACK_DEFINE()
##  @param stack_size Size of the work queue thread's stack (in bytes), which
## 		should either be the same constant passed to
## 		K_THREAD_STACK_DEFINE() or the value of K_THREAD_STACK_SIZEOF().
##  @param prio Priority of the work queue's thread.
##  @param name optional thread name.  If not null a copy is made into the
## 		thread's name buffer.
##
##  @return N/A
##
proc k_work_user_queue_start*(work_q: ptr k_work_user_q;
                              stack: ptr k_thread_stack_t; stack_size: csize_t;
                              prio: cint; name: cstring) {.
    importc: "k_work_user_queue_start", header: "kernel.h".}
## * @}
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_work_poll* {.importc: "k_work_poll", header: "kernel.h", bycopy.} = object
    work* {.importc: "work".}: k_work
    workq* {.importc: "workq".}: ptr k_work_q
    poller* {.importc: "poller".}: z_poller
    events* {.importc: "events".}: ptr k_poll_event
    num_events* {.importc: "num_events".}: cint
    real_handler* {.importc: "real_handler".}: k_work_handler_t
    timeout* {.importc: "timeout".}: _timeout
    poll_result* {.importc: "poll_result".}: cint

## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @addtogroup workqueue_apis
##  @{
##
## *
##  @brief Initialize a statically-defined work item.
##
##  This macro can be used to initialize a statically-defined workqueue work
##  item, prior to its first use. For example,
##
##  @code static K_WORK_DEFINE(<work>, <work_handler>); @endcode
##
##  @param work Symbol name for work item object
##  @param work_handler Function to invoke each time work item is processed.
##
proc K_WORK_DEFINE*(work: untyped; work_handler: untyped) {.
    importc: "K_WORK_DEFINE", header: "kernel.h".}
## *
##  @brief Initialize a statically-defined delayed work item.
##
##  This macro can be used to initialize a statically-defined workqueue
##  delayed work item, prior to its first use. For example,
##
##  @code static K_DELAYED_WORK_DEFINE(<work>, <work_handler>); @endcode
##
##  @param work Symbol name for delayed work item object
##  @param work_handler Function to invoke each time work item is processed.
##
## *
##  @brief Initialize a triggered work item.
##
##  This routine initializes a workqueue triggered work item, prior to
##  its first use.
##
##  @param work Address of triggered work item.
##  @param handler Function to invoke each time work item is processed.
##
##  @return N/A
##
proc k_work_poll_init*(work: ptr k_work_poll; handler: k_work_handler_t) {.
    importc: "k_work_poll_init", header: "kernel.h".}
## *
##  @brief Submit a triggered work item.
##
##  This routine schedules work item @a work to be processed by workqueue
##  @a work_q when one of the given @a events is signaled. The routine
##  initiates internal poller for the work item and then returns to the caller.
##  Only when one of the watched events happen the work item is actually
##  submitted to the workqueue and becomes pending.
##
##  Submitting a previously submitted triggered work item that is still
##  waiting for the event cancels the existing submission and reschedules it
##  the using the new event list. Note that this behavior is inherently subject
##  to race conditions with the pre-existing triggered work item and work queue,
##  so care must be taken to synchronize such resubmissions externally.
##
##  @funcprops \isr_ok
##
##  @warning
##  Provided array of events as well as a triggered work item must be placed
##  in persistent memory (valid until work handler execution or work
##  cancellation) and cannot be modified after submission.
##
##  @param work_q Address of workqueue.
##  @param work Address of delayed work item.
##  @param events An array of events which trigger the work.
##  @param num_events The number of events in the array.
##  @param timeout Timeout after which the work will be scheduled
## 		  for execution even if not triggered.
##
##
##  @retval 0 Work item started watching for events.
##  @retval -EINVAL Work item is being processed or has completed its work.
##  @retval -EADDRINUSE Work item is pending on a different workqueue.
##
proc k_work_poll_submit_to_queue*(work_q: ptr k_work_q; work: ptr k_work_poll;
                                  events: ptr k_poll_event; num_events: cint;
                                  timeout: k_timeout_t): cint {.
    importc: "k_work_poll_submit_to_queue", header: "kernel.h".}
## *
##  @brief Submit a triggered work item to the system workqueue.
##
##  This routine schedules work item @a work to be processed by system
##  workqueue when one of the given @a events is signaled. The routine
##  initiates internal poller for the work item and then returns to the caller.
##  Only when one of the watched events happen the work item is actually
##  submitted to the workqueue and becomes pending.
##
##  Submitting a previously submitted triggered work item that is still
##  waiting for the event cancels the existing submission and reschedules it
##  the using the new event list. Note that this behavior is inherently subject
##  to race conditions with the pre-existing triggered work item and work queue,
##  so care must be taken to synchronize such resubmissions externally.
##
##  @funcprops \isr_ok
##
##  @warning
##  Provided array of events as well as a triggered work item must not be
##  modified until the item has been processed by the workqueue.
##
##  @param work Address of delayed work item.
##  @param events An array of events which trigger the work.
##  @param num_events The number of events in the array.
##  @param timeout Timeout after which the work will be scheduled
## 		  for execution even if not triggered.
##
##  @retval 0 Work item started watching for events.
##  @retval -EINVAL Work item is being processed or has completed its work.
##  @retval -EADDRINUSE Work item is pending on a different workqueue.
##
proc k_work_poll_submit*(work: ptr k_work_poll; events: ptr k_poll_event;
                        num_events: cint; timeout: k_timeout_t): cint {.
    importc: "k_work_poll_submit", header: "kernel.h".}
## *
##  @brief Cancel a triggered work item.
##
##  This routine cancels the submission of triggered work item @a work.
##  A triggered work item can only be canceled if no event triggered work
##  submission.
##
##  @funcprops \isr_ok
##
##  @param work Address of delayed work item.
##
##  @retval 0 Work item canceled.
##  @retval -EINVAL Work item is being processed or has completed its work.
##
proc k_work_poll_cancel*(work: ptr k_work_poll): cint {.
    importc: "k_work_poll_cancel", header: "kernel.h".}
## * @}
## *
##  @defgroup msgq_apis Message Queue APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Message Queue Structure
##
type
  k_msgq* {.importc: "k_msgq", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: _wait_q_t ## * Message queue wait queue
    ## * Lock
    lock* {.importc: "lock".}: k_spinlock ## * Message size
    msg_size* {.importc: "msg_size".}: csize_t ## * Maximal number of messages
    max_msgs* {.importc: "max_msgs".}: uint32_t ## * Start of message buffer
    buffer_start* {.importc: "buffer_start".}: cstring ## * End of message buffer
    buffer_end* {.importc: "buffer_end".}: cstring ## * Read pointer
    read_ptr* {.importc: "read_ptr".}: cstring ## * Write pointer
    write_ptr* {.importc: "write_ptr".}: cstring ## * Number of used messages
    used_msgs* {.importc: "used_msgs".}: uint32_t
    poll_events* {.importc: "poll_events".}: sys_dlist_t ##  _POLL_EVENT;
                                                      ## * Message queue
    flags* {.importc: "flags".}: uint8_t

## *
##  @cond INTERNAL_HIDDEN
##
proc Z_MSGQ_INITIALIZER*(obj: untyped; q_buffer: untyped; q_msg_size: untyped;
                        q_max_msgs: untyped) {.importc: "Z_MSGQ_INITIALIZER",
    header: "kernel.h".}
## *
##  INTERNAL_HIDDEN @endcond
##
var K_MSGQ_FLAG_ALLOC* {.importc: "K_MSGQ_FLAG_ALLOC", header: "kernel.h".}: int
## *
##  @brief Message Queue Attributes
##
type
  k_msgq_attrs* {.importc: "k_msgq_attrs", header: "kernel.h", bycopy.} = object
    msg_size* {.importc: "msg_size".}: csize_t ## * Message Size
    ## * Maximal number of messages
    max_msgs* {.importc: "max_msgs".}: uint32_t ## * Used messages
    used_msgs* {.importc: "used_msgs".}: uint32_t

## *
##  @brief Statically define and initialize a message queue.
##
##  The message queue's ring buffer contains space for @a q_max_msgs messages,
##  each of which is @a q_msg_size bytes long. The buffer is aligned to a
##  @a q_align -byte boundary, which must be a power of 2. To ensure that each
##  message is similarly aligned to this boundary, @a q_msg_size must also be
##  a multiple of @a q_align.
##
##  The message queue can be accessed outside the module where it is defined
##  using:
##
##  @code extern struct k_msgq <name>; @endcode
##
##  @param q_name Name of the message queue.
##  @param q_msg_size Message size (in bytes).
##  @param q_max_msgs Maximum number of messages that can be queued.
##  @param q_align Alignment of the message queue's ring buffer.
##
##
proc K_MSGQ_DEFINE*(q_name: untyped; q_msg_size: untyped; q_max_msgs: untyped;
                    q_align: untyped) {.importc: "K_MSGQ_DEFINE",
                                      header: "kernel.h".}
## *
##  @brief Initialize a message queue.
##
##  This routine initializes a message queue object, prior to its first use.
##
##  The message queue's ring buffer must contain space for @a max_msgs messages,
##  each of which is @a msg_size bytes long. The buffer must be aligned to an
##  N-byte boundary, where N is a power of 2 (i.e. 1, 2, 4, ...). To ensure
##  that each message is similarly aligned to this boundary, @a q_msg_size
##  must also be a multiple of N.
##
##  @param msgq Address of the message queue.
##  @param buffer Pointer to ring buffer that holds queued messages.
##  @param msg_size Message size (in bytes).
##  @param max_msgs Maximum number of messages that can be queued.
##
##  @return N/A
##
proc k_msgq_init*(msgq: ptr k_msgq; buffer: cstring; msg_size: csize_t;
                  max_msgs: uint32_t) {.importc: "k_msgq_init", header: "kernel.h".}
## *
##  @brief Initialize a message queue.
##
##  This routine initializes a message queue object, prior to its first use,
##  allocating its internal ring buffer from the calling thread's resource
##  pool.
##
##  Memory allocated for the ring buffer can be released by calling
##  k_msgq_cleanup(), or if userspace is enabled and the msgq object loses
##  all of its references.
##
##  @param msgq Address of the message queue.
##  @param msg_size Message size (in bytes).
##  @param max_msgs Maximum number of messages that can be queued.
##
##  @return 0 on success, -ENOMEM if there was insufficient memory in the
## 	thread's resource pool, or -EINVAL if the size parameters cause
## 	an integer overflow.
##
proc k_msgq_alloc_init*(msgq: ptr k_msgq; msg_size: csize_t; max_msgs: uint32_t): cint {.
    syscall, importc: "k_msgq_alloc_init", header: "kernel.h".}
## *
##  @brief Release allocated buffer for a queue
##
##  Releases memory allocated for the ring buffer.
##
##  @param msgq message queue to cleanup
##
##  @retval 0 on success
##  @retval -EBUSY Queue not empty
##
proc k_msgq_cleanup*(msgq: ptr k_msgq): cint {.importc: "k_msgq_cleanup",
    header: "kernel.h".}
## *
##  @brief Send a message to a message queue.
##
##  This routine sends a message to message queue @a q.
##
##  @note The message content is copied from @a data into @a msgq and the @a data
##  pointer is not retained, so the message content will not be modified
##  by this function.
##
##  @funcprops \isr_ok
##
##  @param msgq Address of the message queue.
##  @param data Pointer to the message.
##  @param timeout Non-negative waiting period to add the message,
##                 or one of the special values K_NO_WAIT and
##                 K_FOREVER.
##
##  @retval 0 Message sent.
##  @retval -ENOMSG Returned without waiting or queue purged.
##  @retval -EAGAIN Waiting period timed out.
##
proc k_msgq_put*(msgq: ptr k_msgq; data: pointer; timeout: k_timeout_t): cint {.
    syscall, importc: "k_msgq_put", header: "kernel.h".}
## *
##  @brief Receive a message from a message queue.
##
##  This routine receives a message from message queue @a q in a "first in,
##  first out" manner.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##
##  @funcprops \isr_ok
##
##  @param msgq Address of the message queue.
##  @param data Address of area to hold the received message.
##  @param timeout Waiting period to receive the message,
##                 or one of the special values K_NO_WAIT and
##                 K_FOREVER.
##
##  @retval 0 Message received.
##  @retval -ENOMSG Returned without waiting.
##  @retval -EAGAIN Waiting period timed out.
##
proc k_msgq_get*(msgq: ptr k_msgq; data: pointer; timeout: k_timeout_t): cint {.
    syscall, importc: "k_msgq_get", header: "kernel.h".}
## *
##  @brief Peek/read a message from a message queue.
##
##  This routine reads a message from message queue @a q in a "first in,
##  first out" manner and leaves the message in the queue.
##
##  @funcprops \isr_ok
##
##  @param msgq Address of the message queue.
##  @param data Address of area to hold the message read from the queue.
##
##  @retval 0 Message read.
##  @retval -ENOMSG Returned when the queue has no message.
##
proc k_msgq_peek*(msgq: ptr k_msgq; data: pointer): cint {.syscall,
    importc: "k_msgq_peek", header: "kernel.h".}
## *
##  @brief Purge a message queue.
##
##  This routine discards all unreceived messages in a message queue's ring
##  buffer. Any threads that are blocked waiting to send a message to the
##  message queue are unblocked and see an -ENOMSG error code.
##
##  @param msgq Address of the message queue.
##
##  @return N/A
##
proc k_msgq_purge*(msgq: ptr k_msgq) {.syscall, importc: "k_msgq_purge",
                                    header: "kernel.h".}
## *
##  @brief Get the amount of free space in a message queue.
##
##  This routine returns the number of unused entries in a message queue's
##  ring buffer.
##
##  @param msgq Address of the message queue.
##
##  @return Number of unused ring buffer entries.
##
proc k_msgq_num_free_get*(msgq: ptr k_msgq): uint32_t {.syscall,
    importc: "k_msgq_num_free_get", header: "kernel.h".}
## *
##  @brief Get basic attributes of a message queue.
##
##  This routine fetches basic attributes of message queue into attr argument.
##
##  @param msgq Address of the message queue.
##  @param attrs pointer to message queue attribute structure.
##
##  @return N/A
##
proc k_msgq_get_attrs*(msgq: ptr k_msgq; attrs: ptr k_msgq_attrs) {.syscall,
    importc: "k_msgq_get_attrs", header: "kernel.h".}
proc z_impl_k_msgq_num_free_get*(msgq: ptr k_msgq): uint32_t {.inline.} =
  return msgq.max_msgs - msgq.used_msgs

## *
##  @brief Get the number of messages in a message queue.
##
##  This routine returns the number of messages in a message queue's ring buffer.
##
##  @param msgq Address of the message queue.
##
##  @return Number of messages.
##
proc k_msgq_num_used_get*(msgq: ptr k_msgq): uint32_t {.syscall,
    importc: "k_msgq_num_used_get", header: "kernel.h".}
proc z_impl_k_msgq_num_used_get*(msgq: ptr k_msgq): uint32_t {.inline.} =
  return msgq.used_msgs

## * @}
## *
##  @defgroup mailbox_apis Mailbox APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Mailbox Message Structure
##
##
type
  k_mbox_msg* {.importc: "k_mbox_msg", header: "kernel.h", bycopy.} = object
    _mailbox* {.importc: "_mailbox".}: uint32_t ## * internal use only - needed for legacy API support
    ## * size of message (in bytes)
    size* {.importc: "size".}: csize_t ## * application-defined information value
    info* {.importc: "info".}: uint32_t ## * sender's message data buffer
    tx_data* {.importc: "tx_data".}: pointer ## * internal use only - needed for legacy API support
    _rx_data* {.importc: "_rx_data".}: pointer ## * message data block descriptor
    tx_block* {.importc: "tx_block".}: k_mem_block ## * source thread id
    rx_source_thread* {.importc: "rx_source_thread".}: k_tid_t ## * target thread id
    tx_target_thread* {.importc: "tx_target_thread".}: k_tid_t ## * internal use only - thread waiting on send (may be a dummy)
    _syncing_thread* {.importc: "_syncing_thread".}: k_tid_t
    when (CONFIG_NUM_MBOX_ASYNC_MSGS > 0):
      ## * internal use only - semaphore used during asynchronous send
      var _async_sem* {.importc: "_async_sem", header: "kernel.h".}: ptr k_sem

## *
##  @brief Mailbox Structure
##
##
type
  k_mbox* {.importc: "k_mbox", header: "kernel.h", bycopy.} = object
    tx_msg_queue* {.importc: "tx_msg_queue".}: _wait_q_t ## * Transmit messages queue
    ## * Receive message queue
    rx_msg_queue* {.importc: "rx_msg_queue".}: _wait_q_t
    lock* {.importc: "lock".}: k_spinlock

## *
##  @cond INTERNAL_HIDDEN
##
proc Z_MBOX_INITIALIZER*(obj: untyped) {.importc: "Z_MBOX_INITIALIZER",
                                      header: "kernel.h".}
## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @brief Statically define and initialize a mailbox.
##
##  The mailbox is to be accessed outside the module where it is defined using:
##
##  @code extern struct k_mbox <name>; @endcode
##
##  @param name Name of the mailbox.
##
proc K_MBOX_DEFINE*(name: untyped) {.importc: "K_MBOX_DEFINE", header: "kernel.h".}
## *
##  @brief Initialize a mailbox.
##
##  This routine initializes a mailbox object, prior to its first use.
##
##  @param mbox Address of the mailbox.
##
##  @return N/A
##
proc k_mbox_init*(mbox: ptr k_mbox) {.importc: "k_mbox_init", header: "kernel.h".}
## *
##  @brief Send a mailbox message in a synchronous manner.
##
##  This routine sends a message to @a mbox and waits for a receiver to both
##  receive and process it. The message data may be in a buffer, in a memory
##  pool block, or non-existent (i.e. an empty message).
##
##  @param mbox Address of the mailbox.
##  @param tx_msg Address of the transmit message descriptor.
##  @param timeout Waiting period for the message to be received,
##                 or one of the special values K_NO_WAIT
##                 and K_FOREVER. Once the message has been received,
##                 this routine waits as long as necessary for the message
##                 to be completely processed.
##
##  @retval 0 Message sent.
##  @retval -ENOMSG Returned without waiting.
##  @retval -EAGAIN Waiting period timed out.
##
proc k_mbox_put*(mbox: ptr k_mbox; tx_msg: ptr k_mbox_msg; timeout: k_timeout_t): cint {.
    importc: "k_mbox_put", header: "kernel.h".}
## *
##  @brief Send a mailbox message in an asynchronous manner.
##
##  This routine sends a message to @a mbox without waiting for a receiver
##  to process it. The message data may be in a buffer, in a memory pool block,
##  or non-existent (i.e. an empty message). Optionally, the semaphore @a sem
##  will be given when the message has been both received and completely
##  processed by the receiver.
##
##  @param mbox Address of the mailbox.
##  @param tx_msg Address of the transmit message descriptor.
##  @param sem Address of a semaphore, or NULL if none is needed.
##
##  @return N/A
##
proc k_mbox_async_put*(mbox: ptr k_mbox; tx_msg: ptr k_mbox_msg; sem: ptr k_sem) {.
    importc: "k_mbox_async_put", header: "kernel.h".}
## *
##  @brief Receive a mailbox message.
##
##  This routine receives a message from @a mbox, then optionally retrieves
##  its data and disposes of the message.
##
##  @param mbox Address of the mailbox.
##  @param rx_msg Address of the receive message descriptor.
##  @param buffer Address of the buffer to receive data, or NULL to defer data
##                retrieval and message disposal until later.
##  @param timeout Waiting period for a message to be received,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @retval 0 Message received.
##  @retval -ENOMSG Returned without waiting.
##  @retval -EAGAIN Waiting period timed out.
##
proc k_mbox_get*(mbox: ptr k_mbox; rx_msg: ptr k_mbox_msg; buffer: pointer;
                timeout: k_timeout_t): cint {.importc: "k_mbox_get",
    header: "kernel.h".}
## *
##  @brief Retrieve mailbox message data into a buffer.
##
##  This routine completes the processing of a received message by retrieving
##  its data into a buffer, then disposing of the message.
##
##  Alternatively, this routine can be used to dispose of a received message
##  without retrieving its data.
##
##  @param rx_msg Address of the receive message descriptor.
##  @param buffer Address of the buffer to receive data, or NULL to discard
##                the data.
##
##  @return N/A
##
proc k_mbox_data_get*(rx_msg: ptr k_mbox_msg; buffer: pointer) {.
    importc: "k_mbox_data_get", header: "kernel.h".}
## * @}
## *
##  @defgroup pipe_apis Pipe APIs
##  @ingroup kernel_apis
##  @{
##
## * Pipe Structure
type
  INNER_C_STRUCT_kernel_2* {.importc: "no_name", header: "kernel.h", bycopy.} = object
    readers* {.importc: "readers".}: _wait_q_t ## *< Reader wait queue
    writers* {.importc: "writers".}: _wait_q_t ## *< Writer wait queue

type
  k_pipe* {.importc: "k_pipe", header: "kernel.h", bycopy.} = object
    buffer* {.importc: "buffer".}: ptr cuchar ## *< Pipe buffer: may be NULL
    size* {.importc: "size".}: csize_t ## *< Buffer size
    bytes_used* {.importc: "bytes_used".}: csize_t ## *< # bytes used in buffer
    read_index* {.importc: "read_index".}: csize_t ## *< Where in buffer to read from
    write_index* {.importc: "write_index".}: csize_t ## *< Where in buffer to write
    lock* {.importc: "lock".}: k_spinlock ## *< Synchronization lock
    wait_q* {.importc: "wait_q".}: INNER_C_STRUCT_kernel_2 ## * Wait queue
    flags* {.importc: "flags".}: uint8_t ## *< Flags

## *
##  @cond INTERNAL_HIDDEN
##
var K_PIPE_FLAG_ALLOC* {.importc: "K_PIPE_FLAG_ALLOC", header: "kernel.h".}: int
proc Z_PIPE_INITIALIZER*(obj: untyped; pipe_buffer: untyped;
                        pipe_buffer_size: untyped) {.
    importc: "Z_PIPE_INITIALIZER", header: "kernel.h".}
## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @brief Statically define and initialize a pipe.
##
##  The pipe can be accessed outside the module where it is defined using:
##
##  @code extern struct k_pipe <name>; @endcode
##
##  @param name Name of the pipe.
##  @param pipe_buffer_size Size of the pipe's ring buffer (in bytes),
##                          or zero if no ring buffer is used.
##  @param pipe_align Alignment of the pipe's ring buffer (power of 2).
##
##
proc K_PIPE_DEFINE*(name: untyped; pipe_buffer_size: untyped; pipe_align: untyped) {.
    importc: "K_PIPE_DEFINE", header: "kernel.h".}
## *
##  @brief Initialize a pipe.
##
##  This routine initializes a pipe object, prior to its first use.
##
##  @param pipe Address of the pipe.
##  @param buffer Address of the pipe's ring buffer, or NULL if no ring buffer
##                is used.
##  @param size Size of the pipe's ring buffer (in bytes), or zero if no ring
##              buffer is used.
##
##  @return N/A
##
proc k_pipe_init*(pipe: ptr k_pipe; buffer: ptr cuchar; size: csize_t) {.
    importc: "k_pipe_init", header: "kernel.h".}
## *
##  @brief Release a pipe's allocated buffer
##
##  If a pipe object was given a dynamically allocated buffer via
##  k_pipe_alloc_init(), this will free it. This function does nothing
##  if the buffer wasn't dynamically allocated.
##
##  @param pipe Address of the pipe.
##  @retval 0 on success
##  @retval -EAGAIN nothing to cleanup
##
proc k_pipe_cleanup*(pipe: ptr k_pipe): cint {.importc: "k_pipe_cleanup",
    header: "kernel.h".}
## *
##  @brief Initialize a pipe and allocate a buffer for it
##
##  Storage for the buffer region will be allocated from the calling thread's
##  resource pool. This memory will be released if k_pipe_cleanup() is called,
##  or userspace is enabled and the pipe object loses all references to it.
##
##  This function should only be called on uninitialized pipe objects.
##
##  @param pipe Address of the pipe.
##  @param size Size of the pipe's ring buffer (in bytes), or zero if no ring
##              buffer is used.
##  @retval 0 on success
##  @retval -ENOMEM if memory couldn't be allocated
##
proc k_pipe_alloc_init*(pipe: ptr k_pipe; size: csize_t): cint {.syscall,
    importc: "k_pipe_alloc_init", header: "kernel.h".}
## *
##  @brief Write data to a pipe.
##
##  This routine writes up to @a bytes_to_write bytes of data to @a pipe.
##
##  @param pipe Address of the pipe.
##  @param data Address of data to write.
##  @param bytes_to_write Size of data (in bytes).
##  @param bytes_written Address of area to hold the number of bytes written.
##  @param min_xfer Minimum number of bytes to write.
##  @param timeout Waiting period to wait for the data to be written,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @retval 0 At least @a min_xfer bytes of data were written.
##  @retval -EIO Returned without waiting; zero data bytes were written.
##  @retval -EAGAIN Waiting period timed out; between zero and @a min_xfer
##                  minus one data bytes were written.
##
proc k_pipe_put*(pipe: ptr k_pipe; data: pointer; bytes_to_write: csize_t;
                bytes_written: ptr csize_t; min_xfer: csize_t; timeout: k_timeout_t): cint {.
    syscall, importc: "k_pipe_put", header: "kernel.h".}
## *
##  @brief Read data from a pipe.
##
##  This routine reads up to @a bytes_to_read bytes of data from @a pipe.
##
##  @param pipe Address of the pipe.
##  @param data Address to place the data read from pipe.
##  @param bytes_to_read Maximum number of data bytes to read.
##  @param bytes_read Address of area to hold the number of bytes read.
##  @param min_xfer Minimum number of data bytes to read.
##  @param timeout Waiting period to wait for the data to be read,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @retval 0 At least @a min_xfer bytes of data were read.
##  @retval -EINVAL invalid parameters supplied
##  @retval -EIO Returned without waiting; zero data bytes were read.
##  @retval -EAGAIN Waiting period timed out; between zero and @a min_xfer
##                  minus one data bytes were read.
##
proc k_pipe_get*(pipe: ptr k_pipe; data: pointer; bytes_to_read: csize_t;
                bytes_read: ptr csize_t; min_xfer: csize_t; timeout: k_timeout_t): cint {.
    syscall, importc: "k_pipe_get", header: "kernel.h".}
## *
##  @brief Query the number of bytes that may be read from @a pipe.
##
##  @param pipe Address of the pipe.
##
##  @retval a number n such that 0 <= n <= @ref k_pipe.size; the
##          result is zero for unbuffered pipes.
##
proc k_pipe_read_avail*(pipe: ptr k_pipe): csize_t {.syscall,
    importc: "k_pipe_read_avail", header: "kernel.h".}
## *
##  @brief Query the number of bytes that may be written to @a pipe
##
##  @param pipe Address of the pipe.
##
##  @retval a number n such that 0 <= n <= @ref k_pipe.size; the
##          result is zero for unbuffered pipes.
##
proc k_pipe_write_avail*(pipe: ptr k_pipe): csize_t {.syscall,
    importc: "k_pipe_write_avail", header: "kernel.h".}
## * @}
## *
##  @cond INTERNAL_HIDDEN
##
type
  k_mem_slab* {.importc: "k_mem_slab", header: "kernel.h", bycopy.} = object
    wait_q* {.importc: "wait_q".}: _wait_q_t
    lock* {.importc: "lock".}: k_spinlock
    num_blocks* {.importc: "num_blocks".}: uint32_t
    block_size* {.importc: "block_size".}: csize_t
    buffer* {.importc: "buffer".}: cstring
    free_list* {.importc: "free_list".}: cstring
    num_used* {.importc: "num_used".}: uint32_t
    when defined(CONFIG_MEM_SLAB_TRACE_MAX_UTILIZATION):
      var max_used* {.importc: "max_used", header: "kernel.h".}: uint32_t

proc Z_MEM_SLAB_INITIALIZER*(obj: untyped; slab_buffer: untyped;
                            slab_block_size: untyped; slab_num_blocks: untyped) {.
    importc: "Z_MEM_SLAB_INITIALIZER", header: "kernel.h".}
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
proc K_MEM_SLAB_DEFINE*(name: untyped; slab_block_size: untyped;
                        slab_num_blocks: untyped; slab_align: untyped) {.
    importc: "K_MEM_SLAB_DEFINE", header: "kernel.h".}
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
                      num_blocks: uint32_t): cint {.importc: "k_mem_slab_init",
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
proc k_mem_slab_num_used_get*(slab: ptr k_mem_slab): uint32_t {.inline.} =
  return slab.num_used

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
proc k_mem_slab_max_used_get*(slab: ptr k_mem_slab): uint32_t {.inline.} =
  when defined(CONFIG_MEM_SLAB_TRACE_MAX_UTILIZATION):
    return slab.max_used
  else:
    ARG_UNUSED(slab)
    return 0

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
proc k_mem_slab_num_free_get*(slab: ptr k_mem_slab): uint32_t {.inline.} =
  return slab.num_blocks - slab.num_used

## * @}
## *
##  @addtogroup heap_apis
##  @{
##
##  kernel synchronized heap struct
type
  k_heap* {.importc: "k_heap", header: "kernel.h", bycopy.} = object
    heap* {.importc: "heap".}: sys_heap
    wait_q* {.importc: "wait_q".}: _wait_q_t
    lock* {.importc: "lock".}: k_spinlock

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
proc Z_HEAP_DEFINE_IN_SECT*(name: untyped; bytes: untyped; in_section: untyped) {.
    importc: "Z_HEAP_DEFINE_IN_SECT", header: "kernel.h".}
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
proc K_HEAP_DEFINE*(name: untyped; bytes: untyped) {.importc: "K_HEAP_DEFINE",
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
proc K_HEAP_DEFINE_NOCACHE*(name: untyped; bytes: untyped) {.
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
## * @}
##  polling API - PRIVATE
when defined(CONFIG_POLL):
  proc _INIT_OBJ_POLL_EVENT*(obj: untyped) {.importc: "_INIT_OBJ_POLL_EVENT",
      header: "kernel.h".}
else:
  proc _INIT_OBJ_POLL_EVENT*(obj: untyped) {.importc: "_INIT_OBJ_POLL_EVENT",
      header: "kernel.h".}
##  private - types bit positions
type
  _poll_types_bits* {.size: sizeof(cint).} = enum ##  can be used to ignore an event
    _POLL_TYPE_IGNORE,      ##  to be signaled by k_poll_signal_raise()
    _POLL_TYPE_SIGNAL,      ##  semaphore availability
    _POLL_TYPE_SEM_AVAILABLE, ##  queue/FIFO/LIFO data availability
    _POLL_TYPE_DATA_AVAILABLE, ##  msgq data availability
    _POLL_TYPE_MSGQ_DATA_AVAILABLE, _POLL_NUM_TYPES
proc Z_POLL_TYPE_BIT*(`type`: untyped) {.importc: "Z_POLL_TYPE_BIT",
                                      header: "kernel.h".}
##  private - states bit positions
type
  _poll_states_bits* {.size: sizeof(cint).} = enum ##  default state when creating event
    _POLL_STATE_NOT_READY,  ##  signaled by k_poll_signal_raise()
    _POLL_STATE_SIGNALED,   ##  semaphore is available
    _POLL_STATE_SEM_AVAILABLE, ##  data is available to read on queue/FIFO/LIFO
    _POLL_STATE_DATA_AVAILABLE, ##  queue/FIFO/LIFO wait was cancelled
    _POLL_STATE_CANCELLED,  ##  data is available to read on a message queue
    _POLL_STATE_MSGQ_DATA_AVAILABLE, _POLL_NUM_STATES
proc Z_POLL_STATE_BIT*(state: untyped) {.importc: "Z_POLL_STATE_BIT",
                                      header: "kernel.h".}
var _POLL_EVENT_NUM_UNUSED_BITS* {.importc: "_POLL_EVENT_NUM_UNUSED_BITS",
                                  header: "kernel.h".}: int
##  end of polling API - PRIVATE
## *
##  @defgroup poll_apis Async polling APIs
##  @ingroup kernel_apis
##  @{
##
##  Public polling API
##  public - values for k_poll_event.type bitfield
var K_POLL_TYPE_IGNORE* {.importc: "K_POLL_TYPE_IGNORE", header: "kernel.h".}: int
##  public - polling modes
type
  k_poll_modes* {.size: sizeof(cint).} = enum ##  polling thread does not take ownership of objects when available
    K_POLL_MODE_NOTIFY_ONLY = 0, K_POLL_NUM_MODES
##  public - values for k_poll_event.state bitfield
var K_POLL_STATE_NOT_READY* {.importc: "K_POLL_STATE_NOT_READY",
                            header: "kernel.h".}: int
##  public - poll signal object
type
  k_poll_signal* {.importc: "k_poll_signal", header: "kernel.h", bycopy.} = object
    poll_events* {.importc: "poll_events".}: sys_dlist_t ## * PRIVATE - DO NOT TOUCH
    ## *
    ##  1 if the event has been signaled, 0 otherwise. Stays set to 1 until
    ##  user resets it to 0.
    ##
    signaled* {.importc: "signaled".}: cuint ## * custom result value passed to k_poll_signal_raise() if needed
    result* {.importc: "result".}: cint

proc K_POLL_SIGNAL_INITIALIZER*(obj: untyped) {.
    importc: "K_POLL_SIGNAL_INITIALIZER", header: "kernel.h".}
## *
##  @brief Poll Event
##
##
discard "forward decl of k_poll_event"
proc K_POLL_EVENT_INITIALIZER*(_event_type: untyped; _event_mode: untyped;
                              _event_obj: untyped) {.
    importc: "K_POLL_EVENT_INITIALIZER", header: "kernel.h".}
proc K_POLL_EVENT_STATIC_INITIALIZER*(_event_type: untyped; _event_mode: untyped;
                                      _event_obj: untyped; event_tag: untyped) {.
    importc: "K_POLL_EVENT_STATIC_INITIALIZER", header: "kernel.h".}
## *
##  @brief Initialize one struct k_poll_event instance
##
##  After this routine is called on a poll event, the event it ready to be
##  placed in an event array to be passed to k_poll().
##
##  @param event The event to initialize.
##  @param type A bitfield of the types of event, from the K_POLL_TYPE_xxx
##              values. Only values that apply to the same object being polled
##              can be used together. Choosing K_POLL_TYPE_IGNORE disables the
##              event.
##  @param mode Future. Use K_POLL_MODE_NOTIFY_ONLY.
##  @param obj Kernel object or poll signal.
##
##  @return N/A
##
proc k_poll_event_init*(event: ptr k_poll_event; `type`: uint32_t; mode: cint;
                        obj: pointer) {.importc: "k_poll_event_init",
                                      header: "kernel.h".}
## *
##  @brief Wait for one or many of multiple poll events to occur
##
##  This routine allows a thread to wait concurrently for one or many of
##  multiple poll events to have occurred. Such events can be a kernel object
##  being available, like a semaphore, or a poll signal event.
##
##  When an event notifies that a kernel object is available, the kernel object
##  is not "given" to the thread calling k_poll(): it merely signals the fact
##  that the object was available when the k_poll() call was in effect. Also,
##  all threads trying to acquire an object the regular way, i.e. by pending on
##  the object, have precedence over the thread polling on the object. This
##  means that the polling thread will never get the poll event on an object
##  until the object becomes available and its pend queue is empty. For this
##  reason, the k_poll() call is more effective when the objects being polled
##  only have one thread, the polling thread, trying to acquire them.
##
##  When k_poll() returns 0, the caller should loop on all the events that were
##  passed to k_poll() and check the state field for the values that were
##  expected and take the associated actions.
##
##  Before being reused for another call to k_poll(), the user has to reset the
##  state field to K_POLL_STATE_NOT_READY.
##
##  When called from user mode, a temporary memory allocation is required from
##  the caller's resource pool.
##
##  @param events An array of events to be polled for.
##  @param num_events The number of events in the array.
##  @param timeout Waiting period for an event to be ready,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @retval 0 One or more events are ready.
##  @retval -EAGAIN Waiting period timed out.
##  @retval -EINTR Polling has been interrupted, e.g. with
##          k_queue_cancel_wait(). All output events are still set and valid,
##          cancelled event(s) will be set to K_POLL_STATE_CANCELLED. In other
##          words, -EINTR status means that at least one of output events is
##          K_POLL_STATE_CANCELLED.
##  @retval -ENOMEM Thread resource pool insufficient memory (user mode only)
##  @retval -EINVAL Bad parameters (user mode only)
##
proc k_poll*(events: ptr k_poll_event; num_events: cint; timeout: k_timeout_t): cint {.
    syscall, importc: "k_poll", header: "kernel.h".}
## *
##  @brief Initialize a poll signal object.
##
##  Ready a poll signal object to be signaled via k_poll_signal_raise().
##
##  @param sig A poll signal.
##
##  @return N/A
##
proc k_poll_signal_init*(sig: ptr k_poll_signal) {.syscall,
    importc: "k_poll_signal_init", header: "kernel.h".}
##
##  @brief Reset a poll signal object's state to unsignaled.
##
##  @param sig A poll signal object
##
proc k_poll_signal_reset*(sig: ptr k_poll_signal) {.syscall,
    importc: "k_poll_signal_reset", header: "kernel.h".}
## *
##  @brief Fetch the signaled state and result value of a poll signal
##
##  @param sig A poll signal object
##  @param signaled An integer buffer which will be written nonzero if the
## 		   object was signaled
##  @param result An integer destination buffer which will be written with the
## 		   result value if the object was signaled, or an undefined
## 		   value if it was not.
##
proc k_poll_signal_check*(sig: ptr k_poll_signal; signaled: ptr cuint;
                          result: ptr cint) {.syscall,
    importc: "k_poll_signal_check", header: "kernel.h".}
## *
##  @brief Signal a poll signal object.
##
##  This routine makes ready a poll signal, which is basically a poll event of
##  type K_POLL_TYPE_SIGNAL. If a thread was polling on that event, it will be
##  made ready to run. A @a result value can be specified.
##
##  The poll signal contains a 'signaled' field that, when set by
##  k_poll_signal_raise(), stays set until the user sets it back to 0 with
##  k_poll_signal_reset(). It thus has to be reset by the user before being
##  passed again to k_poll() or k_poll() will consider it being signaled, and
##  will return immediately.
##
##  @note The result is stored and the 'signaled' field is set even if
##  this function returns an error indicating that an expiring poll was
##  not notified.  The next k_poll() will detect the missed raise.
##
##  @param sig A poll signal.
##  @param result The value to store in the result field of the signal.
##
##  @retval 0 The signal was delivered successfully.
##  @retval -EAGAIN The polling thread's timeout is in the process of expiring.
##
proc k_poll_signal_raise*(sig: ptr k_poll_signal; result: cint): cint {.syscall,
    importc: "k_poll_signal_raise", header: "kernel.h".}
## *
##  @internal
##
proc z_handle_obj_poll_events*(events: ptr sys_dlist_t; state: uint32_t) {.
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
proc k_cpu_idle*() {.inline.} =
  arch_cpu_idle()

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
proc k_cpu_atomic_idle*(key: cuint) {.inline.} =
  arch_cpu_atomic_idle(key)

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
  ##  NOTE: This is the implementation for arches that do not implement
  ##  ARCH_EXCEPT() to generate a real CPU exception.
  ##
  ##  We won't have a real exception frame to determine the PC value when
  ##  the oops occurred, so print file and line number before we jump into
  ##  the fatal error handler.
  ##
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
proc z_init_thread_base*(thread_base: ptr _thread_base; priority: cint;
                        initial_state: uint32_t; options: cuint) {.
    importc: "z_init_thread_base", header: "kernel.h".}
when defined(CONFIG_MULTITHREADING):
  ## *
  ##  @internal
  ##
  proc z_init_static_threads*() {.importc: "z_init_static_threads",
                                header: "kernel.h".}
else:
  ## *
  ##  @internal
  ##
  proc z_init_static_threads*() {.importc: "z_init_static_threads",
                                header: "kernel.h".}
## *
##  @internal
##
proc z_is_thread_essential*(): bool {.importc: "z_is_thread_essential",
                                    header: "kernel.h".}
when defined(CONFIG_SMP):
  proc z_smp_thread_init*(arg: pointer; thread: ptr k_thread) {.
      importc: "z_smp_thread_init", header: "kernel.h".}
  proc z_smp_thread_swap*() {.importc: "z_smp_thread_swap", header: "kernel.h".}
## *
##  @internal
##
proc z_timer_expiration_handler*(t: ptr _timeout) {.
    importc: "z_timer_expiration_handler", header: "kernel.h".}
when defined(CONFIG_PRINTK):
  ## *
  ##  @brief Emit a character buffer to the console device
  ##
  ##  @param c String of characters to print
  ##  @param n The length of the string
  ##
  ##
  proc k_str_out*(c: cstring; n: csize_t) {.syscall, importc: "k_str_out",
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
proc k_float_disable*(thread: ptr k_thread): cint {.syscall,
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
proc k_float_enable*(thread: ptr k_thread; options: cuint): cint {.syscall,
    importc: "k_float_enable", header: "kernel.h".}
when defined(CONFIG_THREAD_RUNTIME_STATS):
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