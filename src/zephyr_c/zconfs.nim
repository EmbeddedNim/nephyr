import os, tables, strutils, streams, parsecfg
import macros

const
  ZephyrConfigFile* {.strdefine.} = "build_" & getEnv("BOARD") / "zephyr" / ".config"

proc parseCmakeConfig*(configName=".config"): TableRef[string, string] =
  var 
    fpath = configName
  echo "Using CMAKE Config file: ", fpath
  var
    f = readFile(fpath)
    fs = newStringStream(f)
    opts = newTable[string, string]()

  if fs != nil:
    var p: CfgParser
    open(p, fs, "zephyr.config")
    while true:
      var e = next(p)
      case e.kind
      of cfgEof: break
      of cfgSectionStart:   ## a ``[section]`` has been parsed
        echo("warning ignoring new config section: " & e.section)
      of cfgKeyValuePair:
        # echo("key-value-pair: " & e.key & ": " & e.value)
        if e.value != "n":
          opts[e.key] = e.value
      of cfgOption:
        echo("warning ignoring config option: " & e.key & ": " & e.value)
      of cfgError:
        echo(e.msg)
    close(p)
  
  result = opts


macro generateZephyrConfigDefines*(): untyped =
  return quote do:
    const CONFIG_SCHED_DUMB = true
  # {.define(CONFIG_NET).}


## Current constants ... 
# CONFIG_SCHED_DUMB
# CONFIG_TIMESLICING
# CONFIG_SMP
# CONFIG_PM
# CONFIG_FPU_SHARING
# CONFIG_THREAD_MONITOR
# CONFIG_SMP
# CONFIG_WAITQ_SCALABLE
# CONFIG_TIMEOUT_64BIT
# CONFIG_ADC_CONFIGURABLE_INPUTS
# CONFIG_ADC_ASYNC
# CONFIG_ADC_ASYNC
# CONFIG_SPI_ASYNC
# CONFIG_SPI_ASYNC
# CONFIG_FPU_SHARING
# CONFIG_X86
# CONFIG_FPU_SHARING 
# CONFIG_X86_SSE
# CONFIG_INIT_STACKS 
# CONFIG_THREAD_STACK_INFO
# CONFIG_THREAD_LOCAL_STORAGE
# CONFIG_THREAD_LOCAL_STORAGE
# CONFIG_SYS_CLOCK_EXISTS
# CONFIG_SCHED_DEADLINE
# CONFIG_SCHED_CPU_MASK
# CONFIG_TIMEOUT_64BIT
# CONFIG_SYS_CLOCK_EXISTS
# CONFIG_USERSPACE
# CONFIG_MEM_SLAB_TRACE_MAX_UTILIZATION
# CONFIG_MEM_SLAB_TRACE_MAX_UTILIZATION
# CONFIG_POLL
# ARCH_EXCEPT
# CONFIG_MULTITHREADING
# CONFIG_SMP
# CONFIG_PRINTK
# CONFIG_THREAD_RUNTIME_STATS
# CONFIG_THREAD_MONITOR
# CONFIG_SCHED_DEADLINE
# CONFIG_SMP
# CONFIG_SCHED_CPU_MASK
# CONFIG_SYS_CLOCK_EXISTS
# CONFIG_THREAD_USERSPACE_LOCAL_DATA
# CONFIG_ERRNO
# CONFIG_ERRNO_IN_TLS
# CONFIG_THREAD_RUNTIME_STATS
# CONFIG_THREAD_RUNTIME_STATS_USE_TIMING_FUNCTIONS
# CONFIG_THREAD_MONITOR
# CONFIG_THREAD_NAME
# CONFIG_THREAD_CUSTOM_DATA
# CONFIG_THREAD_USERSPACE_LOCAL_DATA
# CONFIG_ERRNO 
# CONFIG_ERRNO_IN_TLS
# CONFIG_THREAD_STACK_INFO
# CONFIG_USERSPACE
# CONFIG_USE_SWITCH
# CONFIG_THREAD_LOCAL_STORAGE
# CONFIG_THREAD_RUNTIME_STATS
# CONFIG_DEMAND_PAGING_THREAD_STATS
# CONFIG_PM_DEVICE
# CONFIG_PM_DEVICE
# CONFIG_PM_DEVICE
# CONFIG_TIMEOUT_64BIT
# CONFIG_TICKLESS_KERNEL
# CONFIG_TIMER_HAS_64BIT_CYCLE_COUNTER
