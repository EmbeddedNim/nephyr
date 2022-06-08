import ../zephyr/zdevice

proc z_device_get_all_static*(device: ptr UncheckedArray[ptr device]): csize_t {.
    importc: "z_device_get_all_static", header: "device.h".} ##\
      ## @brief Get access to the static array of static devices.
      ## 
      ## @param devices where to store the pointer to the array of
      ## statically allocated devices. The array must not be mutated
      ## through this pointer.
      ## *
      ## @return the number of statically allocated devices.
      ## 

proc listAllStaticDevices*(): seq[ptr device] =
  var sdevs: ptr UncheckedArray[ptr device]
  var cnt: csize_t
  cnt = z_device_get_all_static(sdevs)
  echo "cnt: ", cnt
  newSeq(result, cnt)
  for i in 0..<cnt:
    echo "dev ptr: ", sdevs[i].pointer.repr
    result[i] = sdevs[][i]
