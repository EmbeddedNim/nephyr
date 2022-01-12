
import sequtils
import strutils

import utils, logs
import mcu_utils/basictypes

export basictypes
export utils
export logs
export sequtils
export strutils

import ../zephyr_c/zkernel

export kernel


proc sysReboot*(coldReboot: bool = false) = sys_reboot(if coldReboot: 1 else: 0)
