
import ../zkernel_fixes
import ../zsys_clock

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

