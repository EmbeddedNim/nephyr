
import std/sequtils, std/strutils

import mcu_utils/basictypes

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

when CONFIG_USB_DEVICE_STACK:
  proc usbEnable*(arg: pointer = nil): cint {.importc: "usb_enable", header: "<usb/usb_device.h>", discardable.}
