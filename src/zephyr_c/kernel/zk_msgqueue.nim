
import ../zkernel_fixes
import ../zsys_clock
import ../zthread
import ../kernel/zk_sem

type
  k_msgq* {.importc: "struct k_msgq", header: "kernel.h", bycopy.} = object
    ##  @brief Message Queue Structure
    wait_q* {.importc: "wait_q".}: z_wait_q_t ## * Message queue wait queue
    ## * Lock
    lock* {.importc: "lock".}: k_spinlock ## * Message size
    msg_size* {.importc: "msg_size".}: csize_t ## * Maximal number of messages
    max_msgs* {.importc: "max_msgs".}: uint32 ## * Start of message buffer
    buffer_start* {.importc: "buffer_start".}: cstring ## * End of message buffer
    buffer_end* {.importc: "buffer_end".}: cstring ## * Read pointer
    read_ptr* {.importc: "read_ptr".}: cstring ## * Write pointer
    write_ptr* {.importc: "write_ptr".}: cstring ## * Number of used messages
    used_msgs* {.importc: "used_msgs".}: uint32
    poll_events* {.importc: "poll_events".}: sys_dlist_t ##  _POLL_EVENT;
                                                      ## * Message queue
    flags* {.importc: "flags".}: uint8

  k_msgq_attrs* {.importc: "struct k_msgq_attrs", header: "kernel.h", bycopy.} = object
    ##  @brief Message Queue Attributes
    msg_size* {.importc: "msg_size".}: csize_t ## * Message Size
    ## * Maximal number of messages
    max_msgs* {.importc: "max_msgs".}: uint32 ## * Used messages
    used_msgs* {.importc: "used_msgs".}: uint32

# proc Z_MSGQ_INITIALIZER*(obj: untyped; q_buffer: untyped; q_msg_size: untyped;
                        # q_max_msgs: untyped) {.importc: "Z_MSGQ_INITIALIZER",
    # header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
# var K_MSGQ_FLAG_ALLOC* {.importc: "K_MSGQ_FLAG_ALLOC", header: "kernel.h".}: int


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
# proc K_MSGQ_DEFINE*(q_name: cminvtoken; q_msg_size: static[int]; q_max_msgs: static[int];
                    # q_align: static[int]) {.importc: "K_MSGQ_DEFINE",
                                      # header: "kernel.h".}


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
                  max_msgs: uint32) {.importc: "k_msgq_init", header: "kernel.h".}


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
proc k_msgq_alloc_init*(msgq: ptr k_msgq; msg_size: csize_t; max_msgs: uint32): cint {.
    zsyscall, importc: "k_msgq_alloc_init", header: "kernel.h".}


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
    zsyscall, importc: "k_msgq_put", header: "kernel.h".}


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
    zsyscall, importc: "k_msgq_get", header: "kernel.h".}


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
proc k_msgq_peek*(msgq: ptr k_msgq; data: pointer): cint {.zsyscall,
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
proc k_msgq_purge*(msgq: ptr k_msgq) {.zsyscall, importc: "k_msgq_purge",
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
proc k_msgq_num_free_get*(msgq: ptr k_msgq): uint32 {.zsyscall,
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
proc k_msgq_get_attrs*(msgq: ptr k_msgq; attrs: ptr k_msgq_attrs) {.zsyscall,
    importc: "k_msgq_get_attrs", header: "kernel.h".}
proc z_impl_k_msgq_num_free_get*(msgq: ptr k_msgq): uint32 {.inline.} =
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
proc k_msgq_num_used_get*(msgq: ptr k_msgq): uint32 {.zsyscall,
    importc: "k_msgq_num_used_get", header: "kernel.h".}
proc z_impl_k_msgq_num_used_get*(msgq: ptr k_msgq): uint32 {.inline.} =
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

  k_mbox_msg* {.importc: "struct k_mbox_msg", header: "kernel.h", incompleteStruct, bycopy.} = object
    z_mailbox* {.importc: "_mailbox".}: uint32 ## * internal use only - needed for legacy API support
    ## * size of message (in bytes)
    size* {.importc: "size".}: csize_t ## * application-defined information value
    info* {.importc: "info".}: uint32 ## * sender's message data buffer
    tx_data* {.importc: "tx_data".}: pointer ## * internal use only - needed for legacy API support
    z_rx_data* {.importc: "_rx_data".}: pointer ## * message data block descriptor
    tx_block* {.importc: "tx_block".}: k_mem_block ## * source thread id
    rx_source_thread* {.importc: "rx_source_thread".}: k_tid_t ## * target thread id
    tx_target_thread* {.importc: "tx_target_thread".}: k_tid_t ## * internal use only - thread waiting on send (may be a dummy)
    z_syncing_thread* {.importc: "_syncing_thread".}: k_tid_t

## *
##  @brief Mailbox Structure
##
##
type
  k_mbox* {.importc: "struct k_mbox", header: "kernel.h", bycopy.} = object
    tx_msg_queue* {.importc: "tx_msg_queue".}: z_wait_q_t ## * Transmit messages queue
    ## * Receive message queue
    rx_msg_queue* {.importc: "rx_msg_queue".}: z_wait_q_t
    lock* {.importc: "lock".}: k_spinlock

## *
##  @cond INTERNAL_HIDDEN
##
# proc Z_MBOX_INITIALIZER*(obj: untyped) {.importc: "Z_MBOX_INITIALIZER",
                                      # header: "kernel.h".}


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
# proc K_MBOX_DEFINE*(name: untyped) {.importc: "K_MBOX_DEFINE", header: "kernel.h".}


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
