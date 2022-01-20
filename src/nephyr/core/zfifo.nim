import std/options

import ../../zephyr_c/kernel/zk_fifo
import ../../zephyr_c/kernel/zk_time

type
  ZFifoItem*[T] = object
    a: pointer
    data: T

  ZFifoItemRef*[T] = ref ZFifoItem[T]

  ZFifo*[T] = ref object
    kfifo*: k_fifo


when defined(DebugZFifoImpl):
  proc `=destroy`*[T](x: var ZFifoItem[T]) =
    echo "destroy: zfifoitem: ", x.addr.pointer.repr
    when T is ref:
      if x.data != nil:
        dealloc(x.data)

template testsZkFifo*() =

  import std/random
  import std/options

  proc producerThread(args: (ZFifo[int], int, int)) =
    var
      myFifo = args[0]
      count = args[1]
      tsrand = args[2]
    echo "\n===== running producer ===== "
    # myFifo.clear()
    for i in 0..<count:
      os.sleep(rand(tsrand))
      # /* create data item to send */
      var txData = 1234 + 100 * i

      # /* send data to consumers */
      echo "-> Producer: tx_data: putting: ", i, " -> ", repr(txData)
      myFifo.put(txData)
      echo "-> Producer: tx_data: sent: ", i
    echo "Done Producer: "
    
  proc consumerThread(args: (ZFifo[int], int, int)) =
    var
      myFifo = args[0]
      count = args[1]
      tsrand = args[2]
    echo "\n===== running consumer ===== "
    for i in 0..<count:
      os.sleep(rand(tsrand))
      echo "<- Consumer: rx_data: wait: ", i
      echo "   Consumer: is_empty: ", myFifo.isEmpty()
      var rxData = myFifo.get(K_FOREVER)
      # while rxData.isNone():
        # echo "<- Consumer: Got None..."
        # rxData = myFifo.get(K_FOREVER)

      # os.sleep(rand(100))
      echo "<- Consumer: rx_data: got: ", i, " <- ", repr(rxData)

    echo "Done Consumer: "

  proc runTestsZkFifo() =
    randomize()
    var myFifo = newZFifo[int]()
    echo "zf: ", repr(myFifo)

    producerThread((myFifo, 10, 100))
    echo "myFifo: ", repr(myFifo)
    consumerThread((myFifo, 10, 100))
    echo "myFifo: ", repr(myFifo)

  proc runTestsZkFifoThreaded(ncnt, tsrand: int) =
    echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
    echo "[ZFifo] Begin "
    randomize()
    var myFifo = newZFifo[int]()
    echo "zf: ", repr(myFifo)

    var thrp: Thread[(ZFifo[int], int, int)]
    var thrc: Thread[(ZFifo[int], int, int)]

    createThread(thrc, consumerThread, (myFifo, ncnt, tsrand))
    # os.sleep(2000)
    createThread(thrp, producerThread, (myFifo, ncnt, tsrand))
    # echo "myFifo: ", repr(myFifo)
    joinThreads(thrp, thrc)
    echo "[ZFifo] Done joined "
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "


proc newZFifoItem*[T](data: var T): ZFifoItemRef[T] =
  new(result)
  result.data = data
  when defined(DebugZFifoImpl):
    echo "create: zfifoitem: ", cast[pointer](result).pointer.repr

proc clear*[T](self: var ZFifo[T]) =
  k_fifo_cancel_wait(addr self.kfifo)

proc isEmpty*[T](self: var ZFifo[T]): bool =
  return k_fifo_is_empty(addr self.kfifo) != 0

proc put*[T](self: var ZFifo[T]; data: var T) =
  ##  This routine adds a data item to @a fifo. A FIFO data item must be
  ##  aligned on a word boundary, and the first word of the item is reserved
  ##  for the kernel's use.
  var item = newZFifoItem(data)
  GC_ref(item)
  k_fifo_put(addr self.kfifo, cast[pointer](move item))

proc get*[T](self: var ZFifo[T], timeout = K_FOREVER): Option[T] =
  ##  This routine adds a data item to @a fifo. A FIFO data item must be
  ##  aligned on a word boundary, and the first word of the item is reserved
  ##  for the kernel's use.
  var itemptr = k_fifo_get(addr self.kfifo, timeout)
  if itemptr.isNil:
    none(T)
  else:
    var item = cast[ZFifoItemRef[T]](itemptr)
    GC_unref(item)
    some(item.data)

