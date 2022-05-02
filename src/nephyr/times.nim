import std/[times, monotimes]
import mcu_utils/basictypes

import zephyr/zconfs
import zephyr/zkernel

# from std/monotimes import MonoTime
export times, monotimes

export basictypes
export MonoTime

proc k_uptime_ticks*(): int64 {.importc: "$1", header: "kernel.h".} #

proc k_uptime_get*(): int64 {.importc: "$1", header: "kernel.h".} #
proc k_uptime_get_32*(): uint32 {.importc: "$1", header: "kernel.h".} #
proc k_uptime_delta*(reftime: ptr int64): int64 {.importc: "$1", header: "kernel.h".} #

proc k_cycle_get_32*(): uint32 {.importc: "$1", header: "kernel.h".} #
proc k_cycle_get_64*(): uint32 {.importc: "$1", header: "kernel.h".} #

proc k_ms_to_ticks_ceil32*(ts: uint64): uint64 {.importc: "$1", header: "kernel.h".} #
proc k_cyc_to_us_floor64*(ts: uint64): uint64 {.importc: "$1", header: "kernel.h".} #

proc millis*(): Millis = Millis(k_uptime_get())

when CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER:
  proc micros*(): Micros = Micros(k_cyc_to_us_floor64(k_cycle_get_64()))
else:
  proc micros*(): Micros = Micros(k_cyc_to_us_floor64(k_cycle_get_32()))

proc delay*(ms: Millis): Millis =
  ## Sleep for millis, return 0 if requested time elapsed, otherwise the number of millis remaining
  return k_msleep(ms.int32).Millis

proc delay*(us: Micros): Micros =
  ## Sleep for micros, return 0 if requested time elapsed, otherwise the number of micros remaining
  return k_usleep(us.int32).Micros

proc delayMillis*(ts: int): bool {.discardable.} =
  ## Sleep for millis, return false if woken up early
  let res = k_msleep(ts.int32)
  if res == 0:
    return true

# proc sleep*(us: Micros) =
#   var remaining = us.int32
#   while remaining != 0:
#     remaining  = k_msleep(remaining)

# proc sleep*(ms: Millis) =
#   ## Sleep for micros
#   var remaining = ms.int32
#   while remaining != 0:
#     remaining  = k_msleep(remaining)
