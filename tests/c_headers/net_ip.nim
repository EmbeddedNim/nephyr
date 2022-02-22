## * @file
##  @brief IPv6 and IPv4 definitions
##
##  Generic IPv6 and IPv4 address definitions.
##
##
##  Copyright (c) 2016 Intel Corporation
##
##  SPDX-License-Identifier: Apache-2.0
##

## *
##  @brief IPv4/IPv6 primitives and helpers
##  @defgroup ip_4_6 IPv4/IPv6 primitives and helpers
##  @ingroup networking
##  @{
##

## * @cond INTERNAL_HIDDEN
##  Specifying VLAN tag here in order to avoid circular dependencies

var PF_UNSPEC* {.importc: "PF_UNSPEC", header: "net_ip.h".}: int
##  Address families.

var AF_UNSPEC* {.importc: "AF_UNSPEC", header: "net_ip.h".}: int
## * Protocol numbers from IANA/BSD

type
  net_ip_protocol* {.size: sizeof(uint16).} = enum
    IPPROTO_IP = 0,             ## *< IP protocol (pseudo-val for setsockopt()
    IPPROTO_ICMP = 1,           ## *< ICMP protocol
    IPPROTO_IGMP = 2,           ## *< IGMP protocol
    IPPROTO_IPIP = 4,           ## *< IPIP tunnels
    IPPROTO_TCP = 6,            ## *< TCP protocol
    IPPROTO_UDP = 17,           ## *< UDP protocol
    IPPROTO_IPV6 = 41,          ## *< IPv6 protocol
    IPPROTO_ICMPV6 = 58,        ## *< ICMPv6 protocol
    IPPROTO_RAW = 255           ## *< RAW IP packets


## * Protocol numbers for TLS protocols

type
  net_ip_protocol_secure* {.size: sizeof(uint16).} = enum
    IPPROTO_TLS_1_0 = 256,      ## *< TLS 1.0 protocol
    IPPROTO_TLS_1_1 = 257,      ## *< TLS 1.1 protocol
    IPPROTO_TLS_1_2 = 258,      ## *< TLS 1.2 protocol
    IPPROTO_DTLS_1_0 = 272,     ## *< DTLS 1.0 protocol
    IPPROTO_DTLS_1_2 = 273      ## *< DTLS 1.2 protocol


## * Socket type

type
  net_sock_type* {.size: sizeof(uint16).} = enum
    SOCK_STREAM = 1,            ## *< Stream socket type
    SOCK_DGRAM,               ## *< Datagram socket type
    SOCK_RAW                  ## *< RAW socket type


## * @brief Convert 16-bit value from network to host byte order.
##
##  @param x The network byte order value to convert.
##
##  @return Host byte order value.
##

proc ntohs*(x: untyped) {.importc: "ntohs", header: "net_ip.h".}
## * @brief Convert 32-bit value from network to host byte order.
##
##  @param x The network byte order value to convert.
##
##  @return Host byte order value.
##

proc ntohl*(x: untyped) {.importc: "ntohl", header: "net_ip.h".}
## * @brief Convert 64-bit value from network to host byte order.
##
##  @param x The network byte order value to convert.
##
##  @return Host byte order value.
##

proc ntohll*(x: untyped) {.importc: "ntohll", header: "net_ip.h".}
## * @brief Convert 16-bit value from host to network byte order.
##
##  @param x The host byte order value to convert.
##
##  @return Network byte order value.
##

proc htons*(x: untyped) {.importc: "htons", header: "net_ip.h".}
## * @brief Convert 32-bit value from host to network byte order.
##
##  @param x The host byte order value to convert.
##
##  @return Network byte order value.
##

proc htonl*(x: untyped) {.importc: "htonl", header: "net_ip.h".}
## * @brief Convert 64-bit value from host to network byte order.
##
##  @param x The host byte order value to convert.
##
##  @return Network byte order value.
##

proc htonll*(x: untyped) {.importc: "htonll", header: "net_ip.h".}
## * IPv6 address struct

type
  INNER_C_UNION_net_ip_0* {.importc: "no_name", header: "net_ip.h", bycopy, union.} = object
    s6_addr* {.importc: "s6_addr".}: array[16, uint8]
    s6_addr16* {.importc: "s6_addr16".}: array[8, uint16] ##  In big endian
    s6_addr32* {.importc: "s6_addr32".}: array[4, uint32] ##  In big endian

  in6_addr* {.importc: "in6_addr", header: "net_ip.h", bycopy.} = object
    ano_net_ip_1* {.importc: "ano_net_ip_1".}: INNER_C_UNION_net_ip_0


## * IPv4 address struct

type
  INNER_C_UNION_net_ip_2* {.importc: "no_name", header: "net_ip.h", bycopy, union.} = object
    s4_addr* {.importc: "s4_addr".}: array[4, uint8]
    s4_addr16* {.importc: "s4_addr16".}: array[2, uint16] ##  In big endian
    s4_addr32* {.importc: "s4_addr32".}: array[1, uint32] ##  In big endian
    s_addr* {.importc: "s_addr".}: uint32 ##  In big endian, for POSIX compatibility.

  in_addr* {.importc: "in_addr", header: "net_ip.h", bycopy.} = object
    ano_net_ip_3* {.importc: "ano_net_ip_3".}: INNER_C_UNION_net_ip_2


## * Socket address family type

type
  sa_family_t* = uint16

## * Length of a socket address

type
  socklen_t* = csize_t

##
##  Note that the sin_port and sin6_port are in network byte order
##  in various sockaddr* structs.
##
## * Socket address struct for IPv6.

type
  sockaddr_in6* {.importc: "sockaddr_in6", header: "net_ip.h", bycopy.} = object
    sin6_family* {.importc: "sin6_family".}: sa_family_t ##  AF_INET6
    sin6_port* {.importc: "sin6_port".}: uint16 ##  Port number
    sin6_addr* {.importc: "sin6_addr".}: in6_addr ##  IPv6 address
    sin6_scope_id* {.importc: "sin6_scope_id".}: uint8 ##  interfaces for a scope

  sockaddr_in6_ptr* {.importc: "sockaddr_in6_ptr", header: "net_ip.h", bycopy.} = object
    sin6_family* {.importc: "sin6_family".}: sa_family_t ##  AF_INET6
    sin6_port* {.importc: "sin6_port".}: uint16 ##  Port number
    sin6_addr* {.importc: "sin6_addr".}: ptr in6_addr ##  IPv6 address
    sin6_scope_id* {.importc: "sin6_scope_id".}: uint8 ##  interfaces for a scope


## * Socket address struct for IPv4.

