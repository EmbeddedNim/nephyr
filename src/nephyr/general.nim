
import std/sequtils, std/strutils

import mcu_utils/basictypes
import mcu_utils/logging

export basictypes
export sequtils
export strutils

# nephyr modules
import utils, logs
import zephyr/zkernel
import zephyr/kernel/zk_time

export zkernel
export utils
export logs

from os import raiseOSError
export raiseOSError

type
  NephyrError* = object of Exception

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

  ThreadPriority* = distinct range[-128..128]
  BytesSz* = distinct int

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

macro zkThread*(p: untyped) = result = p

proc kCreateThread*(
    thread: var k_thread;
    function: proc (p1, p2, p3: pointer) {.cdecl.};
    stack: ptr k_thread_stack_t;
    stack_size: BytesSz;
    p1: pointer = nil,
    p2: pointer = nil,
    p3: pointer = nil,
    priority = ThreadPriority 1,
    options: uint32 = 0;
    delay: k_timeout_t = K_NO_WAIT
): k_tid_t =
  ## convenience wrapper for createThread
  ## 
  ## Usage:
  ## 
  ##   # Thread Definition
  ##   const blinkStackSz = 8192.BytesSz
  ##   KDefineStack(blinkStack, blinkStackSz.int)
  ##   var blink {.exportc.}: k_thread
  ## 
  ##   # Create and start thread
  ##   let blinkId =
  ##     blink.kCreateThread(
  ##       function = blinkThrFunc,
  ##       stack = blinkStack,
  ##       stack_size = blinkStackSz,
  ##       priority = 2.ThreadPriority,
  ##     )

  let entry: k_thread_entry_t = function
  result =
    zkernel.k_thread_create(
      addr thread,
      stack,
      stack_size.csize_t,
      entry,
      p1, p2, p3,
      priority.cint,
      options,
      delay
    )


template staticKThread*(
    name: untyped,
    entry: proc (p1, p2, p3: pointer) {.cdecl.};
    stack: static[BytesSz];
    p1: pointer = nil,
    p2: pointer = nil,
    p3: pointer = nil,
    priority = ThreadPriority 1,
    options: uint32 = 0;
    delay: k_timeout_t = K_NO_WAIT
) =
  ## convenience template to setup new thread
  ## includes creating a static stack
  ## creates global variables:
  ##    var nameStack*: ptr k_thread_stack_t
  ##    var nameThr* {.exportc.}: k_thread
  ##    var name*: k_tid_t
  ## 
  KDefineStack(`name Stack`, stack.int)
  var `name Thr` {.inject, global, exportc.}: k_thread
  let `name` {.inject, used, global.}: k_tid_t =
    zkernel.k_thread_create(
      addr `name Thr`,
      `name Stack`,
      stack.csize_t,
      entry,
      p1, p2, p3,
      priority.cint,
      options,
      delay
    )

