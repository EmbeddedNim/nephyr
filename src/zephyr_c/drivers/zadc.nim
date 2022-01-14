## *
##  @brief ADC driver APIs
##  @defgroup adc_interface ADC driver APIs
##  @ingroup io_interfaces
##  @{
##
## * @brief ADC channel gain factors.
## 
import ../zconfs
import ../zdevice
import ../kernel/zk_poll


type

  adc_reference* {.size: sizeof(cint).} = enum
    ADC_REF_VDD_1,            ## *< VDD.
    ADC_REF_VDD_1_2,          ## *< VDD/2.
    ADC_REF_VDD_1_3,          ## *< VDD/3.
    ADC_REF_VDD_1_4,          ## *< VDD/4.
    ADC_REF_INTERNAL,         ## *< Internal.
    ADC_REF_EXTERNAL0,        ## *< External, input 0.
    ADC_REF_EXTERNAL1         ## *< External, input 1.

  adc_gain* {.size: sizeof(cint).} = enum
    ADC_GAIN_1d6x,             ## *< x 1/6.
    ADC_GAIN_1d5x,             ## *< x 1/5.
    ADC_GAIN_1d4x,             ## *< x 1/4.
    ADC_GAIN_1d3x,             ## *< x 1/3.
    ADC_GAIN_1d2x,             ## *< x 1/2.
    ADC_GAIN_2d3x,             ## *< x 2/3.
    ADC_GAIN_1x,               ## *< x 1.
    ADC_GAIN_2x,               ## *< x 2.
    ADC_GAIN_3x,               ## *< x 3.
    ADC_GAIN_4x,               ## *< x 4.
    ADC_GAIN_8x,               ## *< x 8.
    ADC_GAIN_16x,              ## *< x 16.
    ADC_GAIN_32x,              ## *< x 32.
    ADC_GAIN_64x,              ## *< x 64.
    ADC_GAIN_128x              ## *< x 128.

  adc_sequence_callback* = proc (dev: ptr device; sequence: ptr adc_sequence;
                              sampling_index: uint16): adc_action ##\
    ## *
    ##  @brief Type definition of the optional callback function to be called after
    ##         a requested sampling is done.
    ##
    ##  @param dev             Pointer to the device structure for the driver
    ##                         instance.
    ##  @param sequence        Pointer to the sequence structure that triggered
    ##                         the sampling. This parameter points to a copy of
    ##                         the structure that was supplied to the call that
    ##                         started the sampling sequence, thus it cannot be
    ##                         used with the CONTAINER_OF() macro to retrieve
    ##                         some other data associated with the sequence.
    ##                         Instead, the adc_sequence_options::user_data field
    ##                         should be used for such purpose.
    ##
    ##  @param sampling_index  Index (0-65535) of the sampling done.
    ##
    ##  @returns Action to be performed by the driver. See @ref adc_action.
    ##

  adc_action* {.size: sizeof(cint).} = enum
    ## * The sequence should be continued normally.
    ADC_ACTION_CONTINUE = 0, ## *
                          ##  The sampling should be repeated. New samples or sample should be
                          ##  read from the ADC and written in the same place as the recent ones.
                          ##
    ADC_ACTION_REPEAT,        ## * The sequence should be finished immediately.
    ADC_ACTION_FINISH


  adc_sequence_options* {.importc: "adc_sequence_options", header: "adc.h", bycopy.} = object
    ##  @brief Structure defining additional options for an ADC sampling sequence.
    interval_us* {.importc: "interval_us".}: uint32 ## *
                                                ##  Interval between consecutive samplings (in microseconds), 0 means
                                                ##  sample as fast as possible, without involving any timer.
                                                ##  The accuracy of this interval is dependent on the implementation of
                                                ##  a given driver. The default routine that handles the intervals uses
                                                ##  a kernel timer for this purpose, thus, it has the accuracy of the
                                                ##  kernel's system clock. Particular drivers may use some dedicated
                                                ##  hardware timers and achieve a better precision.
                                                ##
    ## *
    ##  Callback function to be called after each sampling is done.
    ##  Optional - set to NULL if it is not needed.
    ##
    callback* {.importc: "callback".}: adc_sequence_callback ## *
                                                         ##  Pointer to user data. It can be used to associate the sequence
                                                         ##  with any other data that is needed in the callback function.
                                                         ##
    user_data* {.importc: "user_data".}: pointer ## *
                                             ##  Number of extra samplings to perform (the total number of samplings
                                             ##  is 1 + extra_samplings).
                                             ##
    extra_samplings* {.importc: "extra_samplings".}: uint16


  adc_sequence* {.importc: "adc_sequence", header: "adc.h", bycopy.} = object
    ##  @brief Structure defining an ADC sampling sequence.
    options* {.importc: "options".}: ptr adc_sequence_options ## *
                                                         ##  Pointer to a structure defining additional options for the sequence.
                                                         ##  If NULL, the sequence consists of a single sampling.
                                                         ##
    ## *
    ##  Bit-mask indicating the channels to be included in each sampling
    ##  of this sequence.
    ##  All selected channels must be configured with adc_channel_setup()
    ##  before they are used in a sequence.
    ##
    channels* {.importc: "channels".}: uint32 ## *
                                          ##  Pointer to a buffer where the samples are to be written. Samples
                                          ##  from subsequent samplings are written sequentially in the buffer.
                                          ##  The number of samples written for each sampling is determined by
                                          ##  the number of channels selected in the "channels" field.
                                          ##  The buffer must be of an appropriate size, taking into account
                                          ##  the number of selected channels and the ADC resolution used,
                                          ##  as well as the number of samplings contained in the sequence.
                                          ##
    buffer* {.importc: "buffer".}: pointer ## *
                                       ##  Specifies the actual size of the buffer pointed by the "buffer"
                                       ##  field (in bytes). The driver must ensure that samples are not
                                       ##  written beyond the limit and it must return an error if the buffer
                                       ##  turns out to be not large enough to hold all the requested samples.
                                       ##
    buffer_size* {.importc: "buffer_size".}: csize_t ## *
                                                 ##  ADC resolution.
                                                 ##  For single-ended channels the sample values are from range:
                                                 ##    0 .. 2^resolution - 1,
                                                 ##  for differential ones:
                                                 ##    - 2^(resolution-1) .. 2^(resolution-1) - 1.
                                                 ##
    resolution* {.importc: "resolution".}: uint8 ## *
                                             ##  Oversampling setting.
                                             ##  Each sample is averaged from 2^oversampling conversion results.
                                             ##  This feature may be unsupported by a given ADC hardware, or in
                                             ##  a specific mode (e.g. when sampling multiple channels).
                                             ##
    oversampling* {.importc: "oversampling".}: uint8 ## *
                                                 ##  Perform calibration before the reading is taken if requested.
                                                 ##
                                                 ##  The impact of channel configuration on the calibration
                                                 ##  process is specific to the underlying hardware.  ADC
                                                 ##  implementations that do not support calibration should
                                                 ##  ignore this flag.
                                                 ##
    calibrate* {.importc: "calibrate".}: bool


  adc_api_channel_setup* = proc (dev: ptr device; channel_cfg: ptr adc_channel_cfg): cint ##\
    ##  @brief Type definition of ADC API function for configuring a channel.
    ##  See adc_channel_setup() for argument descriptions.

  adc_api_read* = proc (dev: ptr device; sequence: ptr adc_sequence): cint ##\
    ##  @brief Type definition of ADC API function for setting a read request.
    ##  See adc_read() for argument descriptions.

  adc_api_read_async* = proc (dev: ptr device; sequence: ptr adc_sequence;
                           async: ptr k_poll_signal): cint ##\
    ##  @brief Type definition of ADC API function for setting an asynchronous
    ##         read request.
    ##  See adc_read_async() for argument descriptions.

  ## *
  ##  @brief ADC driver API
  ##
  ##  This is the mandatory API any ADC driver needs to expose.
  ##
  adc_driver_api* {.importc: "adc_driver_api", header: "adc.h", bycopy.} = object
    channel_setup* {.importc: "channel_setup".}: adc_api_channel_setup
    read* {.importc: "read".}: adc_api_read
    when CONFIG_ADC_ASYNC:
      read_async* {.header: "adc.h".}: adc_api_read_async
    ref_internal* {.importc: "ref_internal".}: uint16 ##  mV

  ## *
  ##  @brief Structure for specifying the configuration of an ADC channel.
  ##
  adc_channel_cfg* {.importc: "adc_channel_cfg", header: "adc.h", bycopy.} = object
    gain* {.importc: "gain".}: adc_gain ## * Gain selection.
    ## * Reference selection.
    reference* {.importc: "reference".}: adc_reference ## *
                                                   ##  Acquisition time.
                                                   ##  Use the ADC_ACQ_TIME macro to compose the value for this field or
                                                   ##  pass ADC_ACQ_TIME_DEFAULT to use the default setting for a given
                                                   ##  hardware (e.g. when the hardware does not allow to configure the
                                                   ##  acquisition time).
                                                   ##  Particular drivers do not necessarily support all the possible units.
                                                   ##  Value range is 0-16383 for a given unit.
                                                   ##
    acquisition_time* {.importc: "acquisition_time".}: uint16 ## *
                                                          ##  Channel identifier.
                                                          ##  This value primarily identifies the channel within the ADC API - when
                                                          ##  a read request is done, the corresponding bit in the "channels" field
                                                          ##  of the "adc_sequence" structure must be set to include this channel
                                                          ##  in the sampling.
                                                          ##  For hardware that does not allow selection of analog inputs for given
                                                          ##  channels, but rather have dedicated ones, this value also selects the
                                                          ##  physical ADC input to be used in the sampling. Otherwise, when it is
                                                          ##  needed to explicitly select an analog input for the channel, or two
                                                          ##  inputs when the channel is a differential one, the selection is done
                                                          ##  in "input_positive" and "input_negative" fields.
                                                          ##  Particular drivers indicate which one of the above two cases they
                                                          ##  support by selecting or not a special hidden Kconfig option named
                                                          ##  ADC_CONFIGURABLE_INPUTS. If this option is not selected, the macro
                                                          ##  CONFIG_ADC_CONFIGURABLE_INPUTS is not defined and consequently the
                                                          ##  mentioned two fields are not present in this structure.
                                                          ##  While this API allows identifiers from range 0-31, particular drivers
                                                          ##  may support only a limited number of channel identifiers (dependent
                                                          ##  on the underlying hardware capabilities or configured via a dedicated
                                                          ##  Kconfig option).
                                                          ##
    channel_id* {.importc: "channel_id", bitsize: 5.}: uint8 ## * Channel type: single-ended or differential.
    differential* {.importc: "differential", bitsize: 1.}: uint8
    when CONFIG_ADC_CONFIGURABLE_INPUTS:
      ## *
      ##  Positive ADC input.
      ##  This is a driver dependent value that identifies an ADC input to be
      ##  associated with the channel.
      ##
      input_positive* {.header: "adc.h".}: uint8
      ## *
      ##  Negative ADC input (used only for differential channels).
      ##  This is a driver dependent value that identifies an ADC input to be
      ##  associated with the channel.
      ##
      input_negative* {.header: "adc.h".}: uint8


