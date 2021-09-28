import cmtoken
export cmtoken

template BIT*(n: untyped): untyped =
  1 shl n

template NephyrDefineFlag*(T: untyped, V: typedesc)  =
  type
    T* = distinct V
  proc `or` *(x, y: T): T {.borrow.}

type
  sys_snode_t* {.importc: "sys_snode_t", header: "slist.h", bycopy.} = object ##\
  ## single linked list node, used in some api's
  
  k_poll_signal* {.importc: "k_poll_signal", header: "kernel.h", bycopy.} = object ##\
  ## TODO: import kernel.h 
