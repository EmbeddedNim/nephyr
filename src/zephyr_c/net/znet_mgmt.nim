##
##  Copyright (c) 2016 Intel Corporation.
##
##  SPDX-License-Identifier: Apache-2.0
##
## *
##  @file
##  @brief Network Management API public header
##

## *
##  @brief Network Management
##  @defgroup net_mgmt Network Management
##  @ingroup networking
##  @{
##

import ../wrapper_utils
import ../zkernel_fixes
import znet_if

const
  NET_MGMT_EVENT_MASK* = 0x80000000
  NET_MGMT_ON_IFACE_MASK* = 0x40000000
  NET_MGMT_LAYER_MASK* = 0x30000000
  NET_MGMT_SYNC_EVENT_MASK* = 0x08000000
  NET_MGMT_LAYER_CODE_MASK* = 0x07FF0000
  NET_MGMT_COMMAND_MASK* = 0x0000FFFF
  NET_MGMT_EVENT_BIT* = BIT(31)
  NET_MGMT_IFACE_BIT* = BIT(30)
  NET_MGMT_SYNC_EVENT_BIT* = BIT(27)

# proc NET_MGMT_LAYER*(layer: untyped) {.importc: "NET_MGMT_LAYER",
                                    #  header: "net_mgmt.h".}

# proc NET_MGMT_LAYER_CODE*(_code: untyped) {.importc: "NET_MGMT_LAYER_CODE",
    # header: "net_mgmt.h".}

# proc NET_MGMT_EVENT*(mgmt_request: untyped) {.importc: "NET_MGMT_EVENT",
#     header: "net_mgmt.h".}
# proc NET_MGMT_ON_IFACE*(mgmt_request: untyped) {.importc: "NET_MGMT_ON_IFACE",
#     header: "net_mgmt.h".}
# proc NET_MGMT_EVENT_SYNCHRONOUS*(mgmt_request: untyped) {.
#     importc: "NET_MGMT_EVENT_SYNCHRONOUS", header: "net_mgmt.h".}
# proc NET_MGMT_GET_LAYER*(mgmt_request: untyped) {.importc: "NET_MGMT_GET_LAYER",
#     header: "net_mgmt.h".}
# proc NET_MGMT_GET_LAYER_CODE*(mgmt_request: untyped) {.
#     importc: "NET_MGMT_GET_LAYER_CODE", header: "net_mgmt.h".}
# proc NET_MGMT_GET_COMMAND*(mgmt_request: untyped) {.
#     importc: "NET_MGMT_GET_COMMAND", header: "net_mgmt.h".}

##  Useful generic definitions

const
  NET_MGMT_LAYER_L2* = 1
  NET_MGMT_LAYER_L3* = 2
  NET_MGMT_LAYER_L4* = 3

## * @endcond
## *
##  @typedef net_mgmt_request_handler_t
##  @brief Signature which all Net MGMT request handler need to follow
##  @param mgmt_request The exact request value the handler is being called
##         through
##  @param iface A valid pointer on struct net_if if the request is meant
##         to be tight to a network interface. NULL otherwise.
##  @param data A valid pointer on a data understood by the handler.
##         NULL otherwise.
##  @param len Length in byte of the memory pointed by data.
##

type
  net_mgmt_request_handler_t* = proc (mgmt_request: uint32; iface: ptr net_if;
                                   data: pointer; len: csize_t): cint

  net_mgmt_event_handler_t* = proc (cb: ptr net_mgmt_event_callback;
                                 mgmt_event: uint32; iface: ptr net_if)

  INNER_C_UNION_net_mgmt_0* {.importc: "no_name", header: "net_mgmt.h", bycopy, union.} = object
    handler* {.importc: "handler".}: net_mgmt_event_handler_t ## * Actual callback function being used to notify the owner
                                                          ##
    ## * Semaphore meant to be used internaly for the synchronous
    ##  net_mgmt_event_wait() function.
    ##
    # sync_call* {.importc: "sync_call".}: ptr k_sem

  INNER_C_UNION_net_mgmt_2* {.importc: "no_name", header: "net_mgmt.h", bycopy, union.} = object
    event_mask* {.importc: "event_mask".}: uint32 ## * A mask of network events on which the above handler should
                                              ##  be called in case those events come.
                                              ##  Note that only the command part is treated as a mask,
                                              ##  matching one to several commands. Layer and layer code will
                                              ##  be made of an exact match. This means that in order to
                                              ##  receive events from multiple layers, one must have multiple
                                              ##  listeners registered, one for each layer being listened.
                                              ##
    ## * Internal place holder when a synchronous event wait is
    ##  successfully unlocked on a event.
    ##
    raised_event* {.importc: "raised_event".}: uint32

  net_mgmt_event_callback* {.importc: "net_mgmt_event_callback",
                            header: "net_mgmt.h", bycopy.} = object
    node* {.importc: "node".}: sys_snode_t ## * Meant to be used internally, to insert the callback into a list.
                                       ##  So nobody should mess with it.
                                       ##
    ano_net_mgmt_1* {.importc: "ano_net_mgmt_1".}: INNER_C_UNION_net_mgmt_0
    ano_net_mgmt_3* {.importc: "ano_net_mgmt_3".}: INNER_C_UNION_net_mgmt_2


