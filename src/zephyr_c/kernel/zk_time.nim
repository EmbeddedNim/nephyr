
import ../zconfs
import ../zkernel_fixes
import ../zsys_clock

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
var K_FOREVER* {.importc: "K_FOREVER", header: "kernel.h".}: k_timeout_t


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

  k_timer* {.importc: "struct k_timer", header: "kernel.h", bycopy.} = object
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

