## * @file
##  @brief IPv6 data handler
##
##  This is not to be included by the application.
##
##
##  Copyright (c) 2016 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

const hdr = "<net/ip/ipv6.h>"

# import ../zkernel_fixes
import ../zconfs
# import ../zdevice
# import ../kernel/zk_fifo
import ../zkernel
import znet_core
import znet_if
import znet_linkaddr

import posix

const
  NET_IPV6_ND_HOP_LIMIT* = 255
  NET_IPV6_ND_INFINITE_LIFETIME* = 0xFFFFFFFF
  NET_IPV6_DEFAULT_PREFIX_LEN* = 64
  NET_MAX_RS_COUNT* = 3

## *
##  @brief Bitmaps for IPv6 extension header processing
##
##  When processing extension headers, we record which one we have seen.
##  This is done as the network packet cannot have twice the same header,
##  except for destination option.
##  This information is stored in bitfield variable.
##  The order of the bitmap is the order recommended in RFC 2460.
##

const
  NET_IPV6_EXT_HDR_BITMAP_HBHO* = 0x01
  NET_IPV6_EXT_HDR_BITMAP_DESTO1* = 0x02
  NET_IPV6_EXT_HDR_BITMAP_ROUTING* = 0x04
  NET_IPV6_EXT_HDR_BITMAP_FRAG* = 0x08
  NET_IPV6_EXT_HDR_BITMAP_AH* = 0x10
  NET_IPV6_EXT_HDR_BITMAP_ESP* = 0x20
  NET_IPV6_EXT_HDR_BITMAP_DESTO2* = 0x40

## *
##  @brief Destination and Hop By Hop extension headers option types
##

const
  NET_IPV6_EXT_HDR_OPT_PAD1* = 0
  NET_IPV6_EXT_HDR_OPT_PADN* = 1
  NET_IPV6_EXT_HDR_OPT_RPL* = 0x63

## *
##  @brief Multicast Listener Record v2 record types.
##

const
  NET_IPV6_MLDv2_MODE_IS_INCLUDE* = 1
  NET_IPV6_MLDv2_MODE_IS_EXCLUDE* = 2
  NET_IPV6_MLDv2_CHANGE_TO_INCLUDE_MODE* = 3
  NET_IPV6_MLDv2_CHANGE_TO_EXCLUDE_MODE* = 4
  NET_IPV6_MLDv2_ALLOW_NEW_SOURCES* = 5
  NET_IPV6_MLDv2_BLOCK_OLD_SOURCES* = 6

##  State of the neighbor

type
  net_ipv6_nbr_state* {.size: sizeof(cint).} = enum
    NET_IPV6_NBR_STATE_INCOMPLETE,
    NET_IPV6_NBR_STATE_REACHABLE,
    NET_IPV6_NBR_STATE_STALE,
    NET_IPV6_NBR_STATE_DELAY,
    NET_IPV6_NBR_STATE_PROBE,
    NET_IPV6_NBR_STATE_STATIC


proc net_ipv6_nbr_state2str*(state: net_ipv6_nbr_state): cstring {.
    importc: "net_ipv6_nbr_state2str", header: hdr.}
## *
##  @brief IPv6 neighbor information.
##

type
  net_ipv6_nbr_data* {.importc: "struct net_ipv6_nbr_data", header: hdr, bycopy, incompleteStruct.} = object
    pending* {.importc: "pending".}: ptr net_pkt_alias ## * Any pending packet waiting ND to finish.
    ## * IPv6 ipaddress.
    iaddr* {.importc: "ipaddr".}: In6Addr ## * Reachable timer.
    reachable* {.importc: "reachable".}: int64 ## * Reachable timeout
    reachable_timeout* {.importc: "reachable_timeout".}: int32 ## * Neighbor Solicitation reply timer
    send_ns* {.importc: "send_ns".}: int64 ## * State of the neighbor discovery
    state* {.importc: "state".}: net_ipv6_nbr_state ## * Link metric for the neighbor
    link_metric* {.importc: "link_metric".}: uint16 ## * How many times we have sent NS
    ns_count* {.importc: "ns_count".}: uint8 ## * Is the neighbor a router
    is_router* {.importc: "is_router".}: bool
    # when defined(CONFIG_NET_IPV6_NBR_CACHE) or defined(CONFIG_NET_IPV6_ND):
    #   ## * Stale counter used to removed oldest nbr in STALE state,
    #   ##   when table is full.
    #   stale_counter* {.importc: "stale_counter", header: hdr.}: uint32


