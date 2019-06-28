// mpu_store.sv
// register file --> external source

import global_defs::*;

module mpu_store
(
	// Control signals
	input clk,    		// Clock
	input rst,    		// Synchronous reset active high
	input en,			// Signal input data

	// Input from register file
	input logic [FP-1:0] reg_element_out,				// [32|64]-bit float, matrix element
	input logic [MBITS:0] reg_m_store_loc,				// Matrix row location
	input logic [NBITS:0] reg_n_store_loc,				// Matrix column location
	input logic reg_store_complete,						// Signal for end of matrix transfer
	output logic reg_store_en,							// Signal for store enable

	// Output to file or memory
	output logic [FP-1:0] element_out 					// Matrix element output
);

	import mpu_pkg::*;

	logic [MBITS:0] m_size='0, row_ptr='x;
	logic [NBITS:0] n_size='0, col_ptr='x;

	store_state_t state=STORE_IDLE, next_state=STORE_IDLE;

	// State machine driver
	always_ff @(posedge clk) begin
		state <= rst ? STORE_IDLE : next_state;
	end

	// Matrix register output
	always_comb begin : matrix_store
		case (state)
			STORE_IDLE: begin
				if (en) begin
					next_state = STORE_MATRIX;
					reg_m_out = '0;
					reg_n_out = '0;
					reg_store_en = 1;
				end
				else begin
					next_state = STORE_IDLE;
					reg_store_en = 0;
				end
			end

			STORE_MATRIX: begin 	// TODO
				// Next state logic
				if (reg_store_complete) begin
					next_state = STORE_IDLE;
					reg_store_en = 0;
				end
				else begin
					next_state = STORE_MATRIX;
					reg_store_en = 1;
				end
			end
		endcase
	end : matrix_store


endmodule : mpu_store
