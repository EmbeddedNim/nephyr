import zconsts

when BOARD in ["teensy40", "teensy41"]:
  ## Change Teensy PinMux to use CS GPIO Pin

  proc board_configuration() {.exportc.} =
    {.emit: """
    #include <fsl_iomuxc.h>
    IOMUXC_SetPinMux(IOMUXC_GPIO_AD_B0_03_GPIO1_IO03, 0);
    """.}

  SystemInit(board_configuration, INIT_PRE_KERNEL_1, 40)

