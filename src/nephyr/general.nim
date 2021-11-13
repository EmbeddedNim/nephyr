
import sequtils
import strutils

import utils, logs
import mcu_utils/basictypes

export basictypes
export utils
export logs
export sequtils
export strutils

import zephyr_c/kernel

export kernel

proc NimMain() {.importc.}

proc sysReboot*(coldReboot: bool = false) = sys_reboot(if coldReboot: 1 else: 0)

template app_main*(blk: untyped): untyped =

  proc main*() {.exportc.} =
    NimMain() # initialize garbage collector memory, types and stack
    try:
      blk
    except:
      echo "Error: "
      echo getCurrentExceptionMsg()
      abort()
