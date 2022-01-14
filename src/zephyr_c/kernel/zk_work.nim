
import ../zkernel_fixes
import ../zsys_clock
import ../zthread
import ../zatomic
import zk_sem
import zk_queue
import zk_poll

type

  k_work* {.importc: "k_work", header: "kernel.h", bycopy.} = object
    ## * @brief A structure used to submit work.
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
    flags* {.importc: "flags".}: uint32

  k_work_queue_config* {.importc: "k_work_queue_config", header: "kernel.h", bycopy.} = object
    ## * @brief A structure holding optional configuration items for a work
    ##  queue.
    ##
    ##  This structure, and values it references, are not retained by
    ##  k_work_queue_start().
    ##
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

  k_work_q* {.importc: "k_work_q", header: "kernel.h", bycopy.} = object
    ## * @brief A structure used to hold work until it can be processed.
    thread* {.importc: "thread".}: k_thread ##  The thread that animates the work.
    ##  All the following fields must be accessed only while the
    ##  work module spinlock is held.
    ##
    ##  List of k_work items to be worked.
    pending* {.importc: "pending".}: sys_slist_t ##  Wait queue for idle work thread.
    notifyq* {.importc: "notifyq".}: z_wait_q_t ##  Wait queue for threads waiting for the queue to drain.
    drainq* {.importc: "drainq".}: z_wait_q_t ##  Flags describing queue state.
    flags* {.importc: "flags".}: uint32

  k_delayed_work * {.importc: "_timeout", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_work_handler_t* = proc (work: ptr k_work) {.cdecl.}

  z_work_flusher* {.importc: "z_work_flusher", header: "kernel.h", bycopy.} = object
    ##  Record used to wait for work to flush.
    ##
    ##  The work item is inserted into the queue that will process (or is
    ##  processing) the item, and will be processed as soon as the item
    ##  completes.  When the flusher is processed the semaphore will be
    ##  signaled, releasing the thread waiting for the flush.
    work* {.importc: "work".}: k_work
    sem* {.importc: "sem".}: k_sem

  z_work_canceller* {.importc: "z_work_canceller", header: "kernel.h", bycopy.} = object
    ##  Record used to wait for work to complete a cancellation.
    ##
    ##  The work item is inserted into a global queue of pending cancels.
    ##  When a cancelling work item goes idle any matching waiters are
    ##  removed from pending_cancels and are woken.
    ##
    node* {.importc: "node".}: sys_snode_t
    work* {.importc: "work".}: ptr k_work
    sem* {.importc: "sem".}: k_sem

  k_work_delayable* {.importc: "k_work_delayable", header: "kernel.h", bycopy.} = object
    ## * @brief A structure used to submit work after a delay.
    work* {.importc: "work".}: k_work ##  The work item.
    ##  Timeout used to submit work after a delay.
    timeout* {.importc: "timeout".}: k_priv_timeout ##  The queue to which the work should be submitted.
    queue* {.importc: "queue".}: ptr k_work_q

  k_work_user* {.importc: "k_work_user", header: "kernel.h", incompleteStruct, bycopy.} = object
    # k_reserved* {.importc: "_reserved".}: pointer ##  Used by k_queue implementation.
    handler* {.importc: "handler".}: k_work_user_handler_t
    flags* {.importc: "flags".}: atomic_t

  k_work_poll* {.importc: "k_work_poll", header: "kernel.h", bycopy.} = object
    work* {.importc: "work".}: k_work
    workq* {.importc: "workq".}: ptr k_work_q
    poller* {.importc: "poller".}: z_poller
    events* {.importc: "events".}: ptr k_poll_event
    num_events* {.importc: "num_events".}: cint
    real_handler* {.importc: "real_handler".}: k_work_handler_t
    timeout* {.importc: "timeout".}: k_priv_timeout
    poll_result* {.importc: "poll_result".}: cint
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

  k_work_sync* {.importc: "k_work_sync", header: "kernel.h", incompleteStruct, bycopy.} = object
    # C union
    flusher* {.importc: "flusher".}: z_work_flusher # union 1
    canceller* {.importc: "canceller".}: z_work_canceller # union 2
    # end c union

  k_work_user_handler_t* = proc (work: ptr k_work_user)

  k_work_user_q* {.importc: "k_work_user_q", header: "kernel.h", bycopy.} = object
    queue* {.importc: "queue".}: k_queue
    thread* {.importc: "thread".}: k_thread

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


# proc Z_WORK_INITIALIZER*(work_handler: untyped) {.importc: "Z_WORK_INITIALIZER",
    # header: "kernel.h".}


# proc Z_WORK_DELAYABLE_INITIALIZER*(work_handler: untyped) {.
    # importc: "Z_WORK_DELAYABLE_INITIALIZER", header: "kernel.h".}


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
# proc K_WORK_DELAYABLE_DEFINE*(work: untyped; work_handler: untyped) {.
    # importc: "K_WORK_DELAYABLE_DEFINE", header: "kernel.h".}


## *
##  @cond INTERNAL_HIDDEN
##

const
  K_WORK_USER_STATE_PENDING* = 0 ##  Work item pending state

## *
##  INTERNAL_HIDDEN @endcond
##
# proc Z_WORK_USER_INITIALIZER*(work_handler: untyped) {.
    # importc: "Z_WORK_USER_INITIALIZER", header: "kernel.h".}


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
# proc K_WORK_USER_DEFINE*(work: untyped; work_handler: untyped) {.
    # importc: "K_WORK_USER_DEFINE", header: "kernel.h".}


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
    importc: "$1", header: "kernel.h".}

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
proc k_work_user_is_pending*(work: ptr k_work_user): bool {.
    importc: "$1", header: "kernel.h".}

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
    importc: "$1", header: "kernel.h".}

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
# proc K_WORK_DEFINE*(work: untyped; work_handler: untyped) {.
    # importc: "K_WORK_DEFINE", header: "kernel.h".}


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

