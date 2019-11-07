# Specify the mode- could be either puresim or veloce
# Always make sure that everything works fine in puresim before changing to veloce
# Mode is compiled for puresim for simulation or veloce for emulation

help:
	@echo -e "\n\n\t\t\tMakefile options: \n \
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \n \
	*                                                                   * \n \
	*  make sim: clean-puresim lib build run                            * \n \
	*  make emu: clean-veloce vlib vbuild run                           * \n \
	*  make sim-all: clean-puresim lib build run-all                    * \n \
	*  make emu-all: clean-veloce vlib vbuild run-all                   * \n \
	*  make sim-cover: clean-puresim lib build-cover run-cover report   * \n \
	*  make emu-cover: clean-veloce vlib vbuild-cover run-cover report  * \n \
	*  make exp: clean-experiment experiment                            * \n \
	*                                                                   * \n \
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \n\n"

# make sim runs all in the 'puresim' environment
sim: clean-puresim lib build run
sim-all: clean-puresim lib build run-all
sim-cover: clean-puresim lib build-cover run-cover report

# make emu runs all in the 'veloce' environment
emu: clean-veloce vlib vbuild run
emu-all: clean-veloce vlib vbuild run-all
emu-cover: clean-veloce vlib vbuild-cover run-cover report

# make exp runs a side experiment that does not intersect with the design
exp: experiment

lib:
	vlib work_puresim
	vmap work work_puresim

vlib:
	vlib work_veloce
	vmap work work_veloce

build:
	vlog -f common_utils.f
	vlog -f hvl_files.f
	vlog -f hdl_files.f
	tbxsvlink -puresim

vbuild:
	vlog -f common_utils.f
	vlog -f hvl_files.f
	vlog -f hdl_files.f
	velanalyze -f common_utils.f
	velanalyze -f hdl_files.f
	velanalyze -extract_hvl_info -f hvl_files.f
	velcomp -top mpu_top
	velhvl -sim veloce

build-cover:
	vlog -cover bcst -f common_utils.f
	vlog -cover bcst -f hvl_files.f
	vlog -cover bcfst -f hdl_files.f
	tbxsvlink -puresim

vbuild-cover:
	vlog -cover bcst -f common_utils.f
	vlog -cover bcst -f hvl_files.f
	vlog -cover bcfst -f hdl_files.f
	velanalyze -f common_utils.f
	velanalyze -f hdl_files.f
	velanalyze -extract_hvl_info -f hvl_files.f
	velcomp -top mpu_top
	velhvl -sim veloce

run:
	#vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=load_store +RUNS=10
	#vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=cluster_unit +RUNS=10
	#vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_positive_ones +RUNS=10
	#vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_negative_ones +RUNS=10
	#vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_zero +RUNS=10
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_inverse +RUNS=10
	#vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=overflow_underflow +RUNS=10

run-all:
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=load_store +RUNS=10
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=cluster_unit +RUNS=10
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_positive_ones +RUNS=10
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_negative_ones +RUNS=10
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_zero +RUNS=10
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=multiply_inverse +RUNS=10
	vsim -c -do "run -all; quit -f" top_tb mpu_top +TESTCASE=overflow_underflow +RUNS=10

run-cover:
	vsim -c -do "coverage save -onexit coverage/mpu_cov.ucdb; run -all; quit -f" -coverage top_tb mpu_top

report:
	vcover report -html -htmldir coverage -verbose -threshL 50 -threshH 90 coverage/mpu_cov.ucdb

clean-puresim:
	rm -rf coverage/*
	rm -rf modelsim.ini
	rm -rf tbx.log/
	rm -rf tbx.med/
	rm -rf transcript
	rm -rf work_puresim/

clean-veloce:
	rm -rf coverage/*
	rm -rf edsenv
	rm -rf modelsim.ini
	rm -rf tbxbindings.h
	rm -rf transcript
	rm -rf veloce.log/
	rm -rf veloce.map
	rm -rf veloce.med/
	rm -rf veloce.wave/
	rm -rf velrunopts.ini
	rm -rf work_veloce/

clean-experiment:
	rm -rf work/
	rm -rf transcript

clean: clean-puresim clean-veloce clean-experiment

celan: clean

# Run a side experiment
experiment:
	vlib work
	vlog src/experimental/top_exp.sv
	vsim -c -do "run -all; quit -f" top_exp
