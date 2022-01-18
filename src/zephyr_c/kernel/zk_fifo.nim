
import ../zkernel_fixes
import ../zsys_clock

import zk_queue

type
  k_fifo* {.importc: "struct k_fifo", header: "kernel.h", bycopy.} = object
    z_queue {.importc: "_queue".}: k_queue

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
proc k_fifo_init*(fifo: ptr k_fifo) {.importc: "k_fifo_init", header: "kernel.h".}


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
proc k_fifo_cancel_wait*(fifo: ptr k_fifo) {.importc: "k_fifo_cancel_wait",
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
proc k_fifo_put*(fifo: ptr k_fifo; data: pointer) {.importc: "k_fifo_put",
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
proc k_fifo_alloc_put*(fifo: ptr k_fifo; data: pointer) {.importc: "k_fifo_alloc_put",
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
proc k_fifo_put_list*(fifo: ptr k_fifo; head: ptr sys_slist_t; tail: ptr sys_slist_t) {.
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
proc k_fifo_put_slist*(fifo: ptr k_fifo; list: ptr sys_slist_t) {.importc: "k_fifo_put_slist",
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
proc k_fifo_get*(fifo: ptr k_fifo; timeout: k_timeout_t): pointer {.importc: "k_fifo_get",
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
proc k_fifo_is_empty*(fifo: ptr k_fifo) {.importc: "k_fifo_is_empty",
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
proc k_fifo_peek_head*(fifo: ptr k_fifo) {.importc: "k_fifo_peek_head",
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
proc k_fifo_peek_tail*(fifo: ptr k_fifo) {.importc: "k_fifo_peek_tail",
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
# proc K_FIFO_DEFINE*(name: k_fifo) {.importc: "K_FIFO_DEFINE", header: "kernel.h".}


## * @}
type
  k_lifo* {.importc: "struct k_lifo", header: "kernel.h", bycopy.} = object
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
proc k_lifo_init*(lifo: ptr k_lifo) {.importc: "k_lifo_init", header: "kernel.h".}


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
proc k_lifo_put*(lifo: ptr k_lifo; data: pointer) {.importc: "k_lifo_put",
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
proc k_lifo_alloc_put*(lifo: ptr k_lifo; data: pointer) {.importc: "k_lifo_alloc_put",
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
proc k_lifo_get*(lifo: ptr k_lifo; timeout: k_timeout_t) {.importc: "k_lifo_get",
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
# proc K_LIFO_DEFINE*(name: cminvtoken) {.importc: "K_LIFO_DEFINE", header: "kernel.h".}
