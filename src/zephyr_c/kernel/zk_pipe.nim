
import ../zkernel_fixes
import ../zsys_clock


##  @defgroup pipe_apis Pipe APIs
##  @ingroup kernel_apis
##  @{
##
## * Pipe Structure
type
  INNER_C_STRUCT_kernel_2* {.importc: "no_name", header: "kernel.h", bycopy.} = object
    readers* {.importc: "readers".}: z_wait_q_t ## *< Reader wait queue
    writers* {.importc: "writers".}: z_wait_q_t ## *< Writer wait queue

type
  k_pipe* {.importc: "k_pipe", header: "kernel.h", bycopy.} = object
    buffer* {.importc: "buffer".}: ptr cuchar ## *< Pipe buffer: may be NULL
    size* {.importc: "size".}: csize_t ## *< Buffer size
    bytes_used* {.importc: "bytes_used".}: csize_t ## *< # bytes used in buffer
    read_index* {.importc: "read_index".}: csize_t ## *< Where in buffer to read from
    write_index* {.importc: "write_index".}: csize_t ## *< Where in buffer to write
    lock* {.importc: "lock".}: k_spinlock ## *< Synchronization lock
    wait_q* {.importc: "wait_q".}: INNER_C_STRUCT_kernel_2 ## * Wait queue
    flags* {.importc: "flags".}: uint8 ## *< Flags

## *
##  @cond INTERNAL_HIDDEN
##
# var K_PIPE_FLAG_ALLOC* {.importc: "K_PIPE_FLAG_ALLOC", header: "kernel.h".}: int

proc Z_PIPE_INITIALIZER*(obj: k_pipe; pipe_buffer: pointer;
                        pipe_buffer_size: int) {.
    importc: "Z_PIPE_INITIALIZER", header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @brief Statically define and initialize a pipe.
##
##  The pipe can be accessed outside the module where it is defined using:
##
##  @code extern struct k_pipe <name>; @endcode
##
##  @param name Name of the pipe.
##  @param pipe_buffer_size Size of the pipe's ring buffer (in bytes),
##                          or zero if no ring buffer is used.
##  @param pipe_align Alignment of the pipe's ring buffer (power of 2).
##
##
# proc K_PIPE_DEFINE*(name: cminvtoken; pipe_buffer_size: static[int]; pipe_align: static[int]) {.
    # importc: "K_PIPE_DEFINE", header: "kernel.h".}


## *
##  @brief Initialize a pipe.
##
##  This routine initializes a pipe object, prior to its first use.
##
##  @param pipe Address of the pipe.
##  @param buffer Address of the pipe's ring buffer, or NULL if no ring buffer
##                is used.
##  @param size Size of the pipe's ring buffer (in bytes), or zero if no ring
##              buffer is used.
##
##  @return N/A
##
proc k_pipe_init*(pipe: ptr k_pipe; buffer: ptr cuchar; size: csize_t) {.
    importc: "k_pipe_init", header: "kernel.h".}


## *
##  @brief Release a pipe's allocated buffer
##
##  If a pipe object was given a dynamically allocated buffer via
##  k_pipe_alloc_init(), this will free it. This function does nothing
##  if the buffer wasn't dynamically allocated.
##
##  @param pipe Address of the pipe.
##  @retval 0 on success
##  @retval -EAGAIN nothing to cleanup
##
proc k_pipe_cleanup*(pipe: ptr k_pipe): cint {.importc: "k_pipe_cleanup",
    header: "kernel.h".}


## *
##  @brief Initialize a pipe and allocate a buffer for it
##
##  Storage for the buffer region will be allocated from the calling thread's
##  resource pool. This memory will be released if k_pipe_cleanup() is called,
##  or userspace is enabled and the pipe object loses all references to it.
##
##  This function should only be called on uninitialized pipe objects.
##
##  @param pipe Address of the pipe.
##  @param size Size of the pipe's ring buffer (in bytes), or zero if no ring
##              buffer is used.
##  @retval 0 on success
##  @retval -ENOMEM if memory couldn't be allocated
##
proc k_pipe_alloc_init*(pipe: ptr k_pipe; size: csize_t): cint {.zsyscall,
    importc: "k_pipe_alloc_init", header: "kernel.h".}


## *
##  @brief Write data to a pipe.
##
##  This routine writes up to @a bytes_to_write bytes of data to @a pipe.
##
##  @param pipe Address of the pipe.
##  @param data Address of data to write.
##  @param bytes_to_write Size of data (in bytes).
##  @param bytes_written Address of area to hold the number of bytes written.
##  @param min_xfer Minimum number of bytes to write.
##  @param timeout Waiting period to wait for the data to be written,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @retval 0 At least @a min_xfer bytes of data were written.
##  @retval -EIO Returned without waiting; zero data bytes were written.
##  @retval -EAGAIN Waiting period timed out; between zero and @a min_xfer
##                  minus one data bytes were written.
##
proc k_pipe_put*(pipe: ptr k_pipe; data: pointer; bytes_to_write: csize_t;
                bytes_written: ptr csize_t; min_xfer: csize_t; timeout: k_timeout_t): cint {.
    zsyscall, importc: "k_pipe_put", header: "kernel.h".}


## *
##  @brief Read data from a pipe.
##
##  This routine reads up to @a bytes_to_read bytes of data from @a pipe.
##
##  @param pipe Address of the pipe.
##  @param data Address to place the data read from pipe.
##  @param bytes_to_read Maximum number of data bytes to read.
##  @param bytes_read Address of area to hold the number of bytes read.
##  @param min_xfer Minimum number of data bytes to read.
##  @param timeout Waiting period to wait for the data to be read,
##                 or one of the special values K_NO_WAIT and K_FOREVER.
##
##  @retval 0 At least @a min_xfer bytes of data were read.
##  @retval -EINVAL invalid parameters supplied
##  @retval -EIO Returned without waiting; zero data bytes were read.
##  @retval -EAGAIN Waiting period timed out; between zero and @a min_xfer
##                  minus one data bytes were read.
##
proc k_pipe_get*(pipe: ptr k_pipe; data: pointer; bytes_to_read: csize_t;
                bytes_read: ptr csize_t; min_xfer: csize_t; timeout: k_timeout_t): cint {.
    zsyscall, importc: "k_pipe_get", header: "kernel.h".}


## *
##  @brief Query the number of bytes that may be read from @a pipe.
##
##  @param pipe Address of the pipe.
##
##  @retval a number n such that 0 <= n <= @ref k_pipe.size; the
##          result is zero for unbuffered pipes.
##
proc k_pipe_read_avail*(pipe: ptr k_pipe): csize_t {.zsyscall,
    importc: "k_pipe_read_avail", header: "kernel.h".}


## *
##  @brief Query the number of bytes that may be written to @a pipe
##
##  @param pipe Address of the pipe.
##
##  @retval a number n such that 0 <= n <= @ref k_pipe.size; the
##          result is zero for unbuffered pipes.
##
proc k_pipe_write_avail*(pipe: ptr k_pipe): csize_t {.zsyscall,
    importc: "k_pipe_write_avail", header: "kernel.h".}
