##
##  Copyright (c) 2016 Wind River Systems, Inc.
##
##  SPDX-License-Identifier: Apache-2.0
##
##
##  The purpose of this file is to provide essential/minimal kernel structure
##  definitions, so that they can be used without including kernel.h.
##
##  The following rules must be observed:
##   1. kernel_structs.h shall not depend on kernel.h both directly and
##     indirectly (i.e. it shall not include any header files that include
##     kernel.h in their dependency chain).
##   2. kernel.h shall imply kernel_structs.h, such that it shall not be
##     necessary to include kernel_structs.h explicitly when kernel.h is
##     included.
##


var STACK_SENTINEL* {.importc: "STACK_SENTINEL", header: "kernel_structs.h".}: int ##  Magic value in lowest bytes of the stack

var Z_NON_PREEMPT_THRESHOLD* {.importc: "_NON_PREEMPT_THRESHOLD",
                            header: "kernel_structs.h".}: int ##  lowest value of _thread_base.preempt at which a thread is non-preemptible

var Z_PREEMPT_THRESHOLD* {.importc: "_PREEMPT_THRESHOLD", header: "kernel_structs.h".}: int ##  highest value of _thread_base.preempt at which a thread is preemptible

  type
    _ready_q* {.importc: "_ready_q", header: "kernel_structs.h", bycopy.} = object
      when not defined(CONFIG_SMP):
        ##  always contains next thread to run: cannot be NULL
        var cache* {.importc: "cache", header: "kernel_structs.h".}: ptr k_thread
      when defined(CONFIG_SCHED_DUMB):
        var runq* {.importc: "runq", header: "kernel_structs.h".}: sys_dlist_t
      elif defined(CONFIG_SCHED_SCALABLE):
        var runq* {.importc: "runq", header: "kernel_structs.h".}: _priq_rb
      elif defined(CONFIG_SCHED_MULTIQ):
        var runq* {.importc: "runq", header: "kernel_structs.h".}: _priq_mq

  type
    _ready_q_t* = _ready_q
  type
    _cpu* {.importc: "_cpu", header: "kernel_structs.h", bycopy.} = object
      nested* {.importc: "nested".}: uint32 ##  nested interrupt count
      ##  interrupt stack pointer base
      irq_stack* {.importc: "irq_stack".}: cstring ##  currently scheduled thread
      current* {.importc: "current".}: ptr k_thread ##  one assigned idle thread per CPU
      idle_thread* {.importc: "idle_thread".}: ptr k_thread
      when (CONFIG_NUM_METAIRQ_PRIORITIES > 0) and
          (CONFIG_NUM_COOP_PRIORITIES > 0):
        ##  Coop thread preempted by current metairq, or NULL
        var metairq_preempted* {.importc: "metairq_preempted",
                               header: "kernel_structs.h".}: ptr k_thread
      when defined(CONFIG_TIMESLICING):
        ##  number of ticks remaining in current time slice
        var slice_ticks* {.importc: "slice_ticks", header: "kernel_structs.h".}: cint
      id* {.importc: "id".}: uint8
      when defined(CONFIG_SMP):
        ##  True when _current is allowed to context switch
        var swap_ok* {.importc: "swap_ok", header: "kernel_structs.h".}: uint8
      arch* {.importc: "arch".}: _cpu_arch ##  Per CPU architecture specifics

  type
    _cpu_t* = _cpu
  type
    z_kernel* {.importc: "z_kernel", header: "kernel_structs.h", bycopy.} = object
      cpus* {.importc: "cpus".}: array[CONFIG_MP_NUM_CPUS, _cpu]
      when defined(CONFIG_PM):
        var idle* {.importc: "idle", header: "kernel_structs.h".}: int32
        ##  Number of ticks for kernel idling
      ready_q* {.importc: "ready_q".}: _ready_q ##
                                            ##  ready queue: can be big, keep after small fields, since some
                                            ##  assembly (e.g. ARC) are limited in the encoding of the offset
                                            ##
      when defined(CONFIG_FPU_SHARING):
        ##
        ##  A 'current_sse' field does not exist in addition to the 'current_fp'
        ##  field since it's not possible to divide the IA-32 non-integer
        ##  registers into 2 distinct blocks owned by differing threads.  In
        ##  other words, given that the 'fxnsave/fxrstor' instructions
        ##  save/restore both the X87 FPU and XMM registers, it's not possible
        ##  for a thread to only "own" the XMM registers.
        ##
        ##  thread that owns the FP regs
        var current_fp* {.importc: "current_fp", header: "kernel_structs.h".}: ptr k_thread
      when defined(CONFIG_THREAD_MONITOR):
        var threads* {.importc: "threads", header: "kernel_structs.h".}: ptr k_thread
        ##  singly linked list of ALL threads

  type
    _kernel_t* = z_kernel
  var _kernel* {.importc: "_kernel", header: "kernel_structs.h".}: z_kernel
  when defined(CONFIG_SMP):
    ##  True if the current context can be preempted and migrated to
    ##  another SMP CPU.
    ##
    proc z_smp_cpu_mobile*(): bool {.importc: "z_smp_cpu_mobile",
                                  header: "kernel_structs.h".}
    var _current_cpu* {.importc: "_current_cpu", header: "kernel_structs.h".}: int
  else:
    var _current_cpu* {.importc: "_current_cpu", header: "kernel_structs.h".}: int
  ##  kernel wait queue record
  when defined(CONFIG_WAITQ_SCALABLE):
    type
      _wait_q_t* {.importc: "_wait_q_t", header: "kernel_structs.h", bycopy.} = object
        waitq* {.importc: "waitq".}: _priq_rb

    proc z_priq_rb_lessthan*(a: ptr rbnode; b: ptr rbnode): bool {.
        importc: "z_priq_rb_lessthan", header: "kernel_structs.h".}
    proc Z_WAIT_Q_INIT*(wait_q: untyped) {.importc: "Z_WAIT_Q_INIT",
                                        header: "kernel_structs.h".}
  else:
    type
      _wait_q_t* {.importc: "_wait_q_t", header: "kernel_structs.h", bycopy.} = object
        waitq* {.importc: "waitq".}: sys_dlist_t

    proc Z_WAIT_Q_INIT*(wait_q: untyped) {.importc: "Z_WAIT_Q_INIT",
                                        header: "kernel_structs.h".}
  ##  kernel timeout record
  discard "forward decl of _timeout"
  type
    _timeout_func_t* = proc (t: ptr _timeout)
  type
    _timeout* {.importc: "_timeout", header: "kernel_structs.h", bycopy.} = object
      node* {.importc: "node".}: sys_dnode_t
      fn* {.importc: "fn".}: _timeout_func_t
      when defined(CONFIG_TIMEOUT_64BIT):
        ##  Can't use k_ticks_t for header dependency reasons
        var dticks* {.importc: "dticks", header: "kernel_structs.h".}: int64
      else:
        var dticks* {.importc: "dticks", header: "kernel_structs.h".}: int32
