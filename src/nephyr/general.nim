
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

type
  SystemInitLevel* = distinct int
  SystemInitPriority* = distinct int

var INIT_PRE_KERNEL_1* {.importc: "PRE_KERNEL_1", header: "<init.h>".}: SystemInitLevel
var INIT_PRE_KERNEL_2* {.importc: "PRE_KERNEL_2", header: "<init.h>".}: SystemInitLevel
var INIT_POST_KERNEL* {.importc: "POST_KERNEL", header: "<init.h>".}: SystemInitLevel
var INIT_APPLICATION* {.importc: "APPLICATION", header: "<init.h>".}: SystemInitLevel

var KernelInitPriorityDefault* {.importc: "CONFIG_KERNEL_INIT_PRIORITY_DEFAULT", header: "<init.h>".}: SystemInitPriority
var KernelInitPriorityDevice* {.importc: "CONFIG_KERNEL_INIT_PRIORITY_DEVICE", header: "<init.h>".}: SystemInitPriority
var KernelInitPriorityObjects* {.importc: "CONFIG_KERNEL_INIT_PRIORITY_OBJECTS", header: "<init.h>".}: SystemInitPriority

template SystemInit*(fn: proc {.cdecl.}, level: SystemInitLevel, priority: SystemInitPriority) =
  ## Template to setup a zephyr initialization callback for a given level and priority. 
  {.emit: "/*INCLUDESECTION*/\n#include <init.h>".}
  {.emit: ["/*VARSECTION*/\nSYS_INIT(", fn, ", ", level, ", ", priority, ");"].}
