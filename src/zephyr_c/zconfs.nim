import os, tables, streams, parsecfg
import macros

const
  ZephyrConfigFile* {.strdefine.} = ""

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

## Current constants ... 
const CONFIG_NAMES = [
  "ADC_ASYNC",
  "ADC_CONFIGURABLE_INPUTS",
  "DEMAND_PAGING_THREAD_STATS",
  "ERRNO",
  "ERRNO", 
  "ERRNO_IN_TLS",
  "FPU_SHARING",
  "FPU_SHARING", 
  "INIT_STACKS", 
  "MEM_SLAB_TRACE_MAX_UTILIZATION",
  "MULTITHREADING",
  "PM",
  "PM_DEVICE",
  "POLL",
  "PRINTK",
  "SCHED_CPU_MASK",
  "SCHED_DEADLINE",
  "SCHED_DUMB",
  "SMP",
  "SPI_ASYNC",
  "SYS_CLOCK_EXISTS",
  "THREAD_CUSTOM_DATA",
  "THREAD_LOCAL_STORAGE",
  "THREAD_MONITOR",
  "THREAD_NAME",
  "THREAD_RUNTIME_STATS",
  "THREAD_RUNTIME_STATS_USE_TIMING_FUNCTIONS",
  "THREAD_STACK_INFO",
  "THREAD_USERSPACE_LOCAL_DATA",
  "TICKLESS_KERNEL",
  "TIMEOUT_64BIT",
  "TIMER_HAS_64BIT_CYCLE_COUNTER",
  "TIMESLICING",
  "USERSPACE",
  "USE_SWITCH",
  "WAITQ_SCALABLE",
  "X86",
  "X86_SSE",
  ]

const OTHER_CONFIGS = [
  "ARCH_EXCEPT",
  ]

macro GenerateZephyrConfigDefines*(): untyped =
  let cval = 
    if ZephyrConfigFile == "":
      quote do: true
    else:
      quote do: false

  result = newStmtList()
  for name in CONFIG_NAMES:
    let confFlag = ident "CONFIG_" & name
    result.add quote do:
      const `confFlag`* = `cval`
  for name in OTHER_CONFIGS :
    let confFlag = ident name
    result.add quote do:
      const `confFlag`* = `cval`

# TODO: FIXME: finish implementing! 
GenerateZephyrConfigDefines()
