# Changelog

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