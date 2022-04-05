import zconsts

var BOARD_CONFIGURED_DONE* = false

static: 
  echo "Board FIXUP: ", BOARD

when BOARD in ["teensy40", "teensy41"]:
  ## Change Teensy PinMux to use CS GPIO Pin

  proc board_configuration() {.exportc.} =
    {.emit: """
    IOMUXC_SetPinMux(IOMUXC_GPIO_AD_B0_03_GPIO1_IO03, 0);
    """.}
    BOARD_CONFIGURED_DONE = true

  {.emit: "#include <fsl_iomuxc.h>".}
  SystemInit(board_configuration, INIT_PRE_KERNEL_1, 40)

elif BOARD == "":
  static:
    raise newException(Exception, "board must be selected. Board was set to: " & BOARD)

