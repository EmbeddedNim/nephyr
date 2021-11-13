
import sequtils
import strutils

import utils, logs
import mcu_utils/basictypes

export basictypes
export utils
export logs
export sequtils
export strutils

proc NimMain() {.importc.}

proc abort*() {.importc: "abort", header: "stdlib.h".}

proc sys_reboot*(kind: cint) {.importc: "sys_reboot", header: "<sys/reboot.h>".}

proc sysReboot*(coldReboot: bool = false) = sys_reboot(if coldReboot: 1 else: 0)

proc printk*(frmt: cstring) {.importc: "$1", varargs, header: "<sys/printk.h>".}

template app_main*(blk: untyped): untyped =

  proc main*() {.exportc.} =
    NimMain() # initialize garbage collector memory, types and stack
    try:
      blk
    except:
      echo "Error: "
      echo getCurrentExceptionMsg()
      abort()