proc newZFifo*[T](): ZFifo[T] =
  ##  This routine initializes a FIFO queue, prior to its first use.
  new(result)
  k_fifo_init(addr result.kfifo) # C Macro

# ## *
# ##  @brief Add an element to a FIFO queue.
# ##
# ##  This routine adds a data item to @a fifo. There is an implicit memory
# ##  allocation to create an additional temporary bookkeeping data structure from
# ##  the calling thread's resource pool, which is automatically freed when the
# ##  item is removed. The data itself is not copied.
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param fifo Address of the FIFO.
# ##  @param data Address of the data item.
# ##
# ##  @retval 0 on success
# ##  @retval -ENOMEM if there isn't sufficient RAM in the caller's resource pool
# ##
# proc k_fifo_alloc_put*(fifo: k_fifo; data: pointer) {.importc: "k_fifo_alloc_put",
#     header: "kernel.h".}


# ## *
# ##  @brief Atomically add a list of elements to a FIFO.
# ##
# ##  This routine adds a list of data items to @a fifo in one operation.
# ##  The data items must be in a singly-linked list, with the first word of
# ##  each data item pointing to the next data item; the list must be
# ##  NULL-terminated.
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param fifo Address of the FIFO queue.
# ##  @param head Pointer to first node in singly-linked list.
# ##  @param tail Pointer to last node in singly-linked list.
# ##
# ##  @return N/A
# ##
# proc k_fifo_put_list*(fifo: k_fifo; head: ptr sys_slist_t; tail: ptr sys_slist_t) {.
#     importc: "k_fifo_put_list", header: "kernel.h".}


# ## *
# ##  @brief Atomically add a list of elements to a FIFO queue.
# ##
# ##  This routine adds a list of data items to @a fifo in one operation.
# ##  The data items must be in a singly-linked list implemented using a
# ##  sys_slist_t object. Upon completion, the sys_slist_t object is invalid
# ##  and must be re-initialized via sys_slist_init().
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param fifo Address of the FIFO queue.
# ##  @param list Pointer to sys_slist_t object.
# ##
# ##  @return N/A
# ##
# proc k_fifo_put_slist*(fifo: k_fifo; list: ptr sys_slist_t) {.importc: "k_fifo_put_slist",
#     header: "kernel.h".}


# ## *
# ##  @brief Get an element from a FIFO queue.
# ##
# ##  This routine removes a data item from @a fifo in a "first in, first out"
# ##  manner. The first word of the data item is reserved for the kernel's use.
# ##
# ##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param fifo Address of the FIFO queue.
# ##  @param timeout Waiting period to obtain a data item,
# ##                 or one of the special values K_NO_WAIT and K_FOREVER.
# ##
# ##  @return Address of the data item if successful; NULL if returned
# ##  without waiting, or waiting period timed out.
# ##
# proc k_fifo_get*(fifo: k_fifo; timeout: k_timeout_t) {.importc: "k_fifo_get",
#     header: "kernel.h".}


# ## *
# ##  @brief Query a FIFO queue to see if it has data available.
# ##
# ##  Note that the data might be already gone by the time this function returns
# ##  if other threads is also trying to read from the FIFO.
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param fifo Address of the FIFO queue.
# ##
# ##  @return Non-zero if the FIFO queue is empty.
# ##  @return 0 if data is available.
# ##
# proc k_fifo_is_empty*(fifo: k_fifo) {.importc: "k_fifo_is_empty",
#                                     header: "kernel.h".}


# ## *
# ##  @brief Peek element at the head of a FIFO queue.
# ##
# ##  Return element from the head of FIFO queue without removing it. A usecase
# ##  for this is if elements of the FIFO object are themselves containers. Then
# ##  on each iteration of processing, a head container will be peeked,
# ##  and some data processed out of it, and only if the container is empty,
# ##  it will be completely remove from the FIFO queue.
# ##
# ##  @param fifo Address of the FIFO queue.
# ##
# ##  @return Head element, or NULL if the FIFO queue is empty.
# ##
# proc k_fifo_peek_head*(fifo: k_fifo) {.importc: "k_fifo_peek_head",
#                                       header: "kernel.h".}


