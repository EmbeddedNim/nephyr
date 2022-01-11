
import mcu_utils/basictypes
import zephyr_c/kernel

from std/monotimes import MonoTime

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

when defined(CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER):
  proc micros*(): Micros = Micros(k_cyc_to_us_floor64(k_cycle_get_64()))
else:
  proc micros*(): Micros = Micros(k_cyc_to_us_floor64(k_cycle_get_32()))

proc delay*(ms: Millis): Millis {.discardable.} =
  ## Sleep for millis, return 0 if requested time elapsed, otherwise the number of millis remaining
  return k_msleep(ms.int32).Millis

proc delay*(us: Micros): Micros {.discardable.} =
  ## Sleep for micros, return 0 if requested time elapsed, otherwise the number of micros remaining
  return k_usleep(us.int32).Micros

proc delayMillis*(ts: int): bool =
  ## Sleep for millis, return false if woken up early
  let res = k_msleep(ts.int32)
  if res == 0:
    return true

proc delayMicros*(ts: int): bool =
  ## Sleep for micros, return false if woken up early
  let res = k_msleep(ts.int32)
  if res == 0:
    return true
