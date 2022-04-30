import zconsts
import general

static:
  echo "Board FIXUP: ", BOARD

when BOARD in ["teensy40", "teensy41"]:

  ## Change Teensy PinMux to use CS GPIO Pin
  proc board_configuration() {.exportc.} =
    {.emit: """
    // configure pin mux for LP-SPI CS pins to be a regular gpio pins 
    // allowing them to be controlled by Zephyr SPI driver and not NXP lpSPI hardware
    IOMUXC_SetPinMux(IOMUXC_GPIO_AD_B0_03_GPIO1_IO03, 0);
    IOMUXC_SetPinMux(IOMUXC_GPIO_B0_00_GPIO2_IO00, 0);
    """.}

  # call zephyr `SYS_INIT` mode
  {.emit: "/*INCLUDESECTION*/\n#include <fsl_iomuxc.h>".}
  SystemInit(board_configuration, INIT_PRE_KERNEL_1, KernelInitPriorityDefault)

elif BOARD == "":
  static:
    raise newException(Exception, "board must be selected. Board was set to: " & BOARD)

