
import wrapper_utils

export wrapper_utils

proc abort*() {.importc: "abort", header: "stdlib.h".}

proc k_sys_reboot*(kind: cint) {.importc: "sys_reboot", header: "<sys/reboot.h>".}

proc printk*(frmt: cstring) {.importc: "$1", varargs, header: "<sys/printk.h>".}

template zsyscall*(fn: untyped) = fn

# __syscall k_tid_t k_thread_create(struct k_thread *new_thread,
# 				  k_thread_stack_t *stack,
# 				  size_t stack_size,
# 				  k_thread_entry_t entry,
# 				  void *p1, void *p2, void *p3,
# 				  int prio, uint32_t options, k_timeout_t delay);
type

  k_thread_stack_t* {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_thread_entry_t* {.importc: "$1 ", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_thread_proc* = proc (p1, p2, p3: pointer) {.cdecl.}

  z_wait_q_t* {.importc: "_wait_q_t", header: "<kernel.h>", bycopy, incompleteStruct.} = object
    waitq: sys_dlist_t

  # these are all opaque kernel types
  sys_slist_t * {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object
  sys_sflist_t * {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object
  sys_dlist_t * {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  sys_heap * {.importc: "struct $1", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_spinlock * {.importc: "struct $1", header: "<spinlock.h>", bycopy, incompleteStruct.} = object

  k_priv_timeout * {.importc: "struct _timeout", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_mem_block * {.importc: "struct k_mem_block", header: "<kernel.h>", bycopy, incompleteStruct.} = object

# var
  # K_NO_WAIT* {.importc: "$1", header: "<kernel.h>".}: k_timeout_t

# proc K_MSEC*(ts: int): k_timeout_t {.importc: "$1", header: "<kernel.h>".}

proc K_THREAD_STACK_SIZEOF*(stack: ptr k_thread_stack_t): csize_t {.
      importc: "$1", header: "<kernel.h>".}
# proc K_THREAD_STACK_DEFINE*(stack_area: cminvtoken, size: csize_t) {.
      # importc: "$1", header: "<kernel.h>".}

# # K thread create
# proc k_thread_create*(new_thread: ptr k_thread,
#                      stack: ptr k_thread_stack_t,
#                      stack_size: csize_t,
#                      entry: k_thread_proc,
#                      p1, p2, p3: pointer,
#                      prio: cint,
#                      options: uint32,
#                      delay: k_timeout_t): k_tid_t {.
#                         importc: "k_thread_create", header: "<kernel.h>".}

