// multiply.sv

import mm_pkg::*;

module multiply
( 
	input logic [3:0] A, B,
	output logic [7:0] Y
);
	initial $display("Multiply");

	assign Y = A * B;

endmodule : multiply
