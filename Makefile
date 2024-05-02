ASM=sjasmplus
SOURCES:=$(shell find src -type f -iname  "*.asm")
BINARY=zinc.bin
EDOS=src/edos/edos.bin

all: $(BINARY)

$(BINARY): $(EDOS) $(SOURCES) .version
	(cd src && ez80asm -i zinc.asm ../$(BINARY))

$(EDOS): $(SOURCES)
	(cd src/edos && ez80asm -i -l edos.asm)
	
.version:
	date '+%Y.%m.%d' >.version
	
clean:
	rm -rf $(EDOS) $(BINARY)