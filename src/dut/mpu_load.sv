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
    output logic mem_load_error_out,                      // Error detection
    output logic mem_load_ack_out,                        // Receive data handshake signal

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

    logic [MBITS:0] row_ptr;
    logic [NBITS:0] col_ptr;
    logic load_finished;

    load_state_t state=LOAD_IDLE, next_state;

    // State machine driver
    always_ff @(posedge clk) begin : state_machine_driver
        state <= rst ? LOAD_IDLE : next_state;
    end : state_machine_driver

    // Register (i,j) incremental pointer driver
    always_ff @(posedge clk) begin
        if (rst) begin
            row_ptr <= '0;
            col_ptr <= '0;
        end
        else begin
            // Logic to clear row and column index pointers 
            if (load_finished) begin    
                row_ptr <= '0;
                col_ptr <= '0;
            end  

            // Row and column pointers must be incremented here for clock synchronization
            else if (!load_finished && load_en_in) begin
                col_ptr <= col_ptr + 1;
                if (col_ptr == reg_n_load_size_out-1) begin
                    col_ptr <= '0;
                    row_ptr <= row_ptr + 1;
                end
            end          
        end
    end


    always_comb begin : matrix_load
        if (rst) begin
            next_state = LOAD_IDLE;
            mem_load_error_out = 0;
            mem_load_ack_out = 0;
            reg_load_en_out = 0;            
            reg_i_load_loc_out = '0;
            reg_j_load_loc_out = '0;
            reg_m_load_size_out = '0;
            reg_n_load_size_out = '0;
            load_finished = 0;
        end
        else begin
            unique case (state)

                LOAD_IDLE: begin : load_idle
                    // Input ready
                    if (load_en_in && !load_finished) begin
                        // Check for dimension errors
                        if (mem_m_load_size_in > M || mem_n_load_size_in > N || !mem_m_load_size_in || !mem_n_load_size_in) begin
                            next_state = LOAD_IDLE;
                            mem_load_error_out = 1;
                            mem_load_ack_out = 0;
                            reg_load_en_out = 0;
                            reg_load_addr_out = '0;
                            reg_load_element_out = '0;             
                            reg_i_load_loc_out = '0;
                            reg_j_load_loc_out = '0;
                            reg_m_load_size_out = '0;
                            reg_n_load_size_out = '0;
                            load_finished = 0;
                        end
                        // Start loading in the matrix on the next cycle
                        else begin
                            next_state = LOAD_MATRIX;
                            mem_load_error_out = 0;                            
                            mem_load_ack_out = 1;
                            reg_load_en_out = 1;
                            reg_load_addr_out = mem_load_addr_in;
                            reg_load_element_out = mem_load_element_in; 
                            reg_i_load_loc_out = row_ptr;
                            reg_j_load_loc_out = col_ptr;
                            reg_m_load_size_out = mem_m_load_size_in;
                            reg_n_load_size_out = mem_n_load_size_in;
                            load_finished = 0;
                        end
                    end
                    // Else, no load input enable signal
                    else begin
                        next_state = LOAD_IDLE;
                        mem_load_error_out = 0;
                        mem_load_ack_out = 0;
                        reg_load_en_out = 0;
                        reg_load_addr_out = '0;
                        reg_load_element_out = '0;         
                        reg_i_load_loc_out = '0;
                        reg_j_load_loc_out = '0;
                        reg_m_load_size_out = '0;
                        reg_n_load_size_out = '0;
                        load_finished = 0;
                    end
                end : load_idle

                LOAD_MATRIX: begin : load_matrix
                    // If currently in the process of loading a matrix
                    if (!load_finished) begin
                        next_state = LOAD_MATRIX;
                        mem_load_error_out = 0;
                        mem_load_ack_out = 1;
                        reg_load_en_out = 1;
                        reg_load_addr_out = mem_load_addr_in;
                        reg_load_element_out = mem_load_element_in; 
                        reg_i_load_loc_out = row_ptr;
                        reg_j_load_loc_out = col_ptr;                    
                        reg_m_load_size_out = mem_m_load_size_in;
                        reg_n_load_size_out = mem_n_load_size_in;

                        // If finished loading data
                        if ((row_ptr == mem_m_load_size_in-1) && (col_ptr == mem_n_load_size_in-1)) begin
                            load_finished = 1;
                        end
                        // Else, keep loading data
                        else begin
                            load_finished = 0;
                        end
                    end

                    // Else, the matrix has finished loading
                    else begin
                        next_state = LOAD_IDLE;
                        mem_load_error_out = 0;
                        mem_load_ack_out = 0;
                        reg_load_en_out = 0;
                        reg_load_addr_out = mem_load_addr_in;
                        reg_load_element_out = mem_load_element_in;           
                        reg_i_load_loc_out = mem_m_load_size_in-1;
                        reg_j_load_loc_out = mem_n_load_size_in-1;
                        reg_m_load_size_out = mem_m_load_size_in;
                        reg_n_load_size_out = mem_n_load_size_in;
                        load_finished = 1;
                    end
                end : load_matrix
            
            endcase
        end
    end : matrix_load

endmodule : mpu_load
