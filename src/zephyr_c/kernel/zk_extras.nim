
#include <kernel_version.h>

proc sys_kernel_version_get*(): uint32 {.importc: "sys_kernel_version_get", header: "<kernel_version.h>".}

proc SYS_KERNEL_VER_MAJOR*(ver: uint32): uint32 {.importc: "SYS_KERNEL_VER_MAJOR", header: "<kernel_version.h>".}
proc SYS_KERNEL_VER_MINOR*(ver: uint32): uint32 {.importc: "SYS_KERNEL_VER_MINOR", header: "<kernel_version.h>".}
proc SYS_KERNEL_VER_PATCHLEVEL*(ver: uint32): uint32 {.importc: "SYS_KERNEL_VER_PATCHLEVEL", header: "<kernel_version.h>".}


proc zKernelVersion*(): tuple[major: int, minor: int, patch: int] =
  let
    ver = sys_kernel_version_get()
    maj = ver.SYS_KERNEL_VER_MAJOR().int
    mnr = ver.SYS_KERNEL_VER_MINOR().int
    ptc = ver.SYS_KERNEL_VER_PATCHLEVEL().int
  return (major: maj.int, minor: mnr, patch: ptc)