proc net_ipv6_nbr_data_init*(nbr: ptr net_nbr_alias): ptr net_ipv6_nbr_data {.importc: "$1", header: hdr.}

when defined(CONFIG_NET_IPV6_DAD):
  proc net_ipv6_start_dad*(iface: ptr net_if; ifaddr: ptr net_if_addr): cint {.
      importc: "net_ipv6_start_dad", header: hdr.}
proc net_ipv6_send_ns*(iface: ptr net_if; pending: ptr net_pkt_alias; src: ptr In6Addr;
                      dst: ptr In6Addr; tgt: ptr In6Addr; is_my_address: bool): cint {.
    importc: "net_ipv6_send_ns", header: hdr.}
proc net_ipv6_send_rs*(iface: ptr net_if): cint {.importc: "net_ipv6_send_rs",
    header: hdr.}
proc net_ipv6_start_rs*(iface: ptr net_if): cint {.importc: "net_ipv6_start_rs",
    header: hdr.}
proc net_ipv6_send_na*(iface: ptr net_if; src: ptr In6Addr; dst: ptr In6Addr;
                      tgt: ptr In6Addr; flags: uint8): cint {.
    importc: "net_ipv6_send_na", header: hdr.}
proc net_ipv6_is_nexthdr_upper_layer*(nexthdr: uint8): bool {.importc: "$1", header: hdr.}

## *
##  @brief Create IPv6 packet in provided net_pkt_alias.
##
##  @param pkt Network packet
##  @param src Source IPv6 ipaddress
##  @param dst Destination IPv6 ipaddress
##
##  @return 0 on success, negative errno otherwise.
##

proc net_ipv6_create*(pkt: ptr net_pkt_alias; src: ptr In6Addr; dst: ptr In6Addr): cint {.
      importc: "net_ipv6_create", header: hdr.}

## *
##  @brief Finalize IPv6 packet. It should be called right before
##  sending the packet and after all the data has been added into
##  the packet. This function will set the length of the
##  packet and calculate the higher protocol checksum if needed.
##
##  @param pkt Network packet
##  @param next_header_proto Protocol type of the next header after IPv6 header.
##
##  @return 0 on success, negative errno otherwise.
##

proc net_ipv6_finalize*(pkt: ptr net_pkt_alias; next_header_proto: uint8): cint {.
      importc: "net_ipv6_finalize", header: hdr.}

## *
##  @brief Join a given multicast group.
##
##  @param iface Network interface where join message is sent
##  @param ipaddr Multicast group to join
##
##  @return Return 0 if joining was done, <0 otherwise.
##

proc net_ipv6_mld_join*(iface: ptr net_if; ipaddr: ptr In6Addr): cint {.
      importc: "net_ipv6_mld_join", header: hdr.}

## *
##  @brief Leave a given multicast group.
##
##  @param iface Network interface where leave message is sent
##  @param ipaddr Multicast group to leave
##
##  @return Return 0 if leaving is done, <0 otherwise.
##

proc net_ipv6_mld_leave*(iface: ptr net_if; `ipaddr`: ptr In6Addr): cint {.
      importc: "net_ipv6_mld_leave", header: hdr.}


## *
##  @typedef net_nbr_cb_t
##  @brief Callback used while iterating over neighbors.
##
##  @param nbr A valid pointer on current neighbor.
##  @param user_data A valid pointer on some user data or NULL
##

type
  net_nbr_cb_t* = proc (nbr: ptr net_nbr_alias; user_data: pointer)

