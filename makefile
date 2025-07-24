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
	vsim -c -suppress vopt-7061 test/work.Dmac_Top_tb -do "run -all; quit;" || { echo "\033[0;31mSimulation Failed!\033[0m"; exit 1; }

wave: compile
	vsim -suppress vopt-7061 test/work.Dmac_Top_tb -do "add wave *; run -all;" || { echo "\033[0;31mSimulation (GUI) Failed!\033[0m"; exit 1; }
