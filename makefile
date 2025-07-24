rtl = code/rtl/*
verif = code/verif/*

all: simulate

work:
	@if [ ! -d test ]; then \
		echo "\033[0;36mCreating 'test' directory......\033[0m"; \
		mkdir test; \
	fi
	@if [ ! -d test/work ]; then \
		echo "\033[0;36mCreating Library named 'work'.....\033[0m"; \
		vlib test/work; \
	fi

compile: work
	vlog -work test/work  $(rtl) $(verif) || { echo "\033[0;31mCompilation Failed!\033[0m"; exit 1; }

simulate: compile
	vsim -c test/work.Dmac_Top_tb -do "run -all; quit;"

wave: compile
	vsim test/work.Dmac_Top_tb -do "\
		add wave *; \
		add wave -position insertpoint sim:/Dmac_Top_tb/dut/channel_en_1; \
		add wave -position insertpoint sim:/Dmac_Top_tb/dut/channel_en_2; \
		add wave -position insertpoint sim:/Dmac_Top_tb/dest/mem; \
		run -all;"