## *
##  @brief Make sure the link layer ipaddress is set according to
##  destination ipaddress. If the ll ipaddress is not yet known, then
##  start neighbor discovery to find it out. If ND needs to be done
##  then the returned packet is the Neighbor Solicitation message
##  and the original message is sent after Neighbor Advertisement
##  message is received.
##
##  @param pkt Network packet
##
##  @return Return a verdict.
##

when defined(CONFIG_NET_IPV6_NBR_CACHE) and defined(CONFIG_NET_NATIVE_IPV6):
  proc net_ipv6_prepare_for_send*(pkt: ptr net_pkt_alias): net_verdict {.
      importc: "net_ipv6_prepare_for_send", header: hdr.}
else:
  proc net_ipv6_prepare_for_send*(pkt: ptr net_pkt_alias): net_verdict {.inline.} =
    return NET_OK

## *
##  @brief Look for a neighbor from it's ipaddress on an iface
##
##  @param iface A valid pointer on a network interface
##  @param ipaddr The IPv6 ipaddress to match
##
##  @return A valid pointer on a neighbor on success, NULL otherwise
##

when defined(CONFIG_NET_IPV6_NBR_CACHE) and defined(CONFIG_NET_NATIVE_IPV6):
  proc net_ipv6_nbr_lookup*(iface: ptr net_if; `ipaddr`: ptr In6Addr): ptr net_nbr_alias {.
      importc: "net_ipv6_nbr_lookup", header: hdr.}

## *
##  @brief Get neighbor from its index.
##
##  @param iface Network interface to match. If NULL, then use
##  whatever interface there is configured for the neighbor ipaddress.
##  @param idx Index of the link layer ipaddress in the ipaddress array
##
##  @return A valid pointer on a neighbor on success, NULL otherwise
##

proc net_ipv6_get_nbr*(iface: ptr net_if; idx: uint8): ptr net_nbr_alias {.
    importc: "net_ipv6_get_nbr", header: hdr.}
## *
##  @brief Look for a neighbor from it's link local ipaddress index
##
##  @param iface Network interface to match. If NULL, then use
##  whatever interface there is configured for the neighbor ipaddress.
##  @param idx Index of the link layer ipaddress in the ipaddress array
##
##  @return A valid pointer on a neighbor on success, NULL otherwise
##

when defined(CONFIG_NET_IPV6_NBR_CACHE) and defined(CONFIG_NET_NATIVE_IPV6):
  proc net_ipv6_nbr_lookup_by_index*(iface: ptr net_if; idx: uint8): ptr In6Addr {.
      importc: "net_ipv6_nbr_lookup_by_index", header: hdr.}
else:
  proc net_ipv6_nbr_lookup_by_index*(iface: ptr net_if; idx: uint8): ptr In6Addr {.
      inline.} =
    return nil

## *
##  @brief Add a neighbor to neighbor cache
##
##  Add a neighbor to the cache after performing a lookup and in case
##  there exists an entry in the cache update its state and lladdr.
##
##  @param iface A valid pointer on a network interface
##  @param ipaddr Neighbor IPv6 ipaddress
##  @param lladdr Neighbor link layer ipaddress
##  @param is_router Set to true if the neighbor is a router, false
##  otherwise
##  @param state Initial state of the neighbor entry in the cache
##
##  @return A valid pointer on a neighbor on success, NULL otherwise
##

proc net_ipv6_nbr_add*(iface: ptr net_if; `ipaddr`: ptr In6Addr;
                      lladdr: ptr net_linkaddr; is_router: bool;
                      state: net_ipv6_nbr_state): ptr net_nbr_alias {.
      importc: "net_ipv6_nbr_add", header: hdr.}

## *
##  @brief Remove a neighbor from neighbor cache.
##
##  @param iface A valid pointer on a network interface
##  @param ipaddr Neighbor IPv6 ipaddress
##
##  @return True if neighbor could be removed, False otherwise
##

proc net_ipv6_nbr_rm*(iface: ptr net_if; `ipaddr`: ptr In6Addr): bool {.
    importc: "net_ipv6_nbr_rm", header: hdr.}

