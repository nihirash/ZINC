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

## Development

You should use fresh version of [agon-ez80asm](https://github.com/envenomator/agon-ez80asm) for building system.

Sources splitted by two parts: loader(also replaces CCP) and EDOS(BDOS+BIOS replacement).

## Support me

You can support me via my [Ko-Fi page](https://ko-fi.com/nihirash).

## License

This project licensed with [Nihirash's Coffeeware License](LICENSE). 

It isn't hard to respect it.