import std/[net, os, tables]

import mcu_utils/logging

import zephyr/net/znet_linkaddr
import zephyr/net/znet_ip
import zephyr/net/znet_if
import zephyr/net/znet_config
import zephyr/net/zipv6

export znet_linkaddr, znet_ip, znet_if, znet_config, zipv6

import std/posix 
import std/nativesockets 

export posix, nativesockets, net

import mcu_utils/nettypes

# void net_if_foreach(net_if_cb_t cb, void *user_data)
proc zfind_interfaces(iface: ptr net_if; user_data: pointer) {.cdecl, exportc.} =
  var table = cast[TableRef[NetIfId, NetIfDevice]](user_data)
  let nid = NetIfId(table.len())
  let nif = NetIfDevice(raw: iface)
  table[nid] = nif

proc findAllInterfaces*(): TableRef[NetIfId, NetIfDevice] = 
  ## Finds all current network interfaces
  let cb: net_if_cb_t = zfind_interfaces
  result = newTable[NetIfId, NetIfDevice]()
  net_if_foreach(cb, cast[pointer](result))

proc hasDefaultInterface*(): bool =
  ## check for default interface
  let iface: ptr net_if = net_if_get_default()
  result = not iface.isNil

proc getDefaultInterface*(): NetIfDevice {.raises: [ValueError].} =
  ## get default interface
  let iface: ptr net_if = net_if_get_default()
  if iface.isNil:
    raise newException(ValueError, "no default interface")
  result = NetIfDevice(raw: iface)

proc hwAddress*(ifdev: NetIfDevice): seq[uint8] =
  let ll_addr: net_linkaddr = ifdev.raw.if_dev.link_addr
  result = newSeq[uint8](ll_addr.len.int)
  copyMem(result[0].addr, ll_addr.caddr, ll_addr.len.int)

proc hwMacAddress*(ifdev: NetIfDevice): array[6, uint8] =
  let hwaddr = ifdev.hwAddress()
  result[0..5] = hwaddr[0..5]

proc linkLocalAddr*(ifdev: NetIfDevice): IpAddress {.raises: [ValueError].} =
  ## finds and returns link local address
  let lladdr: ptr In6Addr = net_if_ipv6_get_ll(ifdev.raw, NET_ADDR_ANY_STATE)

  if lladdr.isNil:
    raise newException(ValueError, "no ipv6 link-local addr")

  var
    saddr: Sockaddr_in6
    port: Port
  
  saddr.sin6_family = toInt(Domain.AF_INET6).TSa_Family
  saddr.sin6_addr = lladdr[]
  fromSockAddr(saddr, sizeof(saddr).SockLen, result, port)

# proc setLinkLocalAddress*(ifdev: NetIfDevice, open) =
#   ## finds and returns link local address
#   let lladdr: ptr In6Addr = net_if_ipv6_get_ll(ifdev.raw, NET_ADDR_ANY_STATE)

#   if lladdr.isNil:
#     raise newException(ValueError, "no ipv6 link-local addr")

#   var
#     saddr: Sockaddr_in6
#     port: Port
  
#   saddr.sin6_family = toInt(Domain.AF_INET6).TSa_Family
#   saddr.sin6_addr = lladdr[]
#   fromSockAddr(saddr, sizeof(saddr).SockLen, result, port)
