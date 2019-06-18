full:
	vlib work
	vlog ./*.sv
	vsim -c top -do "run -all; quit"
compile:
	vlib work
	vlog ./*.sv
run:
	vsim -c top -do "run -all; quit"
clean:
	rm -rf work transcript vsim.wlf