## *
##  @brief Invert the application of gain to a measurement value.
##
##  For example, if the gain passed in is ADC_GAIN_1_6 and the
##  referenced value is 10, the value after the function returns is 60.
##
##  @param gain the gain used to amplify the input signal.
##
##  @param value a pointer to a value that initially has the effect of
##  the applied gain but has that effect removed when this function
##  successfully returns.  If the gain cannot be reversed the value
##  remains unchanged.
##
##  @retval 0 if the gain was successfully reversed
##  @retval -EINVAL if the gain could not be interpreted
##

proc adc_gain_invert*(gain: adc_gain; value: ptr int32): cint {.
    importc: "adc_gain_invert", header: "adc.h".}
## * @brief ADC references.



## *
##  @brief Convert a raw ADC value to millivolts.
##
##  This function performs the necessary conversion to transform a raw
##  ADC measurement to a voltage in millivolts.
##
##  @param ref_mv the reference voltage used for the measurement, in
##  millivolts.  This may be from adc_ref_internal() or a known
##  external reference.
##
##  @param gain the ADC gain configuration used to sample the input
##
##  @param resolution the number of bits in the absolute value of the
##  sample.  For differential sampling this may be one less than the
##  resolution in struct adc_sequence.
##
##  @param valp pointer to the raw measurement value on input, and the
##  corresponding millivolt value on successful conversion.  If
##  conversion fails the stored value is left unchanged.
##
##  @retval 0 on successful conversion
##  @retval -EINVAL if the gain is not reversible
##
proc adc_raw_to_millivolts*(ref_mv: int32; gain: adc_gain; resolution: uint8;
                           valp: ptr int32): cint {.inline,
    importc: "adc_raw_to_millivolts".} =
  var adc_mv: int32
  var ret: cint
  if ret == 0:
    valp[] = (adc_mv shr resolution)
  return ret