## *
##  @brief Go through all the neighbors and call callback for each of them.
##
##  @param cb User supplied callback function to call.
##  @param user_data User specified data.
##

proc net_ipv6_nbr_foreach*(cb: net_nbr_cb_t; user_data: pointer) {.
    importc: "net_ipv6_nbr_foreach", header: hdr.}

## *
##  @brief Set the neighbor reachable timer.
##
##  @param iface A valid pointer on a network interface
##  @param nbr Neighbor struct pointer
##

proc net_ipv6_nbr_set_reachable_timer*(iface: ptr net_if; nbr: ptr net_nbr_alias) {.
      importc: "net_ipv6_nbr_set_reachable_timer", header: hdr.}

when CONFIG_NET_IPV6_FRAGMENT:

  ## * Store pending IPv6 fragment information that is needed for reassembly.
  type
    net_ipv6_reassembly* {.importc: "net_ipv6_reassembly", header: hdr, bycopy.} = object
      src* {.importc: "src".}: In6Addr ## * IPv6 source ipaddress of the fragment
      ## * IPv6 destination ipaddress of the fragment
      dst* {.importc: "dst".}: In6Addr ## *
                                    ##  Timeout for cancelling the reassembly. The timer is used
                                    ##  also to detect if this reassembly slot is used or not.
                                    ##
      timer* {.importc: "timer".}: k_work_delayable ## * Pointers to pending fragments
      pkt* {.importc: "pkt".}: array[CONFIG_NET_IPV6_FRAGMENT_MAX_PKT, ptr net_pkt_alias] ## *
                                                                              ## IPv6
                                                                              ## fragment
                                                                              ## identification
      id* {.importc: "id".}: uint32

  ## *
  ##  @typedef net_ipv6_frag_cb_t
  ##  @brief Callback used while iterating over pending IPv6 fragments.
  ##
  ##  @param reass IPv6 fragment reassembly struct
  ##  @param user_data A valid pointer on some user data or NULL
  ##

  type
    net_ipv6_frag_cb_t* = proc (reass: ptr net_ipv6_reassembly; user_data: pointer)

  ## *
  ##  @brief Go through all the currently pending IPv6 fragments.
  ##
  ##  @param cb Callback to call for each pending IPv6 fragment.
  ##  @param user_data User specified data or NULL.
  ##

  proc net_ipv6_frag_foreach*(cb: net_ipv6_frag_cb_t; user_data: pointer) {.
      importc: "net_ipv6_frag_foreach", header: hdr.}
  ## *
  ##  @brief Find the last IPv6 extension header in the network packet.
  ##
  ##  @param pkt Network head packet.
  ##  @param next_hdr_off Offset of the next header field that points
  ##  to last header. This is returned to caller.
  ##  @param last_hdr_off Offset of the last header field in the packet.
  ##  This is returned to caller.
  ##
  ##  @return 0 on success, a negative errno otherwise.
  ##

  proc net_ipv6_find_last_ext_hdr*(pkt: ptr net_pkt_alias; next_hdr_off: ptr uint16;
                                  last_hdr_off: ptr uint16): cint {.
      importc: "net_ipv6_find_last_ext_hdr", header: hdr.}
  ## *
  ##  @brief Handles IPv6 fragmented packets.
  ##
  ##  @param pkt     Network head packet.
  ##  @param hdr     The IPv6 header of the current packet
  ##  @param nexthdr IPv6 next header after fragment header part
  ##
  ##  @return Return verdict about the packet
  ##

  proc net_ipv6_handle_fragment_hdr*(pkt: ptr net_pkt_alias; hdr: ptr net_ipv6_hdr;
                                    nexthdr: uint8): net_verdict {.
      importc: "net_ipv6_handle_fragment_hdr", header: hdr.}

  proc net_ipv6_init*() {.importc: "net_ipv6_init", header: hdr.}
  proc net_ipv6_nbr_init*() {.importc: "net_ipv6_nbr_init", header: hdr.}
