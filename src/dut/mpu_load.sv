// mpu_load.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// external source --> register file
// Load a matrix from an external memory source into the registers one floating
// point number at a time.

import global_defs::*;

module mpu_load 
(   
    // Control signals
    input clk,              // Clock
    input rst,              // Synchronous reset active high
    input load_en_in,       // Signal input data

    // Input matrix from file or memory
    input logic [FPBITS:0] mem_load_element_in,             // [32|64]-bit float, matrix element
    input logic [MBITS:0] mem_m_load_size_in,               // m-dimension of input matrix (rows)
    input logic [NBITS:0] mem_n_load_size_in,               // n-dimension of input matrix (columns)
    input logic [MATRIX_REG_BITS:0] mem_load_addr_in,       // Matrix address   
    output logic mem_load_error_out=0,                      // Error detection
    output logic mem_load_ack_out=0,                        // Receive data handshake signal

    // Output to register file
    output logic reg_load_en_out,                           // Matrix load request
    output logic [MATRIX_REG_BITS:0] reg_load_addr_out,     // Matrix address load location 
    output logic [FPBITS:0] reg_load_element_out,           // Matrix data
    output logic [MBITS:0] reg_i_load_loc_out,              // Matrix row location
    output logic [NBITS:0] reg_j_load_loc_out,              // Matrix column location
    output logic [MBITS:0] reg_m_load_size_out,             // Matrix row size
    output logic [NBITS:0] reg_n_load_size_out              // Matrix column size
);

    import mpu_pkg::*;

    logic [MBITS:0] row_ptr='x;
    logic [NBITS:0] col_ptr='x;

    load_state_t state=LOAD_IDLE, next_state=LOAD_IDLE;

    // State machine driver
    always_ff @(posedge clk) begin
        state <= rst ? LOAD_IDLE : next_state;
    end

    always_comb begin : matrix_load
        unique case (state)

            LOAD_IDLE: begin : load_idle
                next_state = LOAD_IDLE;
                mem_load_ack_out = 0;
                reg_m_load_size_out = '0;
                reg_n_load_size_out = '0;
                reg_load_addr_out = 'x;
                reg_load_en_out = 0;
                reg_i_load_loc_out = 0;
                reg_j_load_loc_out = 0;
                reg_load_element_out = 'x;
                mem_load_error_out = rst ? 0 : mem_load_error_out;

                // Input ready
                if (load_en_in) begin

                    // Check for dimension errors
                    if (mem_m_load_size_in > M || mem_n_load_size_in > N || !mem_m_load_size_in || !mem_n_load_size_in) begin
                        mem_load_error_out = 1;
                    end

                    // Start loading in the matrix on the next cycle
                    else begin
                        row_ptr = '0;
                        col_ptr = '0;                        
                        mem_load_ack_out = 1;
                        mem_load_error_out = 0;
                        reg_m_load_size_out = mem_m_load_size_in;
                        reg_n_load_size_out = mem_n_load_size_in;
                        reg_load_addr_out = mem_load_addr_in;
                        next_state = LOAD_MATRIX;
                    end
                end
            end : load_idle

            LOAD_MATRIX: begin : load_matrix
                if (mem_load_ack_out) begin
                    next_state = LOAD_MATRIX;
                    reg_load_en_out = 1;
                    reg_i_load_loc_out = row_ptr;
                    reg_j_load_loc_out = col_ptr;                    
                    reg_load_element_out = mem_load_element_in;

                    // Tranverse matrix pointers
                    ++col_ptr;
                    if (col_ptr == reg_n_load_size_out) begin
                        col_ptr = '0;
                        ++row_ptr;
                    end

                    // If finished loading data
                    if ((row_ptr == reg_m_load_size_out) && !col_ptr) begin
                        mem_load_ack_out = 0;
                    end
                end
                else begin
                    next_state = LOAD_IDLE;
                end
            end : load_matrix
        
        endcase
    end : matrix_load

endmodule : mpu_load
