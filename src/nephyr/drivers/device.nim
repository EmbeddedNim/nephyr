import ../zephyr/zdevice


proc listAllStaticDevices*(): seq[ptr device] =
  var sdevs: ptr UncheckedArray[device]
  let cnt = z_device_get_all_static(cast[ptr ptr device](addr sdevs))
  newSeq(result, cnt)
  for i in 0..<cnt:
      result[i] = addr(sdevs[i])
