all:
	vlib work
	vlog src/pkg/*.sv
	vlog src/dut/*.sv
	vlog src/tb/*.sv
	vlog src/*.sv
	vsim -c top -do "run -all; quit"

compile:
	vlib work
	vlog src/pkg/*.sv
	vlog src/dut/*.sv
	vlog src/tb/*.sv
	vlog src/*.sv

run:
	vsim -c top -do "run -all; quit"

clean:
	rm -rf work transcript vsim.wlf