## *
##  @brief Configure an ADC channel.
##
##  It is required to call this function and configure each channel before it is
##  selected for a read request.
##
##  @param dev          Pointer to the device structure for the driver instance.
##  @param channel_cfg  Channel configuration.
##
##  @retval 0       On success.
##  @retval -EINVAL If a parameter with an invalid value has been provided.
##
proc adc_channel_setup*(dev: ptr device; channel_cfg: ptr adc_channel_cfg): cint {.
    syscall, importc: "adc_channel_setup", header: "adc.h".}


## *
##  @brief Set a read request.
##
##  @param dev       Pointer to the device structure for the driver instance.
##  @param sequence  Structure specifying requested sequence of samplings.
##
##  If invoked from user mode, any sequence struct options for callback must
##  be NULL.
##
##  @retval 0        On success.
##  @retval -EINVAL  If a parameter with an invalid value has been provided.
##  @retval -ENOMEM  If the provided buffer is to small to hold the results
##                   of all requested samplings.
##  @retval -ENOTSUP If the requested mode of operation is not supported.
##  @retval -EBUSY   If another sampling was triggered while the previous one
##                   was still in progress. This may occur only when samplings
##                   are done with intervals, and it indicates that the selected
##                   interval was too small. All requested samples are written
##                   in the buffer, but at least some of them were taken with
##                   an extra delay compared to what was scheduled.
##
proc adc_read*(dev: ptr device; sequence: ptr adc_sequence): cint {.syscall,
    importc: "adc_read", header: "adc.h".}


## *
##  @brief Set an asynchronous read request.
##
##  @note This function is available only if @option{CONFIG_ADC_ASYNC}
##  is selected.
##
##  If invoked from user mode, any sequence struct options for callback must
##  be NULL.
##
##  @param dev       Pointer to the device structure for the driver instance.
##  @param sequence  Structure specifying requested sequence of samplings.
##  @param async     Pointer to a valid and ready to be signaled struct
##                   k_poll_signal. (Note: if NULL this function will not notify
##                   the end of the transaction, and whether it went successfully
##                   or not).
##
##  @returns 0 on success, negative error code otherwise.
##           See adc_read() for a list of possible error codes.
##
##
proc adc_read_async*(dev: ptr device; sequence: ptr adc_sequence;
                    async: ptr k_poll_signal): cint {.syscall,
    importc: "adc_read_async", header: "adc.h".}

## *
##  @brief Get the internal reference voltage.
##
##  Returns the voltage corresponding to @ref ADC_REF_INTERNAL,
##  measured in millivolts.
##
##  @return a positive value is the reference voltage value.  Returns
##  zero if reference voltage information is not available.
##

proc adc_ref_internal*(dev: ptr device): uint16 {.importc: "adc_ref_internal", header: "adc.h".}
