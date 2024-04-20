#!/bin/bash 
set -e

(cd edos && ez80asm -i -l edos.asm)
ez80asm -b 00 zinc.asm
cp zinc.bin ../emul/sdcard/mos
(cd ../emul && ./fab-agon-emulator -d)
