import zconsts

when BOARD in ["teensy40", "teensy41"]:
  ## Change Teensy PinMux to use CS GPIO Pin
  # type MuxCfg* = distinct int
  # var IOMUXC_GPIO_AD_B0_03_GPIO1_IO03* {.importc: "$1", header: "<fsl_iomuxc.h>".}: MuxCfg
  # proc IOMUXC_SetPinMux*(muxCfg: MuxCfg, val: cint) {.importc: "IOMUXC_SetPinMux", header: "<fsl_iomuxc.h>".}

  proc board_configuration() {.exportc.} =
    {.emit: """
    #include <fsl_iomuxc.h>
    IOMUXC_SetPinMux(IOMUXC_GPIO_AD_B0_03_GPIO1_IO03, 0)
    """.}

  SystemInit(board_configuration, INIT_PRE_KERNEL_1, 40)

