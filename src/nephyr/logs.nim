import strutils
import system
import sequtils

import macros

# const LOG_HDR = "<logging/log.h>"

# proc loge*(formatstr: cstring) {.importc: "LOG_ERR", varargs, header: LOG_HDR.}
# proc logw*(formatstr: cstring) {.importc: "LOG_WRN", varargs, header: LOG_HDR.}
# proc logi*(formatstr: cstring) {.importc: "LOG_INF", varargs, header: LOG_HDR.}
# proc logd*(formatstr: cstring) {.importc: "LOG_DBG", varargs, header: LOG_HDR.}

macro debug(args: varargs[untyped]): untyped =
  # `args` is a collection of `NimNode` values that each contain the
  # AST for an argument of the macro. A macro always has to
  # return a `NimNode`. A node of kind `nnkStmtList` is suitable for
  # this use case.
  result = nnkStmtList.newTree()
  # iterate over any argument that is passed to this macro:
    # add a call to the statement list that writes the expression;
    # `toStrLit` converts an AST to its string representation:
    # result.add newCall("echo",  newLit(n.repr), newLit(": "), newCall("$", n))
  let v = args.mapIt(newCall("$", it))
  result.add newCall("echo", v)


template loge*(args: varargs[untyped]) =
  debug(args) 
template logw*(args: varargs[untyped]) =
  # debug(args) 
  discard "ignore"
template logi*(args: varargs[untyped]) =
  debug(args) 
  # discard "ignore"
template logd*(args: varargs[untyped]) =
  # debug(args) 
  discard "ignore"

# proc ldup*(str: cstring): cstring {.importc: "log_strdup", varargs, header: LOG_HDR.}
proc ldup*(str: cstring): cstring = str
proc ldup*(str: string): cstring =
  ldup(str.cstring())

when defined(zephyr):
  template initLogs*(name: string) = 
    const
        modName = name
        logimpt = """

    /* Display all messages, including debugging ones: */
    #define LOG_LEVEL LOG_LEVEL_DBG
    #include <logging/log.h>
    /* Set the "module" for these log messages: */
    #define LOG_MODULE_NAME socket_net_nim

    LOG_MODULE_REGISTER($1);
    """ % [modName]
    {.emit: logimpt.}

else:

  template initLogs*(name: string) = 
    discard name