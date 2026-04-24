# Project-specific settings
EMP_DIR := third-party/Empirical/include

SGP_DIR := third-party/SignalGP/include
PSB_DIR := third-party/psb-cpp/include

# PROJECT := std_cgp
PROJECT := prog_synth
MAIN_CPP ?= source/${PROJECT}.cpp

# Flags to use regardless of compiler
CFLAGS_SGP := -I$(SGP_DIR)/ -I$(PSB_DIR)
CFLAGS_all := -Wall -Wno-unused-function -std=c++23 -lstdc++fs -I$(EMP_DIR)/ -Iinclude/ -Ithird-party/ $(CFLAGS_SGP)

# Native compiler information
CXX ?= g++14
CXX_nat = $(CXX)
CFLAGS_nat := -O3 -DNDEBUG $(CFLAGS_all) # -msse4.2
CFLAGS_nat_debug := -g -DEMP_TRACK_MEM $(CFLAGS_all)

default: $(PROJECT)
native: $(PROJECT)
all: $(PROJECT) $(PROJECT).js

debug:	CFLAGS_nat := $(CFLAGS_nat_debug)
debug:	$(PROJECT)

$(PROJECT): ${MAIN_CPP} include/
	$(CXX_nat) $(CFLAGS_nat) ${MAIN_CPP} -o $(PROJECT)

clean:
	rm -f $(PROJECT) web/$(PROJECT).js web/*.js.map web/*.js.map *~ source/*.o

# Debugging information
print-%: ; @echo '$(subst ','\'',$*=$($*))'
