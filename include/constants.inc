; Navine OS - Global Constants
; Shared equates for boot, kernel, and userland

%ifndef NAVINE_CONSTANTS_INC
%define NAVINE_CONSTANTS_INC

; Memory layout
%define STAGE1_LOAD_ADDR       0x00007C00
%define STAGE2_LOAD_ADDR       0x00007E00
%define STAGE2_SECTOR          2
%define STAGE2_SECTOR_COUNT    32
%define STAGE2_MAGIC           0x3249564E
%define STAGE2_MAGIC_OFFSET    2
%define KERNEL_DISK_SECTOR     34
%define KERNEL_MAX_SECTORS     1024
%define DISK_TOTAL_SECTORS     65536
%define PML4_PHYS              0x00320000
%define PDPT_PHYS              0x00321000
%define PD_PHYS                0x00322000
%define PD_TABLE_COUNT         4
%define KERNEL_LOAD_PHYS       0x00010000
%define KERNEL_LINK_ADDR       0x00010000
%define BOOT_STACK_TOP         0x0009F000
%define KERNEL_STACK_TOP       0x00380000
%define FB_INFO_PHYS           0x00005000
%define FB_INFO_GFX_OK         24
%define FB_INFO_BPP_OFF        20
%define INSTALL_FLAG_PHYS      0x00005200
%define INSTALL_FLAG_SECTOR    1
%define INSTALL_MAGIC          0x4956414E
%define DOOM_WAD_SIZE_PHYS     0x00005020
%define DOOM_LOAD_PHYS         0x02000000
%define DOOM_WAD_PHYS          0x03000000
%define DOOM_STACK_TOP         0x02F00000
%define DOOM_BIN_LBA           8192
%define DOOM_BIN_SECTORS       1024
%define DOOM_WAD_LBA           9216
%define NAVAPP_BIN_LBA         30000
%define NAVAPP_BIN_SECTORS     256
%define NAVAPP_LOAD_PHYS       0x01800000
%define WALLPAPER_LBA          12800
%define WALLPAPER_SECTORS      16200
%define WALLPAPER_PHYS         0x00800000
%define COMPOSITOR_BACKBUFFER_PHYS 0x01000000
%ifndef DOOM_WAD_INC
%define DOOM_WAD_SECTORS       3584
%define DOOM_WAD_BYTES         (DOOM_WAD_SECTORS * SECTOR_SIZE)
%endif

; Disk geometry
%define SECTOR_SIZE            512
%define BOOT_DRIVE             0x80

; ELF constants
%define ELF_MAGIC              0x464C457F
%define ELFCLASS64             2
%define ELFDATA2LSB            1
%define ET_EXEC                2
%define PT_LOAD                1

; Paging
%define PAGE_PRESENT           (1 << 0)
%define PAGE_WRITE             (1 << 1)
%define PAGE_USER              (1 << 2)
%define PAGE_SIZE              4096
%define PAGE_TABLE_ENTRIES     512

; PIC
%define PIC1_COMMAND           0x20
%define PIC1_DATA              0x21
%define PIC2_COMMAND           0xA0
%define PIC2_DATA              0xA1
%define PIC_EOI                0x20

; PIT
%define PIT_CHANNEL0           0x40
%define PIT_COMMAND            0x43
%define PIT_FREQUENCY          1000

; PS/2
%define PS2_DATA_PORT          0x60
%define PS2_STATUS_PORT        0x64
%define PS2_COMMAND_PORT       0x64

; ATA primary
%define ATA_PRIMARY_IO         0x1F0
%define ATA_PRIMARY_CTRL       0x3F6

; Syscalls
%define SYS_EXIT               1
%define SYS_FORK               2
%define SYS_READ               3
%define SYS_WRITE              4
%define SYS_OPEN               5
%define SYS_CLOSE              6
%define SYS_EXEC               7
%define SYS_WAIT               8
%define SYS_GETPID             9
%define SYS_SLEEP              10
%define SYS_BRK                11
%define SYS_MMAP               12
%define SYS_SOCKET             20
%define SYS_CONNECT            21
%define SYS_SEND               22
%define SYS_RECV               23
%define SYS_IOCTL              30
%define SYS_GETTIME            40

; VESA mode
%define VESA_WIDTH             1920
%define VESA_HEIGHT            1080
%define VESA_BPP               32

; NavineFS magic
%define NAVINEFS_MAGIC         0x4E415649
%define NAVINEFS_VERSION       1

; Process limits
%define MAX_PROCESSES          64
%define MAX_FDS                32
%ifdef NAVINE_LINK_BUILD
%define KERNEL_HEAP_SIZE       (64 * 1024)
%else
%define KERNEL_HEAP_SIZE       (4 * 1024 * 1024)
%endif
%define USER_STACK_SIZE        (64 * 1024)

; Colors (ARGB)
%define COLOR_BLACK            0xFF000000
%define COLOR_WHITE            0xFFFFFFFF
%define COLOR_NAVINE_BLUE      0xFF007AFF
%define COLOR_NAVINE_GRAY      0xFF2C2C2E
%define COLOR_DOCK_BG          0xCC1C1C1E
%define COLOR_MENUBAR_BG       0xE01C1C1E
%define COLOR_TERMINAL_BG      0xCC1E1E20

%endif
