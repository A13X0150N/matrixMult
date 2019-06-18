// multiply.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// HDL to multiply two binary numbers. Output double the length of the input.

import mm_defs::*;

module multiply
#(
	parameter INPUTSIZE = 16,					// Maximum input size for binary multiplication
	localparam INWIDTH = $clog2(INPUTSIZE),		// Input width that captures the input size
	localparam OUTWIDTH = INWIDTH * 2			// The output has double the width of the input
)
( 
	input logic [INWIDTH-1:0] A, B,
	output logic [OUTWIDTH-1:0] Y
);
	initial $display("Multiply");

	if (MULT_SIMULATION) begin
		initial $display("Multiplication method: Simulation");		
		assign Y = A * B;
	end

endmodule : multiply
