
import zcmtoken
export zcmtoken

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
