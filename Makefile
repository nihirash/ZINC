ASM=ez80asm
ASM_FLAGS:=-i -l -v
SOURCES:=$(shell find src/zinc -type f -iname  "*.asm")
BINARY=zinc.bin
EDOS=src/zinc/edos/edos.bin

SETUP_SOURCES:=$(shell find src/zinc-setup -type f -iname  "*.asm")
SETUP_BINARY:=zinc-setup.bin


all: $(BINARY) $(SETUP_BINARY)

$(BINARY): $(EDOS) $(SOURCES)
	(cd src/zinc && $(ASM) $(ASM_FLAGS) zinc.asm ../../$(BINARY))

$(EDOS): $(SOURCES)
	date '+%Y.%m.%d' >.version
	(cd src/zinc/edos && $(ASM) $(ASM_FLAGS) edos.asm)

$(SETUP_BINARY): $(SETUP_SOURCES)
		(cd src/zinc-setup && $(ASM) $(ASM_FLAGS) zinc-setup.asm ../../$(SETUP_BINARY))

clean:
	rm -rf $(EDOS) $(BINARY)