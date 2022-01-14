
import ../zconfs
import ../zkernel_fixes
import ../zsys_clock
import ../zthread

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