type
  sockaddr_in* {.importc: "sockaddr_in", header: "net_ip.h", bycopy.} = object
    sin_family* {.importc: "sin_family".}: sa_family_t ##  AF_INET
    sin_port* {.importc: "sin_port".}: uint16 ##  Port number
    sin_addr* {.importc: "sin_addr".}: in_addr ##  IPv4 address

  sockaddr_in_ptr* {.importc: "sockaddr_in_ptr", header: "net_ip.h", bycopy.} = object
    sin_family* {.importc: "sin_family".}: sa_family_t ##  AF_INET
    sin_port* {.importc: "sin_port".}: uint16 ##  Port number
    sin_addr* {.importc: "sin_addr".}: ptr in_addr ##  IPv4 address


## * Socket address struct for packet socket.

type
  sockaddr_ll* {.importc: "sockaddr_ll", header: "net_ip.h", bycopy.} = object
    sll_family* {.importc: "sll_family".}: sa_family_t ##  Always AF_PACKET
    sll_protocol* {.importc: "sll_protocol".}: uint16 ##  Physical-layer protocol
    sll_ifindex* {.importc: "sll_ifindex".}: cint ##  Interface number
    sll_hatype* {.importc: "sll_hatype".}: uint16 ##  ARP hardware type
    sll_pkttype* {.importc: "sll_pkttype".}: uint8 ##  Packet type
    sll_halen* {.importc: "sll_halen".}: uint8 ##  Length of address
    sll_addr* {.importc: "sll_addr".}: array[8, uint8] ##  Physical-layer address

  sockaddr_ll_ptr* {.importc: "sockaddr_ll_ptr", header: "net_ip.h", bycopy.} = object
    sll_family* {.importc: "sll_family".}: sa_family_t ##  Always AF_PACKET
    sll_protocol* {.importc: "sll_protocol".}: uint16 ##  Physical-layer protocol
    sll_ifindex* {.importc: "sll_ifindex".}: cint ##  Interface number
    sll_hatype* {.importc: "sll_hatype".}: uint16 ##  ARP hardware type
    sll_pkttype* {.importc: "sll_pkttype".}: uint8 ##  Packet type
    sll_halen* {.importc: "sll_halen".}: uint8 ##  Length of address
    sll_addr* {.importc: "sll_addr".}: ptr uint8 ##  Physical-layer address

  sockaddr_can_ptr* {.importc: "sockaddr_can_ptr", header: "net_ip.h", bycopy.} = object
    can_family* {.importc: "can_family".}: sa_family_t
    can_ifindex* {.importc: "can_ifindex".}: cint


when not defined(HAVE_IOVEC):
  type
    iovec* {.importc: "iovec", header: "net_ip.h", bycopy.} = object
      iov_base* {.importc: "iov_base".}: pointer
      iov_len* {.importc: "iov_len".}: csize_t

type
  msghdr* {.importc: "msghdr", header: "net_ip.h", bycopy.} = object
    msg_name* {.importc: "msg_name".}: pointer ##  optional socket address
    msg_namelen* {.importc: "msg_namelen".}: socklen_t ##  size of socket address
    msg_iov* {.importc: "msg_iov".}: ptr iovec ##  scatter/gather array
    msg_iovlen* {.importc: "msg_iovlen".}: csize_t ##  number of elements in msg_iov
    msg_control* {.importc: "msg_control".}: pointer ##  ancillary data
    msg_controllen* {.importc: "msg_controllen".}: csize_t ##  ancillary data buffer len
    msg_flags* {.importc: "msg_flags".}: cint ##  flags on received message

  cmsghdr* {.importc: "cmsghdr", header: "net_ip.h", bycopy.} = object
    cmsg_len* {.importc: "cmsg_len".}: socklen_t ##  Number of bytes, including header
    cmsg_level* {.importc: "cmsg_level".}: cint ##  Originating protocol
    cmsg_type* {.importc: "cmsg_type".}: cint ##  Protocol-specific type
                                          ##  Flexible array member to force alignment of cmsghdr
    cmsg_data* {.importc: "cmsg_data".}: UncheckedArray[z_max_align_t]


##  Alignment for headers and data. These are arch specific but define
##  them here atm if not found alredy.
##

when not defined(ALIGN_H):
  proc ALIGN_H*(x: untyped) {.importc: "ALIGN_H", header: "net_ip.h".}
when not defined(ALIGN_D):
  proc ALIGN_D*(x: untyped) {.importc: "ALIGN_D", header: "net_ip.h".}
when not defined(CMSG_FIRSTHDR):
  proc CMSG_FIRSTHDR*(msghdr: untyped) {.importc: "CMSG_FIRSTHDR", header: "net_ip.h".}
when not defined(CMSG_NXTHDR):
  proc CMSG_NXTHDR*(msghdr: untyped; cmsg: untyped) {.importc: "CMSG_NXTHDR",
      header: "net_ip.h".}
when not defined(CMSG_DATA):
  proc CMSG_DATA*(cmsg: untyped) {.importc: "CMSG_DATA", header: "net_ip.h".}
when not defined(CMSG_SPACE):
  proc CMSG_SPACE*(length: untyped) {.importc: "CMSG_SPACE", header: "net_ip.h".}
when not defined(CMSG_LEN):
  proc CMSG_LEN*(length: untyped) {.importc: "CMSG_LEN", header: "net_ip.h".}
## * @cond INTERNAL_HIDDEN
##  Packet types.

var PACKET_HOST* {.importc: "PACKET_HOST", header: "net_ip.h".}: int
##  Note: These macros are defined in a specific order.
##  The largest sockaddr size is the last one.
##

when defined(CONFIG_NET_IPV4):
  var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE", header: "net_ip.h".}: int
when defined(CONFIG_NET_SOCKETS_PACKET):
  var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE", header: "net_ip.h".}: int
when defined(CONFIG_NET_IPV6):
  var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE", header: "net_ip.h".}: int
  when not defined(CONFIG_NET_SOCKETS_PACKET):
    var NET_SOCKADDR_PTR_MAX_SIZE* {.importc: "NET_SOCKADDR_PTR_MAX_SIZE",
                                   header: "net_ip.h".}: int
when not defined(CONFIG_NET_IPV4):
  when not defined(CONFIG_NET_IPV6):
    when not defined(CONFIG_NET_SOCKETS_PACKET):
      var NET_SOCKADDR_MAX_SIZE* {.importc: "NET_SOCKADDR_MAX_SIZE",
                                 header: "net_ip.h".}: int
## * @endcond
## * Generic sockaddr struct. Must be cast to proper type.

type
  sockaddr* {.importc: "sockaddr", header: "net_ip.h", bycopy.} = object
    sa_family* {.importc: "sa_family".}: sa_family_t
    data* {.importc: "data".}: array[NET_SOCKADDR_MAX_SIZE - sizeof((sa_family_t)),
                                  char]


