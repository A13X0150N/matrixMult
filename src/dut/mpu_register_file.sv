// mpu_register_file.sv

import global_defs::*;

module mpu_register_file 
(
	// Control signals
	input clk,
	input rst,
	input logic reg_load_en,							// Matrix load request
	input logic reg_store_en,							// Matrix store request

	// Load signals
	input logic [MATRIX_REG_SIZE-1:0] reg_load_addr,	// Matrix address to load into	
	input logic [FP-1:0] reg_element_in,				// Matrix input data
	input logic [MBITS:0] reg_m_load_loc,				// Matrix input row location
	input logic [NBITS:0] reg_n_load_loc,				// Matrix input column location
	input logic [MBITS:0] reg_m_size,					// Matrix input row size
	input logic [NBITS:0] reg_n_size,					// Matrix input column size

	// Store signals
	input logic [MATRIX_REG_SIZE-1:0] reg_store_addr,	// Matrix address to write out from
	input logic [MBITS:0] reg_m_store_loc,				// Matrix output row location
	input logic [NBITS:0] reg_n_store_loc,				// Matrix output column location
	output logic [FP-1:0] reg_element_out,				// Matrix output data
	output logic reg_store_complete						// Signal for end of matrix output
);

	import mpu_pkg::*;

	logic [FP-1:0] matrix_register_array [MATRIX_REGISTERS][M][N];
	logic [MBITS:0] size_m;
	logic [NBITS:0] size_n;

	// Load a matrix into a register
	always_ff @(posedge clk) begin : matrix_load
		if (rst) begin
			size_m <= '0;
			size_n <= '0;
		end
		else if (reg_load_en) begin
			size_m <= reg_m_size;
			size_n <= reg_n_size;
			matrix_register_array[reg_load_addr][reg_m_load_loc][reg_n_load_loc] <= reg_element_in;
		end
	end : matrix_load


	// Store a vectorized matrix from a register
	always_ff @(posedge clk) begin : matrix_store
		if (rst) begin
			reg_element_out <= '0;
			reg_store_complete <= 0;
		end
		else if (reg_store_en) begin
			reg_store_complete <= 0;
			reg_element_out <= matrix_register_array[reg_store_addr][reg_m_store_loc][reg_n_store_loc]
			if ((reg_m_store_loc == size_m) && (reg_n_store_loc == size_n)) begin
				reg_store_complete <= 1;
			end
		end
	end : matrix_store


endmodule : mpu_register_file