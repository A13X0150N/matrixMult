// mpu_register_file.sv

import global_defs::*;

module mpu_register_file 
(
	input clk,
	input rst,

	input logic write_en,								// Matrix write request
	input logic [MATRIX_REG_SIZE-1:0] reg_load_addr,	// Matrix address to load into	
	input logic [FP-1:0] element,						// Matrix data
	input logic [MBITS:0] m,							// Matrix row location
	input logic [NBITS:0] n,							// Matrix column location

	input logic [MATRIX_REG_SIZE-1:0] reg_store_addr,	// Matrix address to write out from
	output logic [FP-1:0] matrix_out  [M][N]			// Matrix output data
	//output logic read_stb,
);

	logic [FP-1:0] matrix_register_array [MATRIX_REGISTERS][M][N];
	logic [MATRIX_REG_SIZE-1:0] matrix_index='0;

	// Load matrix into a register
	always_ff @(posedge clk) begin : matrix_load
		if (write_en) begin
			matrix_register_array[reg_load_addr][m][n] <= element;
		end
	end : matrix_load

	//assign matrix_out = read_addr ? matrix_register_array[read_addr] : '0;
	assign matrix_out = matrix_register_array[reg_store_addr];

	// Matrix register output
	//always_ff @(posedge clk) begin : matrix_store



	//end : matrix_store

endmodule : mpu_register_file