## * @cond INTERNAL_HIDDEN

type
  sockaddr_ptr* {.importc: "sockaddr_ptr", header: "net_ip.h", bycopy.} = object
    family* {.importc: "family".}: sa_family_t
    data* {.importc: "data".}: array[NET_SOCKADDR_PTR_MAX_SIZE -
        sizeof((sa_family_t)), char]


##  Same as sockaddr in our case

type
  sockaddr_storage* {.importc: "sockaddr_storage", header: "net_ip.h", bycopy.} = object
    ss_family* {.importc: "ss_family".}: sa_family_t
    data* {.importc: "data".}: array[NET_SOCKADDR_MAX_SIZE - sizeof((sa_family_t)),
                                  char]


##  Socket address struct for UNIX domain sockets

type
  sockaddr_un* {.importc: "sockaddr_un", header: "net_ip.h", bycopy.} = object
    sun_family* {.importc: "sun_family".}: sa_family_t ##  AF_UNIX
    sun_path* {.importc: "sun_path".}: array[
        NET_SOCKADDR_MAX_SIZE - sizeof((sa_family_t)), char]

  INNER_C_UNION_net_ip_4* {.importc: "no_name", header: "net_ip.h", bycopy, union.} = object
    in6_addr* {.importc: "in6_addr".}: in6_addr
    in_addr* {.importc: "in_addr".}: in_addr

  net_addr* {.importc: "net_addr", header: "net_ip.h", bycopy.} = object
    family* {.importc: "family".}: sa_family_t
    ano_net_ip_5* {.importc: "ano_net_ip_5".}: INNER_C_UNION_net_ip_4


var IN6ADDR_ANY_INIT* {.importc: "IN6ADDR_ANY_INIT", header: "net_ip.h".}: int
let in6addr_any* {.importc: "in6addr_any", header: "net_ip.h".}: in6_addr

let in6addr_loopback* {.importc: "in6addr_loopback", header: "net_ip.h".}: in6_addr

## * @endcond
## * Max length of the IPv4 address as a string. Defined by POSIX.

var INET_ADDRSTRLEN* {.importc: "INET_ADDRSTRLEN", header: "net_ip.h".}: int
## * Max length of the IPv6 address as a string. Takes into account possible
##  mapped IPv4 addresses.
##

var INET6_ADDRSTRLEN* {.importc: "INET6_ADDRSTRLEN", header: "net_ip.h".}: int
## * @cond INTERNAL_HIDDEN
##  These are for internal usage of the stack

var NET_IPV6_ADDR_LEN* {.importc: "NET_IPV6_ADDR_LEN", header: "net_ip.h".}: int
## * @endcond

type
  net_ip_mtu* {.size: sizeof(cint).} = enum ## * IPv6 MTU length. We must be able to receive this size IPv6 packet
                                       ##  without fragmentation.
                                       ##
    NET_IPV4_MTU = 576, NET_IPV6_MTU = 1280 ## * IPv4 MTU length. We must be able to receive this size IPv4 packet
                                      ##  without fragmentation.
                                      ##


## * Network packet priority settings described in IEEE 802.1Q Annex I.1

type
  net_priority* {.size: sizeof(uint8).} = enum
    NET_PRIORITY_BE = 0,        ## *< Best effort (default)
    NET_PRIORITY_BK = 1,        ## *< Background (lowest)
    NET_PRIORITY_EE = 2,        ## *< Excellent effort
    NET_PRIORITY_CA = 3,        ## *< Critical applications (highest)
    NET_PRIORITY_VI = 4,        ## *< Video, < 100 ms latency and jitter
    NET_PRIORITY_VO = 5,        ## *< Voice, < 10 ms latency and jitter
    NET_PRIORITY_IC = 6,        ## *< Internetwork control
    NET_PRIORITY_NC = 7


var NET_MAX_PRIORITIES* {.importc: "NET_MAX_PRIORITIES", header: "net_ip.h".}: int
## * IPv6/IPv4 network connection tuple

type
  net_tuple* {.importc: "net_tuple", header: "net_ip.h", bycopy.} = object
    remote_addr* {.importc: "remote_addr".}: ptr net_addr ## *< IPv6/IPv4 remote address
    local_addr* {.importc: "local_addr".}: ptr net_addr ## *< IPv6/IPv4 local address
    remote_port* {.importc: "remote_port".}: uint16 ## *< UDP/TCP remote port
    local_port* {.importc: "local_port".}: uint16 ## *< UDP/TCP local port
    ip_proto* {.importc: "ip_proto".}: net_ip_protocol ## *< IP protocol


## * What is the current state of the network address

type
  net_addr_state* {.size: sizeof(uint8).} = enum
    NET_ADDR_ANY_STATE = -1,    ## *< Default (invalid) address type
    NET_ADDR_TENTATIVE = 0,     ## *< Tentative address
    NET_ADDR_PREFERRED,       ## *< Preferred address
    NET_ADDR_DEPRECATED       ## *< Deprecated address


## * How the network address is assigned to network interface

type
  net_addr_type* {.size: sizeof(uint8).} = enum ## * Default value. This is not a valid value.
    NET_ADDR_ANY = 0,           ## * Auto configured address
    NET_ADDR_AUTOCONF,        ## * Address is from DHCP
    NET_ADDR_DHCP,            ## * Manually set address
    NET_ADDR_MANUAL,          ## * Manually set address which is overridable by DHCP
    NET_ADDR_OVERRIDABLE


## * @cond INTERNAL_HIDDEN

