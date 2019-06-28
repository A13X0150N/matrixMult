// mpu_load.sv
// external source --> register file

import global_defs::*;

module mpu_load 
(	
	// Control signals
	input clk,    		// Clock
	input rst,    		// Synchronous reset active high
	input en,			// Signal input data

	// Input matrix from file or memory
	input logic [FP-1:0] element,						// [32|64]-bit float, matrix element
	input logic [MBITS:0] matrix_m_size,				// m-dimension of input matrix
	input logic [NBITS:0] matrix_n_size,				// n-dimension of input matrix
	input logic [MATRIX_REG_SIZE-1:0] load_addr,		// Matrix address	
	output logic error=0,								// Error detection
	output logic ack=0,									// Receive data handshake signal

	// Output to register file
	output logic reg_load_en,							// Matrix load request
	output logic [MATRIX_REG_SIZE-1:0] reg_load_addr,	// Matrix address load location	
	output logic [FP-1:0] reg_element_out,				// Matrix data
	output logic [MBITS:0] reg_m_out, reg_m_size		// Matrix row location and size
	output logic [NBITS:0] reg_n_out, reg_n_size		// Matrix column location and size
);

	import mpu_pkg::*;

	logic [MBITS:0] m_size='0, row_ptr='x;
	logic [NBITS:0] n_size='0, col_ptr='x;

	load_state_t state=LOAD_IDLE, next_state=LOAD_IDLE;

	always_ff @(posedge clk) begin
		state <= rst ? LOAD_IDLE : next_state;
	end

	always_comb begin
		unique case (state)
			LOAD_IDLE: begin
				next_state = LOAD_IDLE;
				ack = 0;
				m_size = '0;
				n_size = '0;
				reg_load_addr = 'x;
				reg_load_en = 0;
				reg_m_out = 0;
				reg_n_out = 0;
				reg_element_out = 'x;

				// Input ready
				if (en) begin

					// Check for dimension errors
					if (matrix_m_size > M || matrix_n_size > N || !matrix_m_size || !matrix_n_size) begin
						error = 1;
					end

					// Start loading in the matrix on the next cycle
					else begin
						ack = 1;
						error = 0;
						row_ptr = '0;
						col_ptr = '0;
						m_size = matrix_m_size;
						n_size = matrix_n_size;
						reg_load_addr = load_addr;
						next_state = LOAD_MATRIX;
					end
				end
			end

			LOAD_MATRIX: begin
				if (ack) begin
					next_state = LOAD_MATRIX;
					reg_load_en = 1;
					reg_element_out = element;

					reg_m_out = row_ptr;
					reg_n_out = col_ptr;

					++col_ptr;
					if (col_ptr == n_size) begin
						col_ptr = '0;
						++row_ptr;
					end

					// If finished loading data
					if ((row_ptr == m_size) && !col_ptr) begin
						ack = 0;
					end
				end
				else begin
					next_state = LOAD_IDLE;
				end
			end

	 	endcase
	end


endmodule : mpu_load
