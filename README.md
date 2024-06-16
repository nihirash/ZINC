ZINC - ZINC is Not CP/M
=======================

CP/M compatibility layer for Agon's MOS. 

Requires ez80asm 1.6 or later for building it.

**CAUTION** It is early development version - possibly unstable behavior or any issues, use it on your risk.

## Usage

Download from releases page `zinc.bin`(use only latest release) and copy it to `mos/` directory of your sd card.

After this you'll have possibility run CP/M applications with `zinc` command like:

```
zinc mbasic test
```

You shouldn't specify file extension for executable file(`.com` will be added automatically) and directory should no contain files with long file names.

### Using UART1 from CP/M Applications

UART1 is accessible via IOBYTE(you can switch character input/output from terminal emulator to UART1 just changing one byte in RAM). 

Before using UART use `zinc-setup` utility - it's interactive tool for setting UART parameters. 

## Terminal emulation layer

Currently, it supports "ADM-3a"-like compatible terminal emulation routines(like KayPro or some other computers). 

It also allows disable(and re-enable terminal emulation routines) with `27, 255`(two bytes, 27 in decimal first, 255 in decimal secord) character sequence. If you disable terminal emulation routines you'll have possibility use all Agon's VDP commands, including graphics, sounds etc. Also you can get back to terminal emulation mode by same sequence. 

### Control sequences and codes

 * `0x01` - Home cursor

 * `0x07` - Bell(makes single beep)

 * `0x08` - move cursor left on one character

 * `0x0C` - move cursor right on one character

 * `0x14` - move cursor up on one character

 * `0x16` - move cursor left on one character

 * `0x17` - move cursor right on one character

 * `0x18` - clean current line(after current cursor position)

 * `0x1A` - clean screen

 * `0x1B` - ESCAPE control sequences:
  
    - `ESC`+`=` - load cursor position(`ESC`+`=`+`y-coordinate`+`x-coordinate`)
    
    - `ESC`+`0xFF` - toggle terminal emulation(enable or disable it)

## Development

You should use fresh version of [agon-ez80asm](https://github.com/envenomator/agon-ez80asm) for building system.

Sources splitted by two parts: loader(also replaces CCP) and EDOS(BDOS+BIOS replacement).

## Support me

You can support me via my [Ko-Fi page](https://ko-fi.com/nihirash).

## License

This project licensed with [Nihirash's Coffeeware License](LICENSE). 

It isn't hard to respect it.