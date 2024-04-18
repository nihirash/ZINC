#!/bin/bash 
set -e

(cd edos && ez80asm -b 00 -l edos.asm)
ez80asm -b 00 runcpm.asm
cp runcpm.bin ../emul/sdcard/bin
(cd ../emul && ./fab-agon-emulator -d)
