# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.
import macros
from os import getEnv, `/`

import nephyr/general

export general

proc NimMain() {.importc.}

template app_main*(blk: untyped): untyped =

  proc main*() {.exportc.} =
    NimMain() # initialize garbage collector memory, types and stack
    try:
      blk
    except:
      echo "Error: "
      echo getCurrentExceptionMsg()
      abort()