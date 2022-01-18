
from macros import error
import std/atomics

import ../../zephyr_c/kernel/zk_fifo

type

  item*[TMsg] {.gcsafe.} = object ## a ZChannel for thread communication
    k_reserved: pointer # for Zephyr kernel bookkeeping
    data: TMsg

  ZChannel*[TMsg] {.gcsafe.} = object ## a ZChannel for thread communication
    k_fifo: k_fifo
    limit: Atomic[int]


when not defined(gcDestructors):
  error("must use GC with destructors")

proc initZkFifo*[TMsg](): ZChannel[TMsg] =
  k_fifo_init(addr result.k_fifo)

proc sendImpl(q: PRawChannel, typ: PNimType, msg: pointer, noBlock: bool): bool =
  if q.mask == ChannelDeadMask:
    sysFatal(DeadThreadDefect, "cannot send message; thread died")
  acquireSys(q.lock)
  if q.maxItems > 0:
    # Wait until count is less than maxItems
    if noBlock and q.count >= q.maxItems:
      releaseSys(q.lock)
      return

    while q.count >= q.maxItems:
      waitSysCond(q.cond, q.lock)

  rawSend(q, msg, typ)
  q.elemType = typ
  releaseSys(q.lock)
  signalSysCond(q.cond)
  result = true

proc send*[TMsg](c: var ZChannel[TMsg], msg: sink TMsg) {.inline.} =
  ## Sends a message to a thread. `msg` is deeply copied.
  # discard sendImpl(cast[PRawChannel](addr c), cast[PNimType](getTypeInfo(msg)), unsafeAddr(msg), false)
  wasMoved(msg)

proc trySend*[TMsg](c: var ZChannel[TMsg], msg: sink TMsg): bool {.inline.} =
  ## Tries to send a message to a thread.
  ##
  ## `msg` is deeply copied. Doesn't block.
  ##
  ## Returns `false` if the message was not sent because number of pending items
  ## in the ZChannel exceeded `maxItems`.
  result = sendImpl(cast[PRawChannel](addr c), cast[PNimType](getTypeInfo(msg)), unsafeAddr(msg), true)
  if result:
    wasMoved(msg)

proc recv*[TMsg](c: var ZChannel[TMsg]): TMsg =
  ## Receives a message from the ZChannel `c`.
  ##
  ## This blocks until a message has arrived!
  ## You may use `peek proc <#peek,ZChannel[TMsg]>`_ to avoid the blocking.
  var q = cast[PRawChannel](addr(c))
  acquireSys(q.lock)
  llRecv(q, addr(result), cast[PNimType](getTypeInfo(result)))
  releaseSys(q.lock)

proc tryRecv*[TMsg](c: var ZChannel[TMsg]): tuple[dataAvailable: bool,
                                                  msg: TMsg] =
  ## Tries to receive a message from the ZChannel `c`, but this can fail
  ## for all sort of reasons, including contention.
  ##
  ## If it fails, it returns `(false, default(msg))` otherwise it
  ## returns `(true, msg)`.
  var q = cast[PRawChannel](addr(c))

proc peekHead*[TMsg](c: var ZChannel[TMsg]): int =
  ## Returns the current number of messages in the ZChannel `c`.
  ##
  ## Returns -1 if the ZChannel has been closed.
  ##
  ## **Note**: This is dangerous to use as it encourages races.
  ## It's much better to use `tryRecv proc <#tryRecv,ZChannel[TMsg]>`_ instead.
  var q = cast[PRawChannel](addr(c))

proc peekTail*[TMsg](c: var ZChannel[TMsg]): int =
  var q = cast[PRawChannel](addr(c))

proc peek*[TMsg](c: var ZChannel[TMsg]): int =
  ## Returns the current number of messages in the ZChannel `c`.
  ##
  ## Returns -1 if the ZChannel has been closed.
  ##
  ## **Note**: This is dangerous to use as it encourages races.
  ## It's much better to use `tryRecv proc <#tryRecv,ZChannel[TMsg]>`_ instead.
  return peekTail(c)

proc open*[TMsg](c: var ZChannel[TMsg], maxItems: int = 0) =
  ## Opens a ZChannel `c` for inter thread communication.
  ##
  ## The `send` operation will block until number of unprocessed items is
  ## less than `maxItems`.
  ##
  ## For unlimited queue set `maxItems` to 0.
  initRawChannel(addr(c), maxItems)

proc close*[TMsg](c: var ZChannel[TMsg]) =
  ## Closes a ZChannel `c` and frees its associated resources.

proc ready*[TMsg](c: var ZChannel[TMsg]): bool =
  ## Returns true if some thread is waiting on the ZChannel `c` for
  ## new messages.
  var q = cast[PRawChannel](addr(c))
  result = q.ready
