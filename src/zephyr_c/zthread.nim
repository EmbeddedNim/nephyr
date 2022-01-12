##
##  Copyright (c) 2016, Wind River Systems, Inc.
##
##  SPDX-License-Identifier: Apache-2.0
##

## ============================================ ##
## Wrapper for Zephyr thread.h
## Note: Mostly we just need to let Nim know that these types exist, not how they work. 
## ============================================ ##

## *
##  @typedef k_thread_entry_t
##  @brief Thread entry point function type.
##
##  A thread's entry point function is invoked when the thread starts executing.
##  Up to 3 argument values can be passed to the function.
##
##  The thread terminates execution permanently if the entry point function
##  returns. The thread is responsible for releasing any shared resources
##  it may own (such as mutexes and dynamically allocated memory), prior to
##  returning.
##
##  @param p1 First argument.
##  @param p2 Second argument.
##  @param p3 Third argument.
##
##  @return N/A
##
import zconfs
import zkernel_fixes

when CONFIG_THREAD_MONITOR:
  type
    z_thread_entry* {.importc: "__thread_entry", header: "thread.h", incompleteStruct, bycopy.} = object
      pEntry* {.importc: "pEntry".}: k_thread_entry_t
      parameter1* {.importc: "parameter1".}: pointer
      parameter2* {.importc: "parameter2".}: pointer
      parameter3* {.importc: "parameter3".}: pointer

##  can be used for creating 'dummy' threads, e.g. for pending on objects

type
  q_thread* {.importc: "no_name", header: "thread.h", incompleteStruct, bycopy, union.} = object


  z_thread_base* {.importc: "_thread_base", header: "thread.h", incompleteStruct, bycopy.} = object

    # # qnode_dlist* {.importc: "qnode_dlist".}: sys_dnode_t # note part of anonymous C union
    # # qnode_rb* {.importc: "qnode_rb".}: rbnode # note part of anonymous C union

    # # C Union
    # # C union elem 1
    # sched_locked* {.importc: "sched_locked", header: "thread.h".}: uint8 # part of anonymous union / struct
    # prio* {.importc: "prio", header: "thread.h".}: int8 # part of anonymous union / struct
    # # C union elem 2
    # preempt* {.importc: "preempt".}: uint16
    # # end C union 

    # pended_on* {.importc: "pended_on".}: ptr _wait_q_t

    user_options* {.importc: "user_options".}: uint8 ##  user facing 'thread options'; values defined in include/kernel.h
    ##  thread state
    thread_state* {.importc: "thread_state".}: uint8 

    when CONFIG_SCHED_DEADLINE:
      prio_deadline* {.importc: "prio_deadline".}: cint

    order_key* {.importc: "order_key".}: uint32

    when CONFIG_SMP:
      is_idle* {.importc: "is_idle".}: uint8 ##  True for the per-CPU idle threads
      cpu* {.importc: "cpu".}: uint8 ##  CPU index on which thread was last run
      global_lock_count* {.importc: "global_lock_count".}: uint8 ##  Recursive count of irq_lock() calls

    when CONFIG_SCHED_CPU_MASK:
      cpu_mask* {.importc: "cpu_mask".}: uint8 ##  "May run on" bits for each CPU

    swap_data* {.importc: "swap_data".}: pointer ##  data returned by APIs

    when CONFIG_SYS_CLOCK_EXISTS:
      timeout* {.importc: "timeout".}: k_priv_timeout #   ##  this thread's entry in a timeout queue


# when CONFIG_THREAD_USERSPACE_LOCAL_DATA:
#   type
#     _thread_userspace_local_data* {.importc: "_thread_userspace_local_data",
#                                    header: "thread.h", bycopy.} = object
#       when CONFIG_ERRNO and not CONFIG_ERRNO_IN_TLS:
#         var errno_var* {.importc: "errno_var", header: "thread.h".}: cint

# when CONFIG_THREAD_RUNTIME_STATS:
#   type
#     k_thread_runtime_stats* {.importc: "k_thread_runtime_stats",
#                              header: "thread.h", bycopy.} = object
#       execution_cycles* {.importc: "execution_cycles", header: "thread.h".}: uint64


