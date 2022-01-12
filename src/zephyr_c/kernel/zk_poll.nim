
import ../zconfs
import ../zkernel_fixes
import ../zsys_clock

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
  k_poll_modes* {.size: sizeof(cint).} = enum
    ##  polling thread does not take ownership of objects when available
    K_POLL_MODE_NOTIFY_ONLY = 0, K_POLL_NUM_MODES


  k_poll_event* {.importc: "k_poll_event", header: "1.c", incompleteStruct, bycopy.} = object
    # node* {.importc: "_node".}: sys_dnode_t ## * PRIVATE - DO NOT TOUCH
    # poller* {.importc: "poller".}: ptr z_poller ## * PRIVATE - DO NOT TOUCH
    tag* {.importc: "tag", bitsize: 8.}: uint32 ## * optional user-specified tag, opaque, untouched by the API
    poll_num_types* {.importc: "_POLL_NUM_TYPES".}: uint32 ## * bitfield of event types (bitwise-ORed K_POLL_TYPE_xxx values)
    poll_num_states* {.importc: "_POLL_NUM_STATES".}: uint32 ## * bitfield of event states (bitwise-ORed K_POLL_STATE_xxx values)
    mode* {.importc: "mode".}: uint32 ## * mode of operation, from enum k_poll_modes
    poll_event_num_unused_bits* {.importc: "_POLL_EVENT_NUM_UNUSED_BITS".}: uint32 ##\
      ## * ## unused ## bits ## in ## 32-bit ## word
    
    # Anonymous C Union
    obj* {.importc: "obj".}: pointer
    # signal* {.importc: "signal".}: ptr k_poll_signal
    # sem* {.importc: "sem".}: ptr k_sem
    # fifo* {.importc: "fifo".}: ptr k_fifo
    # queue* {.importc: "queue".}: ptr k_queue
    # msgq* {.importc: "msgq".}: ptr k_msgq
    # End Anonymous C Union

var K_POLL_STATE_NOT_READY* {.importc: "K_POLL_STATE_NOT_READY",
                            header: "kernel.h".}: int ##  public - values for k_poll_event.state bitfield

##  public - poll signal object
type
  k_poll_signal* {.importc: "k_poll_signal", header: "kernel.h", incompleteStruct, bycopy.} = object
    poll_events {.importc: "poll_events".}: sys_dlist_t ## * PRIVATE - DO NOT TOUCH
    signaled* {.importc: "signaled".}: cuint ## *\
    ##  1 if the event has been signaled, 0 otherwise. Stays set to 1 until
    ##  user resets it to 0.
    result* {.importc: "result".}: cint ## * custom result value passed to k_poll_signal_raise() if needed

proc K_POLL_SIGNAL_INITIALIZER*(obj: k_poll_signal) {.
    importc: "K_POLL_SIGNAL_INITIALIZER", header: "kernel.h".}


## *
##  @brief Poll Event
##
##

# proc K_POLL_EVENT_INITIALIZER*(z_event_type: untyped; z_event_mode: untyped;
                              # z_event_obj: untyped) {.
    # importc: "K_POLL_EVENT_INITIALIZER", header: "kernel.h".}

# proc K_POLL_EVENT_STATIC_INITIALIZER*(_event_type: untyped; _event_mode: untyped;
                                      # _event_obj: untyped; event_tag: untyped) {.
    # importc: "K_POLL_EVENT_STATIC_INITIALIZER", header: "kernel.h".}


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
proc k_poll_event_init*(event: ptr k_poll_event; `type`: uint32; mode: cint;
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
    zsyscall, importc: "k_poll", header: "kernel.h".}


## *
##  @brief Initialize a poll signal object.
##
##  Ready a poll signal object to be signaled via k_poll_signal_raise().
##
##  @param sig A poll signal.
##
##  @return N/A
##
proc k_poll_signal_init*(sig: ptr k_poll_signal) {.zsyscall,
    importc: "k_poll_signal_init", header: "kernel.h".}
##
##  @brief Reset a poll signal object's state to unsignaled.
##
##  @param sig A poll signal object
##
proc k_poll_signal_reset*(sig: ptr k_poll_signal) {.zsyscall,
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
                          result: ptr cint) {.zsyscall,
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
proc k_poll_signal_raise*(sig: ptr k_poll_signal; result: cint): cint {.zsyscall,
    importc: "k_poll_signal_raise", header: "kernel.h".}
