STD := 93
SRC_PATH := -P./src
TB_SRC_PATH := -P./tb
WORK_DIR := ghdl
SRC := \
	src/iir2.vhd \
	src/top.vhd \
	tb/stimuli.vhd

TB := stimuli
TB_ARCH := behavioral

check: $(SRC) $(TB_SRC)
	ghdl -s --std=$(STD) --workdir=$(WORK_DIR) \
		$(SRC_PATH) $(TB_SRC_PATH) $(SRC)

analyze: $(SRC) $(TB_SRC)
	ghdl -a --std=$(STD) --workdir=$(WORK_DIR) \
		$(SRC_PATH) $(TB_SRC_PATH) $(SRC) $(TB_SRC)

run: analyze
	ghdl -r --workdir=$(WORK_DIR) $(TB)

clean:
	rm -f $(WORK_DIR)/*