# proc net_mgmt*(mgmt_request: untyped; _iface: untyped; _data: untyped; _len: untyped) {.
    # importc: "net_mgmt", header: "net_mgmt.h".}
# proc NET_MGMT_REGISTER_REQUEST_HANDLER*(_mgmt_request: untyped; _func: untyped) {.
    # importc: "NET_MGMT_REGISTER_REQUEST_HANDLER", header: "net_mgmt.h".}


## *
##  @brief Network Management event callback structure
##  Used to register a callback into the network management event part, in order
##  to let the owner of this struct to get network event notification based on
##  given event mask.
##


## *
##  @brief Helper to initialize a struct net_mgmt_event_callback properly
##  @param cb A valid application's callback structure pointer.
##  @param handler A valid handler function pointer.
##  @param mgmt_event_mask A mask of relevant events for the handler
##

proc net_mgmt_init_event_callback*(cb: ptr net_mgmt_event_callback;
                                    handler: net_mgmt_event_handler_t;
                                    mgmt_event_mask: uint32) 

## *
##  @brief Add a user callback
##  @param cb A valid pointer on user's callback to add.
##

proc net_mgmt_add_event_callback*(cb: ptr net_mgmt_event_callback) {.
    importc: "net_mgmt_add_event_callback", header: "net_mgmt.h".}

## *
##  @brief Delete a user callback
##  @param cb A valid pointer on user's callback to delete.
##

  proc net_mgmt_del_event_callback*(cb: ptr net_mgmt_event_callback) {.
      importc: "net_mgmt_del_event_callback", header: "net_mgmt.h".}

## *
##  @brief Used by the system to notify an event.
##  @param mgmt_event The actual network event code to notify
##  @param iface a valid pointer on a struct net_if if only the event is
##         based on an iface. NULL otherwise.
##  @param info a valid pointer on the information you want to pass along
##         with the event. NULL otherwise. Note the data pointed there is
##         normalized by the related event.
##  @param length size of the data pointed by info pointer.
##
##  Note: info and length are disabled if CONFIG_NET_MGMT_EVENT_INFO
##        is not defined.
##

proc net_mgmt_event_notify_with_info*(mgmt_event: uint32; iface: ptr net_if;
                                      info: pointer; length: csize_t) {.
    importc: "net_mgmt_event_notify_with_info", header: "net_mgmt.h".}
proc net_mgmt_event_notify*(mgmt_event: uint32; iface: ptr net_if) {.inline.} =
  net_mgmt_event_notify_with_info(mgmt_event, iface, nil, 0)

## *
##  @brief Used to wait synchronously on an event mask
##  @param mgmt_event_mask A mask of relevant events to wait on.
##  @param raised_event a pointer on a uint32_t to get which event from
##         the mask generated the event. Can be NULL if the caller is not
##         interested in that information.
##  @param iface a pointer on a place holder for the iface on which the
##         event has originated from. This is valid if only the event mask
##         has bit NET_MGMT_IFACE_BIT set relevantly, depending on events
##         the caller wants to listen to.
##  @param info a valid pointer if user wants to get the information the
##         event might bring along. NULL otherwise.
##  @param info_length tells how long the info memory area is. Only valid if
##         the info is not NULL.
##  @param timeout A timeout delay. K_FOREVER can be used to wait indefinitely.
##
##  @return 0 on success, a negative error code otherwise. -ETIMEDOUT will
##          be specifically returned if the timeout kick-in instead of an
##          actual event.
##

proc net_mgmt_event_wait*(mgmt_event_mask: uint32; raised_event: ptr uint32;
                          iface: ptr ptr net_if; info: ptr pointer;
                          info_length: ptr csize_t; timeout: k_timeout_t): cint {.
    importc: "net_mgmt_event_wait", header: "net_mgmt.h".}

## *
##  @brief Used to wait synchronously on an event mask for a specific iface
##  @param iface a pointer on a valid network interface to listen event to
##  @param mgmt_event_mask A mask of relevant events to wait on. Listened
##         to events should be relevant to iface events and thus have the bit
##         NET_MGMT_IFACE_BIT set.
##  @param raised_event a pointer on a uint32_t to get which event from
##         the mask generated the event. Can be NULL if the caller is not
##         interested in that information.
##  @param info a valid pointer if user wants to get the information the
##         event might bring along. NULL otherwise.
##  @param info_length tells how long the info memory area is. Only valid if
##         the info is not NULL.
##  @param timeout A timeout delay. K_FOREVER can be used to wait indefinitely.
##
##  @return 0 on success, a negative error code otherwise. -ETIMEDOUT will
##          be specifically returned if the timeout kick-in instead of an
##          actual event.
##

proc net_mgmt_event_wait_on_iface*(iface: ptr net_if; mgmt_event_mask: uint32;
                                  raised_event: ptr uint32; info: ptr pointer;
                                  info_length: ptr csize_t; timeout: k_timeout_t): cint {.
    importc: "net_mgmt_event_wait_on_iface", header: "net_mgmt.h".}

## *
##  @brief Used by the core of the network stack to initialize the network
##         event processing.
##

proc net_mgmt_event_init*() {.importc: "net_mgmt_event_init", header: "net_mgmt.h".}

## *
##  @}
##
