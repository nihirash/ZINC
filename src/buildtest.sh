(cd edos && ez80asm -b 00 -l test.asm)
ez80asm -b 00 runcpm.asm
cp runcpm.bin ../emul/sdcard/bin
(cd ../emul && ./fab-agon-emulator -d)
