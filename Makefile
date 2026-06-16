# Navine OS - Native Build (NASM flat binary, no WSL, no cross-linker)

NASM      ?= nasm
PYTHON    ?= python3

BUILD_DIR  = build
STAGE1_BIN = $(BUILD_DIR)/stage1.bin
STAGE2_BIN = $(BUILD_DIR)/stage2.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
DISK_IMG   = $(BUILD_DIR)/navine.img
ISO_IMG    = $(BUILD_DIR)/Navine OS.iso

NASM_BIN = -f bin -I include/

ifeq ($(OS),Windows_NT)
DISK_CMD = powershell -NoProfile -ExecutionPolicy Bypass -File tools/mkdisk.ps1 -BuildDir $(BUILD_DIR)
else
DISK_CMD = $(PYTHON) tools/mkdisk.py $(BUILD_DIR)
endif

all: dirs boot kernel apps iso

dirs:
	@mkdir -p $(BUILD_DIR)

boot: dirs $(STAGE1_BIN) $(STAGE2_BIN)

$(STAGE1_BIN): boot/stage1.asm include/constants.inc
	$(NASM) $(NASM_BIN) -o $@ boot/stage1.asm

$(STAGE2_BIN): boot/stage2.asm include/constants.inc
	$(NASM) $(NASM_BIN) -o $@ boot/stage2.asm

kernel: dirs $(KERNEL_BIN)

$(KERNEL_BIN): kernel/link.asm include/constants.inc include/macros.inc
	$(NASM) $(NASM_BIN) -I kernel/ -w- -o $@ kernel/link.asm

apps: dirs
ifeq ($(OS),Windows_NT)
	cmd /c apps\doom\build-doom.bat
	cmd /c apps\system\build-system.bat
else
	@echo "C/C++ app build scripts are currently Windows batch files."
endif

iso: boot kernel $(DISK_IMG) $(ISO_IMG)

$(DISK_IMG): $(STAGE1_BIN) $(STAGE2_BIN) $(KERNEL_BIN)
	$(DISK_CMD)

vbox:
	powershell -NoProfile -ExecutionPolicy Bypass -File tools/vbox-create.ps1 -BuildDir $(BUILD_DIR)

$(ISO_IMG): $(DISK_IMG)
	$(PYTHON) tools/mkiso_eltorito.py $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

install: iso
	@echo "Navine OS image ready: $(DISK_IMG)"
