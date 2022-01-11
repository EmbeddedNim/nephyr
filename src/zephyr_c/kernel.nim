
import wrapper_utils

export wrapper_utils

proc abort*() {.importc: "abort", header: "stdlib.h".}

proc sys_reboot*(kind: cint) {.importc: "sys_reboot", header: "<sys/reboot.h>".}

proc printk*(frmt: cstring) {.importc: "$1", varargs, header: "<sys/printk.h>".}

# __syscall k_tid_t k_thread_create(struct k_thread *new_thread,
# 				  k_thread_stack_t *stack,
# 				  size_t stack_size,
# 				  k_thread_entry_t entry,
# 				  void *p1, void *p2, void *p3,
# 				  int prio, uint32_t options, k_timeout_t delay);
type
  k_thread* {.importc: "struct k_thread", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_thread_stack_t* {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_thread_entry_t* {.importc: "$1 ", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_tid_t* {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_timeout_t* {.importc: "$1", header: "<kernel.h>", bycopy, incompleteStruct.} = object

  k_thread_proc* = proc (p1, p2, p3: pointer) {.cdecl.}

var
  K_NO_WAIT* {.importc: "$1", header: "<kernel.h>".}: k_timeout_t

proc K_MSEC*(ts: int): k_timeout_t {.importc: "$1", header: "<kernel.h>".}

proc K_THREAD_STACK_SIZEOF*(stack: ptr k_thread_stack_t): csize_t {.
      importc: "$1", header: "<kernel.h>".}
# proc K_THREAD_STACK_DEFINE*(stack_area: cminvtoken, size: csize_t) {.
      # importc: "$1", header: "<kernel.h>".}

# K thread create
proc k_thread_create*(new_thread: ptr k_thread,
                     stack: ptr k_thread_stack_t,
                     stack_size: csize_t,
                     entry: k_thread_proc,
                     p1, p2, p3: pointer,
                     prio: cint,
                     options: uint32,
                     delay: k_timeout_t): k_tid_t {.
                        importc: "k_thread_create", header: "<kernel.h>".}

proc k_sleep*(timeout: k_timeout_t): int32 {.importc: "k_sleep", header: "<kernel.h>"} ##\
  ##  * @brief Put the current thread to sleep.
  ##  *
  ##  * This routine puts the current thread to sleep for @a duration,
  ##  * @note if @a timeout is set to K_FOREVER then the thread is suspended.
  ##  *
  ##  * @param timeout Desired duration of sleep.
  ##  *
  ##  * @return Zero if the requested time has elapsed or the number of milliseconds
  ##  * left to sleep, if thread was woken up by \ref k_wakeup call.

proc k_msleep*(ms: int32): int32 {.importc: "k_msleep", header: "<kernel.h>"} ##\
  ##  * @brief Put the current thread to sleep.
  ##  *
  ##  * This routine puts the current thread to sleep for @a duration milliseconds.
  ##  *
  ##  * @param ms Number of milliseconds to sleep.
  ##  *
  ##  * @return Zero if the requested time has elapsed or the number of milliseconds
  ##  * left to sleep, if thread was woken up by \ref k_wakeup call.
  ##  */

proc k_usleep*(us: int32): int32 {.importc: "k_usleep", header: "<kernel.h>"} ##\
  ## /**
  ##  * @brief Put the current thread to sleep with microsecond resolution.
  ##  *
  ##  * This function is unlikely to work as expected without kernel tuning.
  ##  * In particular, because the lower bound on the duration of a sleep is
  ##  * the duration of a tick, @kconfig{CONFIG_SYS_CLOCK_TICKS_PER_SEC} must be
  ##  * adjusted to achieve the resolution desired. The implications of doing
  ##  * this must be understood before attempting to use k_usleep(). Use with
  ##  * caution.
  ##  *
  ##  * @param us Number of microseconds to sleep.
  ##  *
  ##  * @return Zero if the requested time has elapsed or the number of microseconds
  ##  * left to sleep, if thread was woken up by \ref k_wakeup call.
  ##  */

proc k_yield*() {.importc: "k_yield", header: "<kernel.h>"} ##\
  ## /**
  ##  * @brief Yield the current thread.
  ##  *
  ##  * This routine causes the current thread to yield execution to another
  ##  * thread of the same or higher priority. If there are no other ready threads
  ##  * of the same or higher priority, the routine returns immediately.
  ##  *
  ##  * @return N/A
  ##  */

