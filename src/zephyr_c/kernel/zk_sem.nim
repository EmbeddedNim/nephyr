import ../zkernel_fixes
import ../zsys_clock

type

  k_sem* {.importc: "k_sem", header: "kernel.h", incompleteStruct, bycopy.} = object
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    count* {.importc: "count".}: cuint
    limit* {.importc: "limit".}: cuint
    poll_events* {.importc: "poll_events".}: sys_dlist_t ##  _POLL_EVENT;


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
