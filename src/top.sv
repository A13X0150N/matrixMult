// top.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// Top-level design for DUT and testbench. Eventually migrate UVM.

import mm_defs::*;

module top;
	initial $display("\n\tTop module\n");
	initial	#(CLOCK_PERIOD*1000) $stop;

	bit clk = 0;
	bit clk_en = 1;
	bit rst_n = 1;

	initial begin
		reset;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end

	fpu_multiplier_tb mult_test(clk, clk_en, rst_n);
	
	final $display("\n\tEnd of test\n\n");

	task clock_pulse;
		#(CLOCK_PERIOD/2) clk = 0;
		#(CLOCK_PERIOD/2) clk = 1;
		#(CLOCK_PERIOD/2) clk = 0;
	endtask

	task reset;
		clock_pulse;
		rst_n = 0;
		clock_pulse;
		rst_n = 1;
		clock_pulse;
	endtask

endmodule : top