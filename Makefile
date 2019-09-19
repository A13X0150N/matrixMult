# Specify the mode- could be either puresim or veloce
# Always make sure that everything works fine in puresim before changing to veloce
# Mode is compiled for puresim for simulation or veloce for emulation

# make sim runs all in the 'puresim' environment
sim: clean work build run

# make emu runs all in the 'veloce' environment
emu: clean work vbuild run

# make exp runs a side experiment that does not intersect with the design
exp: clean experiment

# Create respective work libs and map them
work:
	vlib work
	vmap work work

# Compile/synthesize the simulation environment
build:
	vlog src/pkg/packages.sv					# Compile the package
	vlog src/tb/scoreboard_tb.sv				# Compile the scoreboard
	vlog src/tb/driver_tb.sv					# Compile the driver
	vlog src/tb/checker_tb.sv					# Compile the checker
	vlog src/tb/testbench_tb.sv					# Compile the testbench
	vlog src/tb/top_tb.sv 						# Compile the top-level testbench
	vlog src/dut/mpu_bfm.sv						# Compile the MPU interface
	vlog src/dut/mpu_register_file.sv			# Compile the DUT register files
	vlog src/dut/mpu_load.sv					# Compile the load stage
	vlog src/dut/mpu_store.sv					# Compile the store stage
	vlog src/dut/fpu_fma.sv						# Compile the FPU
	vlog src/dut/fma_cluster.sv					# Compile the FMA cluster
	vlog src/dut/mpu_controller.sv 				# Compile the controller
	vlog src/dut/mpu_dispatcher.sv 				# Compile the dispatcher
	vlog src/dut/mpu_collector.sv 				# Compile the collector
	vlog src/dut/mpu_top.sv						# Compile the HDL top
	velhvl -sim puresim

# Compile/synthesize the emulation environment
vbuild:
	vlog src/pkg/packages.sv					# Compile the package
	vlog src/tb/scoreboard_tb.sv				# Compile the scoreboard
	vlog src/tb/driver_tb.sv					# Compile the driver
	vlog src/tb/checker_tb.sv					# Compile the checker
	vlog src/tb/testbench_tb.sv					# Compile the testbench
	vlog src/tb/top_tb.sv		   				# Compile the top-level testbench		
	velanalyze src/pkg/packages.sv				# Analyze the package for synthesis
	velanalyze -extract_hvl_info +define+QUESTA src/tb/driver_tb.sv	# Analyze the HVL for external task calls in BFM
	velanalyze src/dut/mpu_bfm.sv				# Analyze the MPU interface for synthesis
	velanalyze src/dut/mpu_top.sv				# Analyze the HDL top for synthesis
	velanalyze src/dut/mpu_register_file.sv		# Analyze the DUT register files for synthesis
	velanalyze src/dut/mpu_load.sv				# Analyze the load stage
	velanalyze src/dut/mpu_store.sv				# Analyze the store stage
	velanalyze src/dut/fpu_fma.sv				# Analyze the FPU
	velanalyze src/dut/fma_cluster.sv			# Analyze the FMA cluster
	velanalyze src/dut/mpu_controller.sv		# Analyze the controller
	velanalyze src/dut/mpu_dispatcher.sv		# Analyze the dispatcher
	velanalyze src/dut/mpu_collector.sv			# Analyze the collector
	velcomp -top mpu_top   						# Synthesize!
	velhvl -sim veloce -enable_profile_report

# Run a quick experiment on the side
experiment:
	vlib work
	vlog src/experimental/top_exp.sv
	vsim -c -do "run -all; quit -f" top_exp		# Run experiment

# Run simulation or emulation
run:
	vsim -c -do "run -all; quit -f" top_tb mpu_top	# Run all

# Clean the environment
clean:
	rm -rf tbxbindings.h 
	rm -rf modelsim.ini 
	rm -rf work
	rm -rf transcript
	rm -rf *~
	rm -rf vsim.wlf
	rm -rf *.log
	rm -rf dgs.dbg
	rm -rf dmslogdir
	rm -rf veloce.med
	rm -rf veloce.wave
	rm -rf veloce.map
	rm -rf velrunopts.ini
	rm -rf edsenv
