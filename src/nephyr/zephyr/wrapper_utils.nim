import zcmtoken
export zcmtoken

template BIT*(n: untyped): untyped =
  1 shl n

template NephyrDefineDistinctFlag*(T: untyped, V: typedesc)  =
  ## defines a distinct 'flag' type, useful for uint32 options types
  type
    T* = distinct V
  proc `or` *(x, y: T): T {.borrow.}

type
  ## single linked list node, used in some api's
  
  k_poll_signal* {.importc: "k_poll_signal", header: "kernel.h", bycopy.} = object ##\
  ## TODO: import kernel.h 
