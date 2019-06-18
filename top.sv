// top.sv

//`include "mm_pkg.sv"
import mm_pkg::*;

module top;
	initial $display("\n\tTop module\n");
	initial #10000 $stop;

	bit clk = 0;
	bit rst_n = 1;

	always #5 clk = ~clk;

	multiply_tb test(clk, rst_n);
	
	final $display("\n\tEnd of test\n\n");

endmodule : top

