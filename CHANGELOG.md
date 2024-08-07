# Changelog

## 2024.07.26

 * Preserving DE in BDOS calls - very small count of applications waits for this

 * UART can be configured for 300 Bauds 

## 2024.07.03

 * ez80asm updated to 1.8 version

 * Buffered read input can be interrupted with ESC key(with application shutdown)

 * Applications directory added(added kermit sources and binary, z80asm and UART1 usage examples)

 * Set color control code

 * Terminal emulation minor fixes

## 2024.06.22

 * BBC Basic partly working with files but still have issues

 * Tracing of DOS calls removed

 * All API calls implemented

 * Fixed WordStar 3 file operations

## 2024.06.16

 * Uart parameters can be configured with "zinc-setup" configuration utility

 * EDOS now handles CTRL-C via console status call

 * LU310 was fixed

 * Disable VDP commands via keypresses for more correct terminal emulation

 * All terminal code moved out of BIOS

 * UART1 is accessible via IOByte

## 2024.06.09

 * Better ADM-3a terminal emulation

 * Possibility disable it and use VDP commands

## 2024.05.04

 * Very basic ADM-3 terminal emulation

 * "Update random access pointer" call implemented 

 * "Printer" now outputs to VPD's printer

 * Console status and reading working fine now

## 2024.05.02

 * File leak fixed

 * Compute file size call implemented

 * More correct error handling(allows Turbo Pascal execution)

## 2024.04.27

 * First public build(system version call returns version 2.9)

 * Basic console and file operations implemented(Mike's Enhanced Small C Compiler works, Microsoft Basic, Tasty Basic, Zork and many other utils working)