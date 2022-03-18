
import std/sequtils, std/strutils

import mcu_utils/basictypes
import mcu_utils/logging

export basictypes
export sequtils
export strutils

# nephyr modules
import utils, logs
import ../zephyr_c/zkernel

export zkernel
export utils
export logs

proc sysReboot*(coldReboot: bool = false) = k_sys_reboot(if coldReboot: 1 else: 0)
proc sysPanic*(reason: k_fatal_error_reason | cuint) = k_fatal_halt(reason.cuint)
proc sysPanic*() = k_fatal_halt(K_ERR_KERNEL_PANIC.cuint)

proc usb_enable*(arg: pointer): cint {.importc: "usb_enable", header: "<usb/usb_device.h>".}

template sysUsbEnable*(arg: pointer = nil, check = false) =
  let res = usb_enable(arg)
  logWarn("sysUsbEnable:error: ", res)
  if check:
    doCheck(res)


proc hwinfo_get_device_id*(buffer: cstring, length: csize_t) {.importc: "$1", header: "<drivers/hwinfo.h>".}

proc getDeviceId*(size = 64): string =
  result = newString(size)
  hwinfo_get_device_id(result.cstring, size.csize_t)