# ## *
# ##  @brief Peek element at the tail of FIFO queue.
# ##
# ##  Return element from the tail of FIFO queue (without removing it). A usecase
# ##  for this is if elements of the FIFO queue are themselves containers. Then
# ##  it may be useful to add more data to the last container in a FIFO queue.
# ##
# ##  @param fifo Address of the FIFO queue.
# ##
# ##  @return Tail element, or NULL if a FIFO queue is empty.
# ##
# proc k_fifo_peek_tail*(fifo: k_fifo) {.importc: "k_fifo_peek_tail",
#                                       header: "kernel.h".}


# ## *
# ##  @brief Statically define and initialize a FIFO queue.
# ##
# ##  The FIFO queue can be accessed outside the module where it is defined using:
# ##
# ##  @code extern struct k_fifo <name>; @endcode
# ##
# ##  @param name Name of the FIFO queue.
# ##
# proc K_FIFO_DEFINE*(name: k_fifo) {.importc: "K_FIFO_DEFINE", header: "kernel.h".}


# ## * @}
# type
#   k_lifo* {.importc: "k_lifo", header: "kernel.h", bycopy.} = object
#     z_queue* {.importc: "_queue".}: k_queue


# ## *
# ##  @defgroup lifo_apis LIFO APIs
# ##  @ingroup kernel_apis
# ##  @{
# ##
# ## *
# ##  @brief Initialize a LIFO queue.
# ##
# ##  This routine initializes a LIFO queue object, prior to its first use.
# ##
# ##  @param lifo Address of the LIFO queue.
# ##
# ##  @return N/A
# ##
# proc k_lifo_init*(lifo: k_lifo) {.importc: "k_lifo_init", header: "kernel.h".}


# ## *
# ##  @brief Add an element to a LIFO queue.
# ##
# ##  This routine adds a data item to @a lifo. A LIFO queue data item must be
# ##  aligned on a word boundary, and the first word of the item is
# ##  reserved for the kernel's use.
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param lifo Address of the LIFO queue.
# ##  @param data Address of the data item.
# ##
# ##  @return N/A
# ##
# proc k_lifo_put*(lifo: k_lifo; data: pointer) {.importc: "k_lifo_put",
#     header: "kernel.h".}


# ## *
# ##  @brief Add an element to a LIFO queue.
# ##
# ##  This routine adds a data item to @a lifo. There is an implicit memory
# ##  allocation to create an additional temporary bookkeeping data structure from
# ##  the calling thread's resource pool, which is automatically freed when the
# ##  item is removed. The data itself is not copied.
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param lifo Address of the LIFO.
# ##  @param data Address of the data item.
# ##
# ##  @retval 0 on success
# ##  @retval -ENOMEM if there isn't sufficient RAM in the caller's resource pool
# ##
# proc k_lifo_alloc_put*(lifo: k_lifo; data: pointer) {.importc: "k_lifo_alloc_put",
#     header: "kernel.h".}


# ## *
# ##  @brief Get an element from a LIFO queue.
# ##
# ##  This routine removes a data item from @a LIFO in a "last in, first out"
# ##  manner. The first word of the data item is reserved for the kernel's use.
# ##
# ##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
# ##
# ##  @funcprops \isr_ok
# ##
# ##  @param lifo Address of the LIFO queue.
# ##  @param timeout Waiting period to obtain a data item,
# ##                 or one of the special values K_NO_WAIT and K_FOREVER.
# ##
# ##  @return Address of the data item if successful; NULL if returned
# ##  without waiting, or waiting period timed out.
# ##
# proc k_lifo_get*(lifo: k_lifo; timeout: k_timeout_t) {.importc: "k_lifo_get",
#     header: "kernel.h".}


# ## *
# ##  @brief Statically define and initialize a LIFO queue.
# ##
# ##  The LIFO queue can be accessed outside the module where it is defined using:
# ##
# ##  @code extern struct k_lifo <name>; @endcode
# ##
# ##  @param name Name of the fifo.
# ##
# proc K_LIFO_DEFINE*(name: cminvtoken) {.importc: "K_LIFO_DEFINE", header: "kernel.h".}
