
import macros
from os import getEnv, `/`

import nephyr/general

export general

include mcu_utils/threads

proc NimMain() {.importc.}

template app_main*(blk: untyped): untyped =
  app_main(0, blk)

template app_main*(delayms: static[int], blk: untyped): untyped =

  proc main*() {.exportc.} =
    when delayms > 0:
      os.sleep(delayms)
    NimMain() # initialize garbage collector memory, types and stack
    try:
      blk
    except:
      echo "Error: "
      echo getCurrentExceptionMsg()
      abort()