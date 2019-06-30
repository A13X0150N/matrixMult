// ao_multiply_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Simple testbench for binary multiplier. Eventually migrate to UVM.

import global_defs::*;

module ao_multiply_tb
(
	input clk, 
	input rst_n
);
	initial $display("\n\tmultiply tb\n");

	import bit_width::*;
	
	bit [INWIDTH-1:0] A='0, B='0;
	bit [OUTWIDTH-1:0] Y;
	bit start=0, ready, ready_d;

	multiply #(INWIDTH) dut(.*);

	initial $monitor($time, "\tA: %d   B: %d   Y: %d", A, B, Y);

	always @(posedge clk)
		ready_d <= ready;

	always @(posedge ready) begin
		start = 0;
		A += 1;
		B += 2;
		start = 1;
	end

endmodule : ao_multiply_tb