type
  net_ipv6_hdr* {.importc: "net_ipv6_hdr", header: "net_ip.h", bycopy, packed.} = object
    vtc* {.importc: "vtc".}: uint8
    tcflow* {.importc: "tcflow".}: uint8
    flow* {.importc: "flow".}: uint16
    len* {.importc: "len".}: uint16
    nexthdr* {.importc: "nexthdr".}: uint8
    hop_limit* {.importc: "hop_limit".}: uint8
    src* {.importc: "src".}: in6_addr
    dst* {.importc: "dst".}: in6_addr

  net_ipv6_frag_hdr* {.importc: "net_ipv6_frag_hdr", header: "net_ip.h", bycopy, packed.} = object
    nexthdr* {.importc: "nexthdr".}: uint8
    reserved* {.importc: "reserved".}: uint8
    offset* {.importc: "offset".}: uint16
    id* {.importc: "id".}: uint32

  net_ipv4_hdr* {.importc: "net_ipv4_hdr", header: "net_ip.h", bycopy, packed.} = object
    vhl* {.importc: "vhl".}: uint8
    tos* {.importc: "tos".}: uint8
    len* {.importc: "len".}: uint16
    id* {.importc: "id".}: array[2, uint8]
    offset* {.importc: "offset".}: array[2, uint8]
    ttl* {.importc: "ttl".}: uint8
    proto* {.importc: "proto".}: uint8
    chksum* {.importc: "chksum".}: uint16
    src* {.importc: "src".}: in_addr
    dst* {.importc: "dst".}: in_addr

  net_icmp_hdr* {.importc: "net_icmp_hdr", header: "net_ip.h", bycopy, packed.} = object
    `type`* {.importc: "type".}: uint8
    code* {.importc: "code".}: uint8
    chksum* {.importc: "chksum".}: uint16

  net_udp_hdr* {.importc: "net_udp_hdr", header: "net_ip.h", bycopy, packed.} = object
    src_port* {.importc: "src_port".}: uint16
    dst_port* {.importc: "dst_port".}: uint16
    len* {.importc: "len".}: uint16
    chksum* {.importc: "chksum".}: uint16

  net_tcp_hdr* {.importc: "net_tcp_hdr", header: "net_ip.h", bycopy, packed.} = object
    src_port* {.importc: "src_port".}: uint16
    dst_port* {.importc: "dst_port".}: uint16
    seq* {.importc: "seq".}: array[4, uint8]
    ack* {.importc: "ack".}: array[4, uint8]
    offset* {.importc: "offset".}: uint8
    flags* {.importc: "flags".}: uint8
    wnd* {.importc: "wnd".}: array[2, uint8]
    chksum* {.importc: "chksum".}: uint16
    urg* {.importc: "urg".}: array[2, uint8]
    optdata* {.importc: "optdata".}: UncheckedArray[uint8]



proc net_addr_type2str*(`type`: net_addr_type): cstring =
  case `type`
  of NET_ADDR_AUTOCONF:
    return "AUTO"
  of NET_ADDR_DHCP:
    return "DHCP"
  of NET_ADDR_MANUAL:
    return "MANUAL"
  of NET_ADDR_OVERRIDABLE:
    return "OVERRIDE"
  of NET_ADDR_ANY:
    discard
  else:
    discard
  return "<unknown>"

##  IPv6 extension headers types

var NET_IPV6_NEXTHDR_HBHO* {.importc: "NET_IPV6_NEXTHDR_HBHO", header: "net_ip.h".}: int
## *
##  This 2 unions are here temporarily, as long as net_context.h will
##  be still public and not part of the core only.
##

type
  net_ip_header* {.importc: "net_ip_header", header: "net_ip.h", bycopy, union.} = object
    ipv4* {.importc: "ipv4".}: ptr net_ipv4_hdr
    ipv6* {.importc: "ipv6".}: ptr net_ipv6_hdr

  net_proto_header* {.importc: "net_proto_header", header: "net_ip.h", bycopy, union.} = object
    udp* {.importc: "udp".}: ptr net_udp_hdr
    tcp* {.importc: "tcp".}: ptr net_tcp_hdr


var NET_UDPH_LEN* {.importc: "NET_UDPH_LEN", header: "net_ip.h".}: int
## * @endcond
## *
##  @brief Check if the IPv6 address is a loopback address (::1).
##
##  @param addr IPv6 address
##
##  @return True if address is a loopback address, False otherwise.
##

proc net_ipv6_is_addr_loopback*(`addr`: ptr in6_addr): bool =
  return UNALIGNED_GET(addr(`addr`.s6_addr32[0])) == 0 and
      UNALIGNED_GET(addr(`addr`.s6_addr32[1])) == 0 and
      UNALIGNED_GET(addr(`addr`.s6_addr32[2])) == 0 and
      ntohl(UNALIGNED_GET(addr(`addr`.s6_addr32[3]))) == 1

## *
##  @brief Check if the IPv6 address is a multicast address.
##
##  @param addr IPv6 address
##
##  @return True if address is multicast address, False otherwise.
##

proc net_ipv6_is_addr_mcast*(`addr`: ptr in6_addr): bool =
  return `addr`.s6_addr[0] == 0xFF

discard "forward decl of net_if"
discard "forward decl of net_if_config"
proc net_if_ipv6_addr_lookup*(`addr`: ptr in6_addr; iface: ptr ptr net_if): ptr net_if_addr {.
    importc: "net_if_ipv6_addr_lookup", header: "net_ip.h".}
## *
##  @brief Check if IPv6 address is found in one of the network interfaces.
##
##  @param addr IPv6 address
##
##  @return True if address was found, False otherwise.
##

proc net_ipv6_is_my_addr*(`addr`: ptr in6_addr): bool =
  return net_if_ipv6_addr_lookup(`addr`, nil) != nil

proc net_if_ipv6_maddr_lookup*(`addr`: ptr in6_addr; iface: ptr ptr net_if): ptr net_if_mcast_addr {.
    importc: "net_if_ipv6_maddr_lookup", header: "net_ip.h".}
## *
##  @brief Check if IPv6 multicast address is found in one of the
##  network interfaces.
##
##  @param maddr Multicast IPv6 address
##
##  @return True if address was found, False otherwise.
##

proc net_ipv6_is_my_maddr*(maddr: ptr in6_addr): bool =
  return net_if_ipv6_maddr_lookup(maddr, nil) != nil

## *
##  @brief Check if two IPv6 addresses are same when compared after prefix mask.
##
##  @param addr1 First IPv6 address.
##  @param addr2 Second IPv6 address.
##  @param length Prefix length (max length is 128).
##
##  @return True if IPv6 prefixes are the same, False otherwise.
##

proc net_ipv6_is_prefix*(addr1: ptr uint8; addr2: ptr uint8; length: uint8): bool =
  var bits: uint8
  var bytes: uint8
  var remain: uint8
  var mask: uint8
  if length > 128:
    return false
  if memcmp(addr1, addr2, bytes):
    return false
  if not remain:
    ##  No remaining bits, the prefixes are the same as first
    ##  bytes are the same.
    ##
    return true
  mask = ((0xff shl (8 - remain)) xor 0xff) shl remain
  return (addr1[bytes] and mask) == (addr2[bytes] and mask)

## *
##  @brief Check if the IPv4 address is a loopback address (127.0.0.0/8).
##
##  @param addr IPv4 address
##
##  @return True if address is a loopback address, False otherwise.
##

proc net_ipv4_is_addr_loopback*(`addr`: ptr in_addr): bool =
  return `addr`.s4_addr[0] == 127'u

## *
##   @brief Check if the IPv4 address is unspecified (all bits zero)
##
##   @param addr IPv4 address.
##
##   @return True if the address is unspecified, false otherwise.
##

