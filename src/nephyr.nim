
import macros
from os import getEnv, `/`

import nephyr/general

export general

include mcu_utils/threads

import macros 
import strformat 

proc NimMain() {.importc.}

template wrappAllErrors*(name: string, procBody: untyped): untyped =
  try:
    `procBody`
  except Exception as e:
    ## manually print stack to handle lower memory devices
    echo "[" & name & "]: exception: ", getCurrentExceptionMsg()
    let stes = getStackTraceEntries(e)
    for ste in stes:
      echo "[" & name & "]: ", $ste
  except Defect as e:
    ## manually print stack to handle lower memory devices
    echo "[" & name & "]: defect: ", getCurrentExceptionMsg()
    let stes = getStackTraceEntries(e)
    for ste in stes:
      echo "[" & name & "]: ", $ste

macro zephyr_main*(p: untyped): untyped =
  ## default wrapper that wraps exceptions and prints them out. 
  ## 
  ## This exports the annotated proc with `exportc`. 
  ## 
  result = p
  const
    pragmaIdx = 4
    procBodyIdx = 6
  let
    procBody = p[procBodyIdx]
 
  # add `exportc` pragma
  result[pragmaIdx] = nnkPragma.newTree(ident("exportc"))

  # wrap c body
  result[procBodyIdx] = quote do:
    NimMain() # initialize garbage collector memory, types and stack
    wrappAllErrors("main", `procBody`)
    echo "unknown error causing reboot"
    # sysReboot()
    sysPanic()



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