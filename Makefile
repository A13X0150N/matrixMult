full:
	vlib work
	vlog src/*.sv
	vlog src/dut/*.sv
	vlog src/testbench/*sv
	vsim -c top -do "run -all; quit"

compile:
	vlib work
	vlog src/*.sv
	vlog src/dut/*.sv
	vlog src/testbench/*sv

run:
	vsim -c top -do "run -all; quit"

clean:
	rm -rf work transcript vsim.wlf
