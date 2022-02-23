##
##  Copyright (c) 2016 Intel Corporation.
##
##  SPDX-License-Identifier: Apache-2.0
##
## *
##  @file
##  @brief Public API for network link address
##

## *
##  @brief Network link address library
##  @defgroup net_linkaddr Network Link Address Library
##  @ingroup networking
##  @{
##
## * Maximum length of the link address

import ../zconfs

const hdr = "<net/net_linkaddr.h>"

const
  NET_LINK_ADDR_MAX_LENGTH* = 
    when CONFIG_NET_L2_IEEE802154:
      8
    elif CONFIG_NET_L2_PPP:
      8
    else:
      6

## *
##  Type of the link address. This indicates the network technology that this
##  address is used in. Note that in order to save space we store the value
##  into a uint8_t variable, so please do not introduce any values > 255 in
##  this enum.
##
##  packed

type
  net_link_type* {.size: sizeof(uint8).} = enum ## * Unknown link address type.
    NET_LINK_UNKNOWN = 0,       ## * IEEE 802.15.4 link address.
    NET_LINK_IEEE802154,      ## * Bluetooth IPSP link address.
    NET_LINK_BLUETOOTH,       ## * Ethernet link address.
    NET_LINK_ETHERNET,        ## * Dummy link address. Used in testing apps and loopback support.
    NET_LINK_DUMMY,           ## * CANBUS link address.
    NET_LINK_CANBUS_RAW,      ## * 6loCAN link address.
    NET_LINK_CANBUS


## *
##   @brief Hardware link address structure
##
##   Used to hold the link address information
##

type
  net_linkaddr* {.importc: "net_linkaddr", header: hdr, bycopy.} = object
    caddr* {.importc: "addr".}: ptr uint8 ## * The array of byte representing the address
    ## * Length of that address array
    len* {.importc: "len".}: uint8 ## * What kind of address is this for
    ctype* {.importc: "type".}: uint8


## *
##   @brief Hardware link address structure
##
##   Used to hold the link address information. This variant is needed
##   when we have to store the link layer address.
##
##   Note that you cannot cast this to net_linkaddr as uint8_t * is
##   handled differently than uint8_t addr[] and the fields are purposely
##   in different order.
##

type
  net_linkaddr_storage* {.importc: "net_linkaddr_storage",
                         header: hdr, bycopy.} = object
    ctype* {.importc: "type".}: uint8 ## * What kind of address is this for
    ## * The real length of the ll address.
    len* {.importc: "len".}: uint8 ## * The array of bytes representing the address
    caddr* {.importc: "addr".}: array[NET_LINK_ADDR_MAX_LENGTH, uint8]


## *
##  @brief Compare two link layer addresses.
##
##  @param lladdr1 Pointer to a link layer address
##  @param lladdr2 Pointer to a link layer address
##
##  @return True if the addresses are the same, false otherwise.
##

proc net_linkaddr_cmp*(lladdr1: ptr net_linkaddr; lladdr2: ptr net_linkaddr): bool {.
    importc: "$1", header: hdr.}

## *
##
##  @brief Set the member data of a link layer address storage structure.
##
##  @param lladdr_store The link address storage structure to change.
##  @param new_addr Array of bytes containing the link address.
##  @param new_len Length of the link address array.
##  This value should always be <= NET_LINK_ADDR_MAX_LENGTH.
##

proc net_linkaddr_set*(lladdr_store: ptr net_linkaddr_storage; new_addr: ptr uint8;
                      new_len: uint8): cint {.importc: "$1", header: hdr.}

## *
##  @}
##
