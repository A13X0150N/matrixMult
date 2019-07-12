// mpu_store.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// register file --> external source
// Store a matrix from the register into an external memory source one floating
// point number at a time.

import global_defs::*;

module mpu_store
(
    // Control signals
    input clk,          // Clock
    input rst,          // Synchronous reset active high
    input store_en_in,  // Signal input data

    // To register file
    input logic [FPBITS:0] reg_store_element_in,            // [32|64]-bit float, matrix element
    input logic [MBITS:0] reg_m_store_size_in,              // Register matrix M total rows
    input logic [NBITS:0] reg_n_store_size_in,              // Register matrix N total columns
    output logic reg_store_en_out,                          // Store enable signal
    output logic [MBITS:0] reg_i_store_loc_out,             // Matrix row location
    output logic [NBITS:0] reg_j_store_loc_out,             // Matrix column location
    output logic [MATRIX_REG_BITS:0] reg_store_addr_out,    // Matrix address store location

    // To memory
    input logic [MATRIX_REG_BITS:0] mem_store_addr_in,      // Matrix address store location
    output logic mem_store_en_out,                          // Signal for store enable
    output logic [MBITS:0] mem_m_store_size_out,            // M total rows
    output logic [NBITS:0] mem_n_store_size_out,             // N total columns
    output logic [FPBITS:0] mem_store_element_out          // Matrix element output
);

    import mpu_pkg::*;

    logic [MBITS:0] row_ptr;
    logic [NBITS:0] col_ptr;
    logic store_finished;

    store_state_t state=STORE_IDLE, next_state;

    // State machine driver
    always_ff @(posedge clk) begin : state_machine_driver
        state <= rst ? STORE_IDLE : next_state;
    end : state_machine_driver

    // Register (i,j) incremental pointer driver
    always_ff @(posedge clk) begin
        if (rst) begin
            row_ptr <= '0;
            col_ptr <= '0;
        end
        else begin
            // Logic to clear row and column index pointers 
            if (store_finished) begin    
                row_ptr <= '0;
                col_ptr <= '0;
            end  
            // Row and column pointers must be incremented here for clock synchronization
            else if (!store_finished && store_en_in) begin
                col_ptr <= col_ptr + 1;
                if (col_ptr == mem_n_store_size_out-1) begin
                    col_ptr <= '0;
                    row_ptr <= row_ptr + 1;
                end
            end          
        end
    end

    // Matrix register output
    always_comb begin : matrix_store
        if (rst) begin
            next_state = STORE_IDLE;
            reg_store_en_out = 0;
            reg_i_store_loc_out = '0;
            reg_j_store_loc_out = '0;
            reg_store_addr_out = '0;
            mem_store_en_out = 0;
            mem_m_store_size_out = '0;
            mem_n_store_size_out = '0;
            mem_store_element_out = '0;
            store_finished = 0;            
        end
        else begin
            unique case (state)
                
                STORE_IDLE: begin : store_idle
                    if (store_en_in && !store_finished) begin
                        next_state = STORE_MATRIX;
                        reg_store_en_out = 1;
                        reg_i_store_loc_out = row_ptr;
                        reg_j_store_loc_out = col_ptr;
                        reg_store_addr_out = mem_store_addr_in;
                        mem_store_en_out = 1;
                        mem_m_store_size_out = reg_m_store_size_in;
                        mem_n_store_size_out = reg_n_store_size_in;
                        mem_store_element_out = reg_store_element_in;
                        store_finished = 0;
                    end
                    else begin
                        next_state = STORE_IDLE;
                        reg_store_en_out = 0;
                        reg_i_store_loc_out = '0;
                        reg_j_store_loc_out = '0;
                        reg_store_addr_out = '0;
                        mem_store_en_out = 0;
                        mem_m_store_size_out = '0;
                        mem_n_store_size_out = '0;
                        mem_store_element_out = '0;
                        store_finished = 0;
                    end
                end : store_idle

                STORE_MATRIX: begin : store_matrix
                    // Next state logic
                    if (!store_finished) begin
                        next_state = STORE_MATRIX;
                        reg_store_en_out = 1;
                        reg_i_store_loc_out = row_ptr;
                        reg_j_store_loc_out = col_ptr;
                        reg_store_addr_out = mem_store_addr_in;
                        mem_store_en_out = 1;
                        mem_m_store_size_out = reg_m_store_size_in;
                        mem_n_store_size_out = reg_n_store_size_in;
                        mem_store_element_out = reg_store_element_in;
                       
                        // If finished storing data
                        if ((row_ptr == reg_m_store_size_in-1) && (col_ptr == reg_n_store_size_in-1)) begin
                            store_finished = 1;
                        end
                        else begin
                            store_finished = 0;
                        end

                    end
                    else begin
                        next_state = STORE_IDLE;
                        reg_store_en_out = 0;
                        reg_i_store_loc_out = reg_m_store_size_in-1;
                        reg_j_store_loc_out = reg_n_store_size_in-1;
                        reg_store_addr_out = mem_store_addr_in;
                        mem_store_en_out = 0;
                        mem_m_store_size_out = reg_m_store_size_in;
                        mem_n_store_size_out = reg_n_store_size_in;
                        mem_store_element_out = reg_store_element_in;
                        store_finished = 1;
                    end
                end : store_matrix

            endcase
        end
    end : matrix_store

endmodule : mpu_store
