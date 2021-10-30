
import sequtils
import strutils

import utils, logs
import basictypes

export basictypes
export utils
export logs
export sequtils
export strutils

proc NimMain() {.importc.}

proc abort*() {.importc: "abort", header: "stdlib.h".}

proc sys_reboot*(kind: cint) {.importc: "sys_reboot", header: "<sys/reboot.h>".}

proc sysReboot*(coldReboot: bool = false) = sys_reboot(if coldReboot: 1 else: 0)

proc k_uptime_get*(): uint64 {.importc: "$1", header: "kernel.h".}
proc k_cycle_get_32*(): uint32 {.importc: "$1", header: "kernel.h".}
proc k_cyc_to_us_floor64*(ts: uint64): uint64 {.importc: "$1", header: "kernel.h".}
proc printk*(frmt: cstring) {.importc: "$1", varargs, header: "<sys/printk.h>".}

proc micros*(): uint64 =
  let ticks = k_cycle_get_32()
  return k_cyc_to_us_floor64(ticks)

template app_main*(blk: untyped): untyped =

  proc main*() {.exportc.} =
    NimMain() # initialize garbage collector memory, types and stack
    try:
      blk
    except:
      echo "Error: "
      echo getCurrentExceptionMsg()
      abort()
