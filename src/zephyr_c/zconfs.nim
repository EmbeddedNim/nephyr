import tables, streams, parsecfg, strutils
import json
import macros

const
  ZephyrConfigFile* {.strdefine.} = ""

## Current constants
## 
## add more constant defines as needed to match Zephyr
const CONFIG_NAMES = [
  "ADC_ASYNC",
  "ADC_CONFIGURABLE_INPUTS",
  "DEMAND_PAGING_THREAD_STATS",
  "ERRNO", 
  "ERRNO_IN_TLS",
  "FPU_SHARING", 
  "INIT_STACKS", 
  "MEM_SLAB_TRACE_MAX_UTILIZATION",
  "MPU",
  "MULTITHREADING",
  "NETWORKING",
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

template other_configs(): seq[(string, NimNode)] =
  @[
    ("ARCH_EXCEPT", newLit(true)),
    ("BOARD", newLit("native_posix")),
  ]

proc parseCmakeConfig*(configName=".config"): TableRef[string, JsonNode] =
  var 
    fpath = configName
  echo "Using CMAKE Config file: ", fpath
  var
    f = readFile(fpath)
    fs = newStringStream(f)
    opts = newTable[string, JsonNode]()

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
        if e.value == "y":
          opts[e.key] = % true
        elif e.value != "n":
          var jn = 
            try:
              % fromHex[int](e.value)
            except ValueError:
              try:
                % parseInt(e.value)
              except ValueError:
                echo "unknown: config flag: ", e.key ," value: ", repr e.value
                % e.value
              
          opts[e.key] = jn
      of cfgOption:
        echo("warning ignoring config option: " & e.key & ": " & e.value)
      of cfgError:
        echo(e.msg)
    close(p)
  
  result = opts

macro GenerateZephyrConfigDefines*(): untyped =
  let cvals: TableRef[string, JsonNode] = 
    if ZephyrConfigFile == "":
      var tbl = newTable[string,JsonNode]()
      for name in CONFIG_NAMES:
        tbl[name] = % true
      tbl
    else:
      parseCmakeConfig(ZephyrConfigFile)
      
  proc getCVal(name: string, defval: NimNode = nil): NimNode =
    let jnode = cvals.getOrDefault("CONFIG_" & name, newJNull())
    # echo "jnode: ", repr jnode
    if jnode.kind == JBool:
      result = newLit(jnode.getBool())
    elif jnode.kind == JInt:
      result = newLit(jnode.getInt())
    elif jnode.kind == JFloat:
      result = newLit(jnode.getFloat())
    elif jnode.kind == JString:
      result = newLit(jnode.getStr())
    elif jnode.kind == JNull:
      if defval.isNil:
        result = newLit(false)
      else:
        result = defval
    else:
      error("unhandled config flag: " & name & " type: " & $jnode)

  result = newStmtList()
  for name in CONFIG_NAMES:
    let confFlag = ident "CONFIG_" & name
    let cval = name.getCVal()
    result.add quote do:
      const `confFlag`* = `cval`

  for (name, defval) in other_configs():
    assert typeof(name) is string
    assert typeof(defval) is NimNode
    let confFlag = ident name
    var cval = name.getCVal(defval)
    result.add quote do:
      const `confFlag`* = `cval`

# TODO: FIXME: finish implementing! 
GenerateZephyrConfigDefines()