#   type
#     _thread_runtime_stats* {.importc: "_thread_runtime_stats", header: "thread.h",
#                             bycopy.} = object
#       when CONFIG_THREAD_RUNTIME_STATS_USE_TIMING_FUNCTIONS: ##  Timestamp when last switched in
#         var last_switched_in* {.importc: "last_switched_in", header: "thread.h".}: timing_t
#       else:
#         var last_switched_in* {.importc: "last_switched_in", header: "thread.h".}: uint32
#       stats* {.importc: "stats".}: k_thread_runtime_stats_t

type
  k_thread_runtime_stats_t* {.importc: "k_thread_runtime_stats_t", header: "thread.h", bycopy.} = object

  z_poller* {.importc: "z_poller", header: "thread.h", incompleteStruct, bycopy.} = object
    is_polling* {.importc: "is_polling".}: bool
    mode* {.importc: "mode".}: uint8


## *
##  @ingroup thread_apis
##  Thread Structure
##

type
  k_thread* {.importc: "k_thread", header: "thread.h", incompleteStruct, bycopy.} = object
    base* {.importc: "base".}: z_thread_base ## * defined by the architecture, but all archs need these

    # callee_saved* {.importc: "callee_saved".}: _callee_saved ## * static thread init data
    # init_data* {.importc: "init_data".}: pointer ## * threads waiting in k_thread_join()
    # join_queue* {.importc: "join_queue".}: _wait_q_t

    # poller* {.importc: "poller", header: "thread.h".}: z_poller

    # when CONFIG_THREAD_MONITOR:
    #   ## * thread entry and parameters description
    #   entry* {.importc: "entry", header: "thread.h".}: __thread_entry
    #   ## * next item in list of all threads
    #   next_thread* {.importc: "next_thread", header: "thread.h".}: ptr k_thread

    # when CONFIG_THREAD_NAME:
    #   ## * Thread name
    #   name* {.importc: "name", header: "thread.h".}: array[CONFIG_THREAD_MAX_NAME_LEN, char]

    when CONFIG_THREAD_CUSTOM_DATA:
      ## * crude thread-local storage
      custom_data* {.importc: "custom_data".}: pointer

    when CONFIG_THREAD_USERSPACE_LOCAL_DATA:
      userspace_local_data* {.importc: "userspace_local_data".}: pointer

    when CONFIG_ERRNO and not CONFIG_ERRNO_IN_TLS:
      when not CONFIG_USERSPACE:
        ## * per-thread errno variable
        errno_var* {.importc: "errno_var".}: cint

    # when CONFIG_THREAD_STACK_INFO:
    #   ## * Stack Info
    #   stack_info* {.importc: "stack_info", header: "thread.h".}: _thread_stack_info

    # when CONFIG_USERSPACE:
    #   ## * memory domain info of the thread
    #   mem_domain_info* {.importc: "mem_domain_info", header: "thread.h".}: _mem_domain_info
    #   ## * Base address of thread stack
    #   stack_obj* {.importc: "stack_obj", header: "thread.h".}: ptr k_thread_stack_t
    #   ## * current syscall frame pointer
    #   syscall_frame* {.importc: "syscall_frame", header: "thread.h".}: pointer

    # when CONFIG_USE_SWITCH:
    #   ##  When using __switch() a few previously arch-specific items
    #   ##  become part of the core OS
    #   ##
    #   ## * z_swap() return value
    #   swap_retval* {.importc: "swap_retval", header: "thread.h".}: cint
    #   ## * Context handle returned via arch_switch()
    #   switch_handle* {.importc: "switch_handle", header: "thread.h".}: pointer

    resource_pool* {.importc: "resource_pool".}: pointer ## * resource pool

    when CONFIG_THREAD_LOCAL_STORAGE:
      ##  Pointer to arch-specific TLS area
      tls* {.importc: "tls".}: pointer

    when CONFIG_THREAD_RUNTIME_STATS:
      ## * Runtime statistics
      rt_stats* {.importc: "rt_stats".}: pointer

    # when CONFIG_DEMAND_PAGING_THREAD_STATS:
    #   ## * Paging statistics
    #   paging_stats* {.importc: "paging_stats", header: "thread.h".}: k_mem_paging_stats_t
    # arch* {.importc: "arch".}: _thread_arch ## * arch-specifics: must always be at the end

  k_tid_t* = ptr k_thread
