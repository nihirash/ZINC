ASM=sjasmplus
SOURCES:=$(shell find src -type f -iname  "*.asm")
BINARY=zinc.bin
EDOS=src/edos/edos.bin

all: $(BINARY)

$(BINARY): $(EDOS) $(SOURCES)
	(cd src && ez80asm -i -l zinc.asm ../$(BINARY))

$(EDOS): $(SOURCES)
	date '+%Y.%m.%d' >.version
	(cd src/edos && ez80asm -i -l edos.asm)
	
	
clean:
	rm -rf $(EDOS) $(BINARY)