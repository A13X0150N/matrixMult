// multiply_tb.sv

//`include "mm_pkg.sv"
import mm_pkg::*;

module multiply_tb
(
	input clk, 
	input rst_n
);
	initial $display("\n\tmultiply tb\n");
	
	logic [3:0] A, B;
	logic [7:0] Y;

	multiply dut(.*);

	initial $monitor("A: %d   B: %d   Y: %d", A, B, Y);

endmodule : multiply_tb
