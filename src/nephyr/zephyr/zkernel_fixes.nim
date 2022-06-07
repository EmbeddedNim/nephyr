
import wrapper_utils
import cdecl
import cdecl/cdeclapi
export cdeclapi

export wrapper_utils

proc abort*() {.importc: "abort", header: "stdlib.h".}

proc k_sys_reboot*(kind: cint) {.importc: "sys_reboot", header: "<sys/reboot.h>".}

proc printk*(frmt: cstring) {.importc: "$1", varargs, header: "<sys/printk.h>".}

macro zsyscall*(fn: untyped) = result = fn

type

  k_thread_stack_t* {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_thread_entry_t* {.importc: "$1 ", header: "<kernel.h>".} = proc (p1, p2, p3: pointer) {.cdecl.}

  k_thread_proc* = proc (p1, p2, p3: pointer) {.cdecl.}

  z_wait_q_t* {.importc: "_wait_q_t", header: "<kernel.h>", bycopy, incompleteStruct.} = object
    waitq {.importc: "$1".}: sys_dlist_t

  # these are all opaque kernel types
  # sys_snode_t* {.importc: "sys_snode_t", header: "slist.h", bycopy.} = object ##\
  sys_snode_t* {.importc: "$1", header: "<kernel.h>",
            bycopy, incompleteStruct.} = object
    next {.importc: "$1".}: ptr sys_snode_t
  sys_slist_t* {.importc: "$1", header: "<kernel.h>",
                 bycopy, incompleteStruct.} = object
    head: pointer
    tail: pointer

  sys_sfnode_t* {.importc: "$1", header: "<kernel.h>",
            bycopy, incompleteStruct.} = object
    next_and_flags {.importc: "$1".}: cuint
  sys_sflist_t* {.importc: "$1", header: "<kernel.h>",
                  bycopy, incompleteStruct.} = object
    head: pointer
    tail: pointer

  dnode* {.importc: "struct _dnode", header: "<kernel.h>",
            bycopy, incompleteStruct.} = object
    head {.importc: "$1".}: pointer
    next {.importc: "$1".}: pointer
  sys_dlist_t* {.importc: "$1", header: "<kernel.h>",
                 bycopy, incompleteStruct.} = dnode
  sys_dnode_t* {.importc: "$1", header: "<kernel.h>",
                 bycopy, incompleteStruct.} = dnode

  k_spinlock * {.importc: "struct $1", header: "<spinlock.h>", bycopy, incompleteStruct.} = object

  k_priv_timeout * {.importc: "struct _timeout", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_mem_block * {.importc: "struct k_mem_block", header: "<kernel.h>", bycopy, incompleteStruct.} = object

proc KDefineStackMacro*(stackArea: CToken, size: static[int]) {.
  cdeclmacro: "K_KERNEL_STACK_DEFINE", global, cdeclsVar(name -> ptr k_thread_stack_t).} ##\
    ## Wrapper around Zephyr's `K_KERNEL_STACK_DEFINE` macro. Generally any block
    ## of memory will work, however it must be word aligned.
    ## 
    ## The Zephyr macro also defines extra attributes for the linker so
    ## this macro can be useful for cases where you want to use Zephyr's
    ## "proper" stack definition.

proc K_THREAD_STACK_SIZEOF*(stack: ptr k_thread_stack_t): csize_t {.importc: "$1", header: "<kernel.h>".}

when defined(NephyrDebugSfList):
  proc sys_sflist_peek_head(list: ptr sys_sflist_t): ptr sys_sfnode_t {.importc: "$1", header: "<kernel.h>".}
  proc sys_sflist_peek_next(list: ptr sys_sfnode_t): ptr sys_sfnode_t {.importc: "$1", header: "<kernel.h>".}

  proc repr*(val: sys_sflist_t): string = 

    var
      node: ptr sys_sfnode_t = sys_sflist_peek_head(addr val)
      dlist = newSeq[pointer]()

    while node != nil:
      echo "slist: node: ", repr(node.pointer)
      dlist.add(node.pointer)
      node = sys_sflist_peek_next(node)

    return "slist: " & repr(dlist)

when defined(NephyrDebugSList):
  proc sys_slist_peek_head(list: ptr sys_slist_t): ptr sys_snode_t {.importc: "$1", header: "<kernel.h>".}
  proc sys_slist_peek_next(list: ptr sys_slist_t, node: ptr sys_snode_t): ptr sys_snode_t {.importc: "$1", header: "<kernel.h>".}

  proc repr*(val: sys_slist_t): string = 

    var
      node: ptr sys_snode_t = sys_slist_peek_head(addr val)
      dlist = newSeq[pointer]()

    while node != nil:
      echo "slist: node: ", repr(node.pointer)
      dlist.add(node.pointer)
      node = sys_slist_peek_next(addr val, node)

    return "slist: " & repr(dlist)

when defined(NephyrDebugDList):
  proc sys_dlist_peek_head(list: ptr sys_dlist_t): ptr sys_dnode_t {.importc: "$1", header: "<kernel.h>".}
  proc sys_dlist_peek_next(list, node: ptr sys_dlist_t): ptr sys_dnode_t {.importc: "$1", header: "<kernel.h>".}

  proc repr*(val: sys_dlist_t): string = 

    var
      node: ptr dnode = sys_dlist_peek_head(addr val)
      dlist = newSeq[pointer]()

    while node != nil:
      echo "dlist: node: ", repr(node.pointer)
      dlist.add(node.pointer)
      node = sys_dlist_peek_next(addr val, node)

    return "dlist: " & repr(dlist)
