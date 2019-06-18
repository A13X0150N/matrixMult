// top.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// Top-level design for DUT and testbench. Eventually migrate UVM.

import mm_defs::*;

module top;
	initial $display("\n\tTop module\n");
	initial	#0100 $stop;

	bit clk = 0;
	bit rst_n = 1;

	initial begin
		#2 rst_n = 0;
		#2 rst_n = 1;
		forever #5 clk = ~clk;
	end

	multiply_tb test(clk, rst_n);
	
	final $display("\n\tEnd of test\n\n");

endmodule : top
