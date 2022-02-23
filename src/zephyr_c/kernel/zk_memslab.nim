
import ../zconfs
import ../zkernel_fixes
import ../sys/zsys_heap

type
  k_mem_slab* {.importc: "k_mem_slab", header: "kernel.h", incompleteStruct, bycopy.} = object
    wait_q* {.importc: "wait_q".}: z_wait_q_t
    lock* {.importc: "lock".}: k_spinlock
    num_blocks* {.importc: "num_blocks".}: uint32
    block_size* {.importc: "block_size".}: csize_t
    buffer* {.importc: "buffer".}: cstring
    free_list* {.importc: "free_list".}: cstring
    num_used* {.importc: "num_used".}: uint32
    when CONFIG_MEM_SLAB_TRACE_MAX_UTILIZATION:
      max_used* {.importc: "max_used".}: uint32


# proc Z_MEM_SLAB_INITIALIZER*(obj: untyped; slab_buffer: untyped;
                            # slab_block_size: untyped; slab_num_blocks: untyped) {.
    # importc: "Z_MEM_SLAB_INITIALIZER", header: "kernel.h".}


## *
##  INTERNAL_HIDDEN @endcond
##
## *
##  @defgroup mem_slab_apis Memory Slab APIs
##  @ingroup kernel_apis
##  @{
##
## *
##  @brief Statically define and initialize a memory slab.
##
##  The memory slab's buffer contains @a slab_num_blocks memory blocks
##  that are @a slab_block_size bytes long. The buffer is aligned to a
##  @a slab_align -byte boundary. To ensure that each memory block is similarly
##  aligned to this boundary, @a slab_block_size must also be a multiple of
##  @a slab_align.
##
##  The memory slab can be accessed outside the module where it is defined
##  using:
##
##  @code extern struct k_mem_slab <name>; @endcode
##
##  @param name Name of the memory slab.
##  @param slab_block_size Size of each memory block (in bytes).
##  @param slab_num_blocks Number memory blocks.
##  @param slab_align Alignment of the memory slab's buffer (power of 2).
##
# proc K_MEM_SLAB_DEFINE*(name: cminvtoken; slab_block_size: untyped;
                        # slab_num_blocks: untyped; slab_align: untyped) {.
    # importc: "K_MEM_SLAB_DEFINE", header: "kernel.h".}


## *
##  @brief Initialize a memory slab.
##
##  Initializes a memory slab, prior to its first use.
##
##  The memory slab's buffer contains @a slab_num_blocks memory blocks
##  that are @a slab_block_size bytes long. The buffer must be aligned to an
##  N-byte boundary matching a word boundary, where N is a power of 2
##  (i.e. 4 on 32-bit systems, 8, 16, ...).
##  To ensure that each memory block is similarly aligned to this boundary,
##  @a slab_block_size must also be a multiple of N.
##
##  @param slab Address of the memory slab.
##  @param buffer Pointer to buffer used for the memory blocks.
##  @param block_size Size of each memory block (in bytes).
##  @param num_blocks Number of memory blocks.
##
##  @retval 0 on success
##  @retval -EINVAL invalid data supplied
##
##
proc k_mem_slab_init*(slab: ptr k_mem_slab; buffer: pointer; block_size: csize_t;
                      num_blocks: uint32): cint {.importc: "k_mem_slab_init",
    header: "kernel.h".}


## *
##  @brief Allocate memory from a memory slab.
##
##  This routine allocates a memory block from a memory slab.
##
##  @note @a timeout must be set to K_NO_WAIT if called from ISR.
##  @note When CONFIG_MULTITHREADING=n any @a timeout is treated as K_NO_WAIT.
##
##  @funcprops \isr_ok
##
##  @param slab Address of the memory slab.
##  @param mem Pointer to block address area.
##  @param timeout Non-negative waiting period to wait for operation to complete.
##         Use K_NO_WAIT to return without waiting,
##         or K_FOREVER to wait as long as necessary.
##
##  @retval 0 Memory allocated. The block address area pointed at by @a mem
##          is set to the starting address of the memory block.
##  @retval -ENOMEM Returned without waiting.
##  @retval -EAGAIN Waiting period timed out.
##  @retval -EINVAL Invalid data supplied
##
proc k_mem_slab_alloc*(slab: ptr k_mem_slab; mem: ptr pointer; timeout: k_timeout_t): cint {.
    importc: "k_mem_slab_alloc", header: "kernel.h".}


## *
##  @brief Free memory allocated from a memory slab.
##
##  This routine releases a previously allocated memory block back to its
##  associated memory slab.
##
##  @param slab Address of the memory slab.
##  @param mem Pointer to block address area (as set by k_mem_slab_alloc()).
##
##  @return N/A
##
proc k_mem_slab_free*(slab: ptr k_mem_slab; mem: ptr pointer) {.
    importc: "k_mem_slab_free", header: "kernel.h".}


## *
##  @brief Get the number of used blocks in a memory slab.
##
##  This routine gets the number of memory blocks that are currently
##  allocated in @a slab.
##
##  @param slab Address of the memory slab.
##
##  @return Number of allocated memory blocks.
##
proc k_mem_slab_num_used_get*(slab: ptr k_mem_slab): uint32 {.
    importc: "$1", header: "kernel.h".}

## *
##  @brief Get the number of maximum used blocks so far in a memory slab.
##
##  This routine gets the maximum number of memory blocks that were
##  allocated in @a slab.
##
##  @param slab Address of the memory slab.
##
##  @return Maximum number of allocated memory blocks.
##
proc k_mem_slab_max_used_get*(slab: ptr k_mem_slab): uint32 {.
    importc: "$1", header: "kernel.h".}

## *
##  @brief Get the number of unused blocks in a memory slab.
##
##  This routine gets the number of memory blocks that are currently
##  unallocated in @a slab.
##
##  @param slab Address of the memory slab.
##
##  @return Number of unallocated memory blocks.
##
proc k_mem_slab_num_free_get*(slab: ptr k_mem_slab): uint32 {.
    importc: "$1", header: "kernel.h".}

## * @}
## *