proc net_ipv4_is_addr_unspecified*(`addr`: ptr in_addr): bool =
  return UNALIGNED_GET(addr(`addr`.s_addr)) == 0

## *
##  @brief Check if the IPv4 address is a multicast address.
##
##  @param addr IPv4 address
##
##  @return True if address is multicast address, False otherwise.
##

proc net_ipv4_is_addr_mcast*(`addr`: ptr in_addr): bool =
  return (ntohl(UNALIGNED_GET(addr(`addr`.s_addr))) and 0xF0000000) == 0xE0000000

## *
##  @brief Check if the given IPv4 address is a link local address.
##
##  @param addr A valid pointer on an IPv4 address
##
##  @return True if it is, false otherwise.
##

proc net_ipv4_is_ll_addr*(`addr`: ptr in_addr): bool =
  return (ntohl(UNALIGNED_GET(addr(`addr`.s_addr))) and 0xA9FE0000) == 0xA9FE0000

## *
##   @def net_ipaddr_copy
##   @brief Copy an IPv4 or IPv6 address
##
##   @param dest Destination IP address.
##   @param src Source IP address.
##
##   @return Destination address.
##

proc net_ipaddr_copy*(dest: untyped; src: untyped) {.importc: "net_ipaddr_copy",
    header: "net_ip.h".}
## *
##   @brief Compare two IPv4 addresses
##
##   @param addr1 Pointer to IPv4 address.
##   @param addr2 Pointer to IPv4 address.
##
##   @return True if the addresses are the same, false otherwise.
##

proc net_ipv4_addr_cmp*(addr1: ptr in_addr; addr2: ptr in_addr): bool =
  return UNALIGNED_GET(addr(addr1.s_addr)) == UNALIGNED_GET(addr(addr2.s_addr))

## *
##   @brief Compare two IPv6 addresses
##
##   @param addr1 Pointer to IPv6 address.
##   @param addr2 Pointer to IPv6 address.
##
##   @return True if the addresses are the same, false otherwise.
##

proc net_ipv6_addr_cmp*(addr1: ptr in6_addr; addr2: ptr in6_addr): bool =
  return not memcmp(addr1, addr2, sizeof(in6_addr))

## *
##  @brief Check if the given IPv6 address is a link local address.
##
##  @param addr A valid pointer on an IPv6 address
##
##  @return True if it is, false otherwise.
##

proc net_ipv6_is_ll_addr*(`addr`: ptr in6_addr): bool =
  return UNALIGNED_GET(addr(`addr`.s6_addr16[0])) == htons(0xFE80)

## *
##  @brief Check if the given IPv6 address is a unique local address.
##
##  @param addr A valid pointer on an IPv6 address
##
##  @return True if it is, false otherwise.
##

proc net_ipv6_is_ula_addr*(`addr`: ptr in6_addr): bool =
  return `addr`.s6_addr[0] == 0xFD

## *
##  @brief Return pointer to any (all bits zeros) IPv6 address.
##
##  @return Any IPv6 address.
##

proc net_ipv6_unspecified_address*(): ptr in6_addr {.
    importc: "net_ipv6_unspecified_address", header: "net_ip.h".}
## *
##  @brief Return pointer to any (all bits zeros) IPv4 address.
##
##  @return Any IPv4 address.
##

proc net_ipv4_unspecified_address*(): ptr in_addr {.
    importc: "net_ipv4_unspecified_address", header: "net_ip.h".}
## *
##  @brief Return pointer to broadcast (all bits ones) IPv4 address.
##
##  @return Broadcast IPv4 address.
##

proc net_ipv4_broadcast_address*(): ptr in_addr {.
    importc: "net_ipv4_broadcast_address", header: "net_ip.h".}
discard "forward decl of net_if"
proc net_if_ipv4_addr_mask_cmp*(iface: ptr net_if; `addr`: ptr in_addr): bool {.
    importc: "net_if_ipv4_addr_mask_cmp", header: "net_ip.h".}
## *
##  @brief Check if the given address belongs to same subnet that
##  has been configured for the interface.
##
##  @param iface A valid pointer on an interface
##  @param addr IPv4 address
##
##  @return True if address is in same subnet, false otherwise.
##

proc net_ipv4_addr_mask_cmp*(iface: ptr net_if; `addr`: ptr in_addr): bool =
  return net_if_ipv4_addr_mask_cmp(iface, `addr`)

proc net_if_ipv4_is_addr_bcast*(iface: ptr net_if; `addr`: ptr in_addr): bool {.
    importc: "net_if_ipv4_is_addr_bcast", header: "net_ip.h".}
## *
##  @brief Check if the given IPv4 address is a broadcast address.
##
##  @param iface Interface to use. Must be a valid pointer to an interface.
##  @param addr IPv4 address
##
##  @return True if address is a broadcast address, false otherwise.
##

when defined(CONFIG_NET_NATIVE_IPV4):
  proc net_ipv4_is_addr_bcast*(iface: ptr net_if; `addr`: ptr in_addr): bool =
    if net_ipv4_addr_cmp(`addr`, net_ipv4_broadcast_address()):
      return true
    return net_if_ipv4_is_addr_bcast(iface, `addr`)

else:
  proc net_ipv4_is_addr_bcast*(iface: ptr net_if; `addr`: ptr in_addr): bool =
    ARG_UNUSED(iface)
    ARG_UNUSED(`addr`)
    return false

proc net_if_ipv4_addr_lookup*(`addr`: ptr in_addr; iface: ptr ptr net_if): ptr net_if_addr {.
    importc: "net_if_ipv4_addr_lookup", header: "net_ip.h".}
## *
##  @brief Check if the IPv4 address is assigned to any network interface
##  in the system.
##
##  @param addr A valid pointer on an IPv4 address
##
##  @return True if IPv4 address is found in one of the network interfaces,
##  False otherwise.
##

proc net_ipv4_is_my_addr*(`addr`: ptr in_addr): bool =
  var ret: bool
  ret = net_if_ipv4_addr_lookup(`addr`, nil) != nil
  if not ret:
    ret = net_ipv4_is_addr_bcast(nil, `addr`)
  return ret

## *
##   @brief Check if the IPv6 address is unspecified (all bits zero)
##
##   @param addr IPv6 address.
##
##   @return True if the address is unspecified, false otherwise.
##

proc net_ipv6_is_addr_unspecified*(`addr`: ptr in6_addr): bool =
  return UNALIGNED_GET(addr(`addr`.s6_addr32[0])) == 0 and
      UNALIGNED_GET(addr(`addr`.s6_addr32[1])) == 0 and
      UNALIGNED_GET(addr(`addr`.s6_addr32[2])) == 0 and
      UNALIGNED_GET(addr(`addr`.s6_addr32[3])) == 0

