import zcmtoken
import zdevice

export zcmtoken
export zdevice

template DT_NODELABEL*(ma: untyped): cminvtoken =
  CM_PROC(DT_NODELABEL, ma)

template DT_ALIAS*(ma: untyped): cminvtoken =
  CM_PROC(DT_ALIAS, ma)

proc DT_LABEL*(name: cminvtoken): cstring {.importc: "$1", header: "devicetree.h".}

template dt*(ma: static string): cminvtoken =
  tok`ma`

template alias*(ma: untyped): cminvtoken =
  DT_ALIAS(ma)

type
  nDevice* = object
    name: string

template nDeviceTree*(nd: static[string]): static[nDevice] =
  nDevice(name: nd)

proc DT_CHOSEN*(name: cminvtoken): ptr device {.importc: "$1", header: "devicetree.h".} ##\
  ## 
  ## @brief Get a node identifier for a /chosen node property
  ## 
  ## This is only valid to call if DT_HAS_CHOSEN(prop) is 1.
  ## @param prop lowercase-and-underscores property name for
  ##             the /chosen node
  ## @return a node identifier for the chosen node property
  ## 
