#!/usr/bin/env sh
set -eu
nasm -f bin -I include/ -o build/stage1.bin boot/stage1.asm
nasm -f bin -I include/ -o build/stage2.bin boot/stage2.asm
nasm -f bin -I include/ -I kernel/ -w- -o build/kernel.bin kernel/link.asm