## *
##   @brief Check if the IPv6 address is solicited node multicast address
##   FF02:0:0:0:0:1:FFXX:XXXX defined in RFC 3513
##
##   @param addr IPv6 address.
##
##   @return True if the address is solicited node address, false otherwise.
##

proc net_ipv6_is_addr_solicited_node*(`addr`: ptr in6_addr): bool =
  return UNALIGNED_GET(addr(`addr`.s6_addr32[0])) == htonl(0xff020000) and
      UNALIGNED_GET(addr(`addr`.s6_addr32[1])) == 0x00000000 and
      UNALIGNED_GET(addr(`addr`.s6_addr32[2])) == htonl(0x00000001) and
      ((UNALIGNED_GET(addr(`addr`.s6_addr32[3])) and htonl(0xff000000)) ==
      htonl(0xff000000))

## *
##  @brief Check if the IPv6 address is a given scope multicast
##  address (FFyx::).
##
##  @param addr IPv6 address
##  @param scope Scope to check
##
##  @return True if the address is in given scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_scope*(`addr`: ptr in6_addr; scope: cint): bool =
  return (`addr`.s6_addr[0] == 0xff) and (`addr`.s6_addr[1] == scope)

## *
##  @brief Check if the IPv6 addresses have the same multicast scope (FFyx::).
##
##  @param addr_1 IPv6 address 1
##  @param addr_2 IPv6 address 2
##
##  @return True if both addresses have same multicast scope,
##  false otherwise.
##

proc net_ipv6_is_same_mcast_scope*(addr_1: ptr in6_addr; addr_2: ptr in6_addr): bool =
  return (addr_1.s6_addr[0] == 0xff) and (addr_2.s6_addr[0] == 0xff) and
      (addr_1.s6_addr[1] == addr_2.s6_addr[1])

## *
##  @brief Check if the IPv6 address is a global multicast address (FFxE::/16).
##
##  @param addr IPv6 address.
##
##  @return True if the address is global multicast address, false otherwise.
##

proc net_ipv6_is_addr_mcast_global*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_scope(`addr`, 0x0e)

## *
##  @brief Check if the IPv6 address is a interface scope multicast
##  address (FFx1::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a interface scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_iface*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_scope(`addr`, 0x01)

## *
##  @brief Check if the IPv6 address is a link local scope multicast
##  address (FFx2::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a link local scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_link*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_scope(`addr`, 0x02)

## *
##  @brief Check if the IPv6 address is a mesh-local scope multicast
##  address (FFx3::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a mesh-local scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_mesh*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_scope(`addr`, 0x03)

## *
##  @brief Check if the IPv6 address is a site scope multicast
##  address (FFx5::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a site scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_site*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_scope(`addr`, 0x05)

## *
##  @brief Check if the IPv6 address is an organization scope multicast
##  address (FFx8::).
##
##  @param addr IPv6 address.
##
##  @return True if the address is an organization scope multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_org*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_scope(`addr`, 0x08)

## *
##  @brief Check if the IPv6 address belongs to certain multicast group
##
##  @param addr IPv6 address.
##  @param group Group id IPv6 address, the values must be in network
##  byte order
##
##  @return True if the IPv6 multicast address belongs to given multicast
##  group, false otherwise.
##

proc net_ipv6_is_addr_mcast_group*(`addr`: ptr in6_addr; group: ptr in6_addr): bool =
  return UNALIGNED_GET(addr(`addr`.s6_addr16[1])) == group.s6_addr16[1] and
      UNALIGNED_GET(addr(`addr`.s6_addr16[2])) == group.s6_addr16[2] and
      UNALIGNED_GET(addr(`addr`.s6_addr16[3])) == group.s6_addr16[3] and
      UNALIGNED_GET(addr(`addr`.s6_addr32[1])) == group.s6_addr32[1] and
      UNALIGNED_GET(addr(`addr`.s6_addr32[2])) == group.s6_addr32[1] and
      UNALIGNED_GET(addr(`addr`.s6_addr32[3])) == group.s6_addr32[3]

## *
##  @brief Check if the IPv6 address belongs to the all nodes multicast group
##
##  @param addr IPv6 address
##
##  @return True if the IPv6 multicast address belongs to the all nodes multicast
##  group, false otherwise
##

proc net_ipv6_is_addr_mcast_all_nodes_group*(`addr`: ptr in6_addr): bool =
  let all_nodes_mcast_group: in6_addr
  return net_ipv6_is_addr_mcast_group(`addr`, addr(all_nodes_mcast_group))

## *
##  @brief Check if the IPv6 address is a interface scope all nodes multicast
##  address (FF01::1).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a interface scope all nodes multicast address,
##  false otherwise.
##

proc net_ipv6_is_addr_mcast_iface_all_nodes*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_iface(`addr`) and
      net_ipv6_is_addr_mcast_all_nodes_group(`addr`)

## *
##  @brief Check if the IPv6 address is a link local scope all nodes multicast
##  address (FF02::1).
##
##  @param addr IPv6 address.
##
##  @return True if the address is a link local scope all nodes multicast
##  address, false otherwise.
##

proc net_ipv6_is_addr_mcast_link_all_nodes*(`addr`: ptr in6_addr): bool =
  return net_ipv6_is_addr_mcast_link(`addr`) and
      net_ipv6_is_addr_mcast_all_nodes_group(`addr`)

## *
##   @brief Create solicited node IPv6 multicast address
##   FF02:0:0:0:0:1:FFXX:XXXX defined in RFC 3513
##
##   @param src IPv6 address.
##   @param dst IPv6 address.
##

proc net_ipv6_addr_create_solicited_node*(src: ptr in6_addr; dst: ptr in6_addr) =
  dst.s6_addr[0] = 0xFF
  dst.s6_addr[1] = 0x02
  UNALIGNED_PUT(0, addr(dst.s6_addr16[1]))
  UNALIGNED_PUT(0, addr(dst.s6_addr16[2]))
  UNALIGNED_PUT(0, addr(dst.s6_addr16[3]))
  UNALIGNED_PUT(0, addr(dst.s6_addr16[4]))
  dst.s6_addr[10] = 0'u
  dst.s6_addr[11] = 0x01
  dst.s6_addr[12] = 0xFF
  dst.s6_addr[13] = src.s6_addr[13]
  UNALIGNED_PUT(UNALIGNED_GET(addr(src.s6_addr16[7])), addr(dst.s6_addr16[7]))

