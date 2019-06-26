// mpu_register_file.sv

import global_defs::*;

module mpu_register_file 
(
	input clk,
	input rst,

	input logic write_en,							// Matrix write request
	input logic [MATRIX_REG_SIZE-1:0] write_addr,	// Matrix address	
	input logic [FP-1:0] element,					// Matrix data
	input logic [MBITS:0] m,						// Matrix row location
	input logic [NBITS:0] n,						// Matrix column location

	input logic [MATRIX_REG_SIZE-1:0] matrix_addr,
	output logic [FP-1:0] matrix_out [M][N]
);

	logic [FP-1:0] matrix_register_array [MATRIX_REGISTERS][M][N];
	logic [MATRIX_REG_SIZE-1:0] matrix_index='0;

	always_ff @(posedge clk) begin

		// Reset clears all registers
		if (rst) begin
			//matrix_register_array <= '0; // please work
		end

		else if (write_en) begin
			matrix_register_array[write_addr][m][n] <= element;
		end

	end

	//assign matrix_out = matrix_addr ? matrix_register_array[matrix_addr] : '0;
	assign matrix_out = matrix_register_array[matrix_addr];

endmodule : mpu_register_file