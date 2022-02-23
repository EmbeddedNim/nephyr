## * @file
##  @brief Network core definitions
##
##  Definitions for networking support.
##
##
##  Copyright (c) 2015 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief Networking
##  @defgroup networking Networking
##  @{
##  @}
##
## *
##  @brief Network core library
##  @defgroup net_core Network Core Library
##  @ingroup networking
##  @{
##
## * @cond INTERNAL_HIDDEN
##  Network subsystem logging helpers

type
  net_if_alias* {.incompleteStruct, bycopy.} = distinct object
  net_pkt_alias* {.incompleteStruct, bycopy.} = distinct object
  net_offload_alias* {.incompleteStruct, bycopy.} = distinct object

  net_verdict* {.size: sizeof(cint).} = enum
    NET_OK, ##\
      ## * Packet has been taken care of.
    NET_CONTINUE, ##\
      ## * Packet has not been touched, other part should decide about its
      ##  fate.
    NET_DROP ##\
      ## * Packet must be dropped.


## *
##  @brief Called by lower network stack or network device driver when
##  a network packet has been received. The function will push the packet up in
##  the network stack for further processing.
##
##  @param iface Network interface where the packet was received.
##  @param pkt Network packet data.
##
##  @return 0 if ok, <0 if error.
##

# TODO: FIXME
# proc net_recv_data*(iface: ptr net_if; pkt: ptr net_pkt): cint {.
    # importc: "net_recv_data", header: "net_core.h".}

## *
##  @brief Send data to network.
##
##  @details Send data to network. This should not be used normally by
##  applications as it requires that the network packet is properly
##  constructed.
##
##  @param pkt Network packet.
##
##  @return 0 if ok, <0 if error. If <0 is returned, then the caller needs
##  to unref the pkt in order to avoid memory leak.
##

# TODO: FIXME
# proc net_send_data*(pkt: ptr net_pkt): cint {.importc: "net_send_data",
    # header: "net_core.h".}

var NET_TC_TX_COUNT* {.importc: "NET_TC_TX_COUNT", header: "net_core.h".}: cint
var NET_TC_RX_COUNT* {.importc: "NET_TC_RX_COUNT", header: "net_core.h".}: cint
var NET_TC_COUNT* {.importc: "NET_TC_COUNT", header: "net_core.h".}: cint

##  @endcond
## *
##  @}
##