## * @brief Construct an IPv6 address from eight 16-bit words.
##
##   @param addr IPv6 address
##   @param addr0 16-bit word which is part of the address
##   @param addr1 16-bit word which is part of the address
##   @param addr2 16-bit word which is part of the address
##   @param addr3 16-bit word which is part of the address
##   @param addr4 16-bit word which is part of the address
##   @param addr5 16-bit word which is part of the address
##   @param addr6 16-bit word which is part of the address
##   @param addr7 16-bit word which is part of the address
##

proc net_ipv6_addr_create*(`addr`: ptr in6_addr; addr0: uint16; addr1: uint16;
                          addr2: uint16; addr3: uint16; addr4: uint16; addr5: uint16;
                          addr6: uint16; addr7: uint16) =
  UNALIGNED_PUT(htons(addr0), addr(`addr`.s6_addr16[0]))
  UNALIGNED_PUT(htons(addr1), addr(`addr`.s6_addr16[1]))
  UNALIGNED_PUT(htons(addr2), addr(`addr`.s6_addr16[2]))
  UNALIGNED_PUT(htons(addr3), addr(`addr`.s6_addr16[3]))
  UNALIGNED_PUT(htons(addr4), addr(`addr`.s6_addr16[4]))
  UNALIGNED_PUT(htons(addr5), addr(`addr`.s6_addr16[5]))
  UNALIGNED_PUT(htons(addr6), addr(`addr`.s6_addr16[6]))
  UNALIGNED_PUT(htons(addr7), addr(`addr`.s6_addr16[7]))

## *
##   @brief Create link local allnodes multicast IPv6 address
##
##   @param addr IPv6 address
##

proc net_ipv6_addr_create_ll_allnodes_mcast*(`addr`: ptr in6_addr) =
  net_ipv6_addr_create(`addr`, 0xff02, 0, 0, 0, 0, 0, 0, 0x0001)

## *
##   @brief Create link local allrouters multicast IPv6 address
##
##   @param addr IPv6 address
##

proc net_ipv6_addr_create_ll_allrouters_mcast*(`addr`: ptr in6_addr) =
  net_ipv6_addr_create(`addr`, 0xff02, 0, 0, 0, 0, 0, 0, 0x0002)

## *
##   @brief Create IPv6 address interface identifier
##
##   @param addr IPv6 address
##   @param lladdr Link local address
##

proc net_ipv6_addr_create_iid*(`addr`: ptr in6_addr; lladdr: ptr net_linkaddr) =
  UNALIGNED_PUT(htonl(0xfe800000), addr(`addr`.s6_addr32[0]))
  UNALIGNED_PUT(0, addr(`addr`.s6_addr32[1]))
  case lladdr.len
  of 2:                        ##  The generated IPv6 shall not toggle the
      ##  Universal/Local bit. RFC 6282 ch 3.2.2
      ##
    if lladdr.`type` == NET_LINK_IEEE802154 or lladdr.`type` == NET_LINK_CANBUS:
      UNALIGNED_PUT(0, addr(`addr`.s6_addr32[2]))
      `addr`.s6_addr[11] = 0xff
      `addr`.s6_addr[12] = 0xfe
      `addr`.s6_addr[13] = 0'u
      `addr`.s6_addr[14] = lladdr.`addr`[0]
      `addr`.s6_addr[15] = lladdr.`addr`[1]
  of 6:                        ##  We do not toggle the Universal/Local bit
      ##  in Bluetooth. See RFC 7668 ch 3.2.2
      ##
    memcpy(addr(`addr`.s6_addr[8]), lladdr.`addr`, 3)
    `addr`.s6_addr[11] = 0xff
    `addr`.s6_addr[12] = 0xfe
    memcpy(addr(`addr`.s6_addr[13]), lladdr.`addr` + 3, 3)
    when defined(CONFIG_NET_L2_BT_ZEP1656):
      ##  Workaround against older Linux kernel BT IPSP code.
      ##  This will be removed eventually.
      ##
      if lladdr.`type` == NET_LINK_BLUETOOTH:
        `addr`.s6_addr[8] = `addr`.s6_addr[8] xor 0x02
    if lladdr.`type` == NET_LINK_ETHERNET:
      `addr`.s6_addr[8] = `addr`.s6_addr[8] xor 0x02
  of 8:
    memcpy(addr(`addr`.s6_addr[8]), lladdr.`addr`, lladdr.len)
    `addr`.s6_addr[8] = `addr`.s6_addr[8] xor 0x02

## *
##   @brief Check if given address is based on link layer address
##
##   @return True if it is, False otherwise
##

proc net_ipv6_addr_based_on_ll*(`addr`: ptr in6_addr; lladdr: ptr net_linkaddr): bool =
  if not `addr` or not lladdr:
    return false
  case lladdr.len
  of 2:
    if not memcmp(addr(`addr`.s6_addr[14]), lladdr.`addr`, lladdr.len) and
        `addr`.s6_addr[8] == 0'u and `addr`.s6_addr[9] == 0'u and
        `addr`.s6_addr[10] == 0'u and `addr`.s6_addr[11] == 0xff and
        `addr`.s6_addr[12] == 0xfe:
      return true
  of 6:
    if lladdr.`type` == NET_LINK_ETHERNET:
      if not memcmp(addr(`addr`.s6_addr[9]), addr(lladdr.`addr`[1]), 2) and
          not memcmp(addr(`addr`.s6_addr[13]), addr(lladdr.`addr`[3]), 3) and
          `addr`.s6_addr[11] == 0xff and `addr`.s6_addr[12] == 0xfe and
          (`addr`.s6_addr[8] xor 0x02) == lladdr.`addr`[0]:
        return true
    elif lladdr.`type` == NET_LINK_BLUETOOTH:
      if not memcmp(addr(`addr`.s6_addr[9]), addr(lladdr.`addr`[1]), 2) and
          not memcmp(addr(`addr`.s6_addr[13]), addr(lladdr.`addr`[3]), 3) and
          `addr`.s6_addr[11] == 0xff and `addr`.s6_addr[12] == 0xfe:
        return true
  of 8:
    if not memcmp(addr(`addr`.s6_addr[9]), addr(lladdr.`addr`[1]), lladdr.len - 1) and
        (`addr`.s6_addr[8] xor 0x02) == lladdr.`addr`[0]:
      return true
  return false

## *
##  @brief Get sockaddr_in6 from sockaddr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv6 socket address
##

proc net_sin6*(`addr`: ptr sockaddr): ptr sockaddr_in6 =
  return cast[ptr sockaddr_in6](`addr`)

## *
##  @brief Get sockaddr_in from sockaddr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv4 socket address
##

proc net_sin*(`addr`: ptr sockaddr): ptr sockaddr_in =
  return cast[ptr sockaddr_in](`addr`)

