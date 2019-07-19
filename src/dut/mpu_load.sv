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
    input bit [FPBITS:0] mem_load_element_in,             // [32|64]-bit float, matrix element
    input bit [MBITS:0] mem_m_load_size_in,               // m-dimension of input matrix (rows)
    input bit [NBITS:0] mem_n_load_size_in,               // n-dimension of input matrix (columns)
    input bit [MATRIX_REG_BITS:0] mem_load_addr_in,       // Matrix address   
    output bit mem_load_error_out,                      // Error detection
    output bit mem_load_ack_out,                        // Receive data handshake signal

    // Output to register file
    output bit reg_load_en_out,                           // Matrix load request
    output bit [MATRIX_REG_BITS:0] reg_load_addr_out,     // Matrix address load location 
    output bit [FPBITS:0] reg_load_element_out,           // Matrix data
    output bit [MBITS:0] reg_i_load_loc_out,              // Matrix row location
    output bit [NBITS:0] reg_j_load_loc_out,              // Matrix column location
    output bit [MBITS:0] reg_m_load_size_out,             // Matrix row size
    output bit [NBITS:0] reg_n_load_size_out              // Matrix column size
);

    import mpu_pkg::*;

    bit [MBITS:0] row_ptr;
    bit [NBITS:0] col_ptr;
    bit load_finished;
    bit mem_size_error;
    bit row_end;
    bit col_end;

    load_state_t state=LOAD_IDLE, next_state;

    assign row_end = (row_ptr == (mem_m_load_size_in-1));
    assign col_end = (col_ptr == (mem_n_load_size_in-1));
    assign load_finished = row_end & col_end;
    assign mem_size_error = (mem_m_load_size_in > M || mem_n_load_size_in > N || !mem_m_load_size_in || !mem_n_load_size_in);
    assign mem_load_error_out = mem_size_error;
    assign reg_load_addr_out = mem_load_addr_in;
    assign reg_load_element_out = mem_load_element_in;

    // State machine driver
    always_ff @(posedge clk) begin : state_machine_driver
        state <= rst ? LOAD_IDLE : next_state;
    end : state_machine_driver

    // Register (i,j) incremental pointer counter
    always_ff @(posedge clk) begin : matix_indexing
        if (rst) begin
            row_ptr <= '0;
            col_ptr <= '0;
        end
        else begin
            unique case (state) 
                LOAD_IDLE: begin
                    row_ptr <= '0;
                    col_ptr <= '0;
                end
                LOAD_MATRIX: begin
                    if (load_finished) begin
                        row_ptr <= '0;
                        col_ptr <= '0;
                    end
                    else if (col_end) begin
                        row_ptr <= row_ptr + 1;
                        col_ptr <= '0;
                    end
                    else begin
                        row_ptr <= row_ptr;
                        col_ptr <= col_ptr + 1;
                    end
                end
            endcase       
        end
    end : matix_indexing


    // Next state logic
    always_comb begin : next_state_logic
        if (rst) begin
            next_state <= LOAD_IDLE;
        end
        else begin
            unique case (state)
                LOAD_IDLE: begin
                    if (load_en_in && !load_finished) begin
                        if (mem_size_error) begin
                            next_state <= LOAD_IDLE;
                        end
                        else begin
                            next_state <= LOAD_MATRIX;
                        end
                    end
                    else begin
                        next_state <= LOAD_IDLE;
                    end
                end
                LOAD_MATRIX: begin
                    if (!load_finished) begin
                        next_state <= LOAD_MATRIX;
                    end
                    else begin
                        next_state <= LOAD_IDLE;
                    end
                end
            endcase
        end
    end : next_state_logic


    always_comb begin : matrix_load_output
        if (rst) begin
            mem_load_ack_out <= 0;
            reg_load_en_out <= 0;      
            reg_i_load_loc_out <= '0;
            reg_j_load_loc_out <= '0;
            reg_m_load_size_out <= '0;
            reg_n_load_size_out <= '0;
        end
        else begin
            unique case (state)

                LOAD_IDLE: begin : load_idle
                    // Input ready
                    if (load_en_in && !load_finished) begin
                        // Check for dimension errors
                        if (mem_size_error) begin
                            mem_load_ack_out <= 0;
                            reg_load_en_out <= 0;           
                            reg_i_load_loc_out <= '0;
                            reg_j_load_loc_out <= '0;
                            reg_m_load_size_out <= '0;
                            reg_n_load_size_out <= '0;
                        end
                        // Start loading in the matrix on the next cycle
                        else begin               
                            mem_load_ack_out <= 1;
                            reg_load_en_out <= 1;
                            reg_i_load_loc_out <= row_ptr;
                            reg_j_load_loc_out <= col_ptr;
                            reg_m_load_size_out <= mem_m_load_size_in;
                            reg_n_load_size_out <= mem_n_load_size_in;
                        end
                    end
                    // Else, no load input enable signal
                    else begin
                        mem_load_ack_out <= 0;
                        reg_load_en_out <= 0;     
                        reg_i_load_loc_out <= '0;
                        reg_j_load_loc_out <= '0;
                        reg_m_load_size_out <= '0;
                        reg_n_load_size_out <= '0;
                    end
                end : load_idle

                LOAD_MATRIX: begin : load_matrix
                    // If currently in the process of loading a matrix
                    if (!load_finished) begin
                        mem_load_ack_out <= 1;
                        reg_load_en_out <= 1;
                        reg_i_load_loc_out <= row_ptr;
                        reg_j_load_loc_out <= col_ptr;                    
                        reg_m_load_size_out <= mem_m_load_size_in;
                        reg_n_load_size_out <= mem_n_load_size_in;
                    end

                    // Else, the matrix has finished loading
                    else begin
                        mem_load_ack_out <= 0;
                        reg_load_en_out <= 1;
                        reg_i_load_loc_out <= row_ptr;
                        reg_j_load_loc_out <= col_ptr;
                        reg_m_load_size_out <= mem_m_load_size_in;
                        reg_n_load_size_out <= mem_n_load_size_in;
                    end
                end
            
            endcase
        end
    end : matrix_load_output

endmodule : mpu_load
