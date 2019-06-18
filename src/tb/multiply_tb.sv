// multiply_tb.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// Simple testbench for binary multiplier. Eventually migrate to UVM.

import mm_defs::*;

module multiply_tb
(
	input clk, 
	input rst_n
);
	initial $display("\n\tmultiply tb\n");

	import bit_width::*;
	
	logic [INWIDTH-1:0] A, B;
	logic [OUTWIDTH-1:0] Y;

	multiply #(INPUTSIZE) dut(.*);

	initial $monitor("A: %d   B: %d   Y: %d", A, B, Y);

	always_ff @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			A = '0;
			B = '0;
		end
		else begin
			A += 1;
			B += 2;
		end
	end

endmodule : multiply_tb