## *
##  @brief Get sockaddr_in6_ptr from sockaddr_ptr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv6 socket address
##

proc net_sin6_ptr*(`addr`: ptr sockaddr_ptr): ptr sockaddr_in6_ptr =
  return cast[ptr sockaddr_in6_ptr](`addr`)

## *
##  @brief Get sockaddr_in_ptr from sockaddr_ptr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to IPv4 socket address
##

proc net_sin_ptr*(`addr`: ptr sockaddr_ptr): ptr sockaddr_in_ptr =
  return cast[ptr sockaddr_in_ptr](`addr`)

## *
##  @brief Get sockaddr_ll_ptr from sockaddr_ptr. This is a helper so that
##  the code calling this function can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to linklayer socket address
##

proc net_sll_ptr*(`addr`: ptr sockaddr_ptr): ptr sockaddr_ll_ptr =
  return cast[ptr sockaddr_ll_ptr](`addr`)

## *
##  @brief Get sockaddr_can_ptr from sockaddr_ptr. This is a helper so that
##  the code needing this functionality can be made shorter.
##
##  @param addr Socket address
##
##  @return Pointer to CAN socket address
##

proc net_can_ptr*(`addr`: ptr sockaddr_ptr): ptr sockaddr_can_ptr =
  return cast[ptr sockaddr_can_ptr](`addr`)

## *
##  @brief Convert a string to IP address.
##
##  @param family IP address family (AF_INET or AF_INET6)
##  @param src IP address in a null terminated string
##  @param dst Pointer to struct in_addr if family is AF_INET or
##  pointer to struct in6_addr if family is AF_INET6
##
##  @note This function doesn't do precise error checking,
##  do not use for untrusted strings.
##
##  @return 0 if ok, < 0 if error
##

proc net_addr_pton*(family: sa_family_t; src: cstring; dst: pointer): cint {.syscall,
    importc: "net_addr_pton", header: "net_ip.h".}
## *
##  @brief Convert IP address to string form.
##
##  @param family IP address family (AF_INET or AF_INET6)
##  @param src Pointer to struct in_addr if family is AF_INET or
##         pointer to struct in6_addr if family is AF_INET6
##  @param dst Buffer for IP address as a null terminated string
##  @param size Number of bytes available in the buffer
##
##  @return dst pointer if ok, NULL if error
##

proc net_addr_ntop*(family: sa_family_t; src: pointer; dst: cstring; size: csize_t): cstring {.
    syscall, importc: "net_addr_ntop", header: "net_ip.h".}
## *
##  @brief Parse a string that contains either IPv4 or IPv6 address
##  and optional port, and store the information in user supplied
##  sockaddr struct.
##
##  @details Syntax of the IP address string:
##    192.0.2.1:80
##    192.0.2.42
##    [2001:db8::1]:8080
##    [2001:db8::2]
##    2001:db::42
##  Note that the str_len parameter is used to restrict the amount of
##  characters that are checked. If the string does not contain port
##  number, then the port number in sockaddr is not modified.
##
##  @param str String that contains the IP address.
##  @param str_len Length of the string to be parsed.
##  @param addr Pointer to user supplied struct sockaddr.
##
##  @return True if parsing could be done, false otherwise.
##

proc net_ipaddr_parse*(str: cstring; str_len: csize_t; `addr`: ptr sockaddr): bool {.
    importc: "net_ipaddr_parse", header: "net_ip.h".}
## *
##  @brief Compare TCP sequence numbers.
##
##  @details This function compares TCP sequence numbers,
##           accounting for wraparound effects.
##
##  @param seq1 First sequence number
##  @param seq2 Seconds sequence number
##
##  @return < 0 if seq1 < seq2, 0 if seq1 == seq2, > 0 if seq > seq2
##

proc net_tcp_seq_cmp*(seq1: uint32; seq2: uint32): int32 =
  return (int32)(seq1 - seq2)

## *
##  @brief Check that one TCP sequence number is greater.
##
##  @details This is convenience function on top of net_tcp_seq_cmp().
##
##  @param seq1 First sequence number
##  @param seq2 Seconds sequence number
##
##  @return True if seq > seq2
##

proc net_tcp_seq_greater*(seq1: uint32; seq2: uint32): bool =
  return net_tcp_seq_cmp(seq1, seq2) > 0

## *
##  @brief Convert a string of hex values to array of bytes.
##
##  @details The syntax of the string is "ab:02:98:fa:42:01"
##
##  @param buf Pointer to memory where the bytes are written.
##  @param buf_len Length of the memory area.
##  @param src String of bytes.
##
##  @return 0 if ok, <0 if error
##

proc net_bytes_from_str*(buf: ptr uint8; buf_len: cint; src: cstring): cint {.
    importc: "net_bytes_from_str", header: "net_ip.h".}
## *
##  @brief Convert Tx network packet priority to traffic class so we can place
##  the packet into correct Tx queue.
##
##  @param prio Network priority
##
##  @return Tx traffic class that handles that priority network traffic.
##

proc net_tx_priority2tc*(prio: net_priority): cint {.importc: "net_tx_priority2tc",
    header: "net_ip.h".}
## *
##  @brief Convert Rx network packet priority to traffic class so we can place
##  the packet into correct Rx queue.
##
##  @param prio Network priority
##
##  @return Rx traffic class that handles that priority network traffic.
##

proc net_rx_priority2tc*(prio: net_priority): cint {.importc: "net_rx_priority2tc",
    header: "net_ip.h".}
## *
##  @brief Convert network packet VLAN priority to network packet priority so we
##  can place the packet into correct queue.
##
##  @param priority VLAN priority
##
##  @return Network priority
##

proc net_vlan2priority*(priority: uint8): net_priority =
  ##  Map according to IEEE 802.1Q
  let vlan2priority: UncheckedArray[uint8]
  if priority >= ARRAY_SIZE(vlan2priority):
    ##  Use Best Effort as the default priority
    return NET_PRIORITY_BE
  return cast[net_priority](vlan2priority[priority])

## *
##  @brief Convert network packet priority to network packet VLAN priority.
##
##  @param priority Packet priority
##
##  @return VLAN priority (PCP)
##

proc net_priority2vlan*(priority: net_priority): uint8 =
  ##  The conversion works both ways
  return cast[uint8](net_vlan2priority(priority))

## *
##  @brief Return network address family value as a string. This is only usable
##  for debugging.
##
##  @param family Network address family code
##
##  @return Network address family as a string, or NULL if family is unknown.
##

proc net_family2str*(family: sa_family_t): cstring {.importc: "net_family2str",
    header: "net_ip.h".}
## *
##  @}
##
