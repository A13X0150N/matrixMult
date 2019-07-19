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
    input  bit [FPBITS:0] reg_store_element_in,            // [32|64]-bit float, matrix element
    input  bit [MBITS:0] reg_m_store_size_in,              // Register matrix M total rows
    input  bit [NBITS:0] reg_n_store_size_in,              // Register matrix N total columns
    output bit reg_store_en_out,                           // Store enable signal
    output bit [MBITS:0] reg_i_store_loc_out,              // Matrix row location
    output bit [NBITS:0] reg_j_store_loc_out,              // Matrix column location
    output bit [MATRIX_REG_BITS:0] reg_store_addr_out,     // Matrix address store location

    // To memory
    input  bit [MATRIX_REG_BITS:0] mem_store_addr_in,      // Matrix address store location
    output bit mem_store_en_out,                           // Signal for store enable
    output bit [MBITS:0] mem_m_store_size_out,             // M total rows
    output bit [NBITS:0] mem_n_store_size_out,             // N total columns
    output bit [FPBITS:0] mem_store_element_out            // Matrix element output
);

    import mpu_pkg::*;

    bit [MBITS:0] row_ptr;
    bit [NBITS:0] col_ptr;
    bit store_finished;
    bit row_end;
    bit col_end;

    store_state_t state=STORE_IDLE, next_state;

    assign row_end = (row_ptr == (reg_m_store_size_in-1));
    assign col_end = (col_ptr == (reg_n_store_size_in-1));
    assign store_finished = row_end & col_end;
    assign reg_store_addr_out = mem_store_addr_in;
    assign mem_store_element_out = reg_store_element_in;
    assign mem_m_store_size_out = reg_m_store_size_in;
    assign mem_n_store_size_out = reg_n_store_size_in;
    assign reg_i_store_loc_out = row_ptr;
    assign reg_j_store_loc_out = col_ptr;


    // State machine driver
    always_ff @(posedge clk) begin : state_machine_driver
        state <= rst ? STORE_IDLE : next_state;
    end : state_machine_driver


    // Register (i,j) incremental pointer counter
    always_ff @(posedge clk) begin : matix_indexing
        if (rst) begin
            row_ptr <= '0;
            col_ptr <= '0;
        end
        else begin
            unique case (state) 
                STORE_IDLE: begin
                    row_ptr <= '0;
                    col_ptr <= '0;
                end
                STORE_MATRIX: begin
                    if (store_finished) begin
                        row_ptr <= row_ptr;
                        col_ptr <= col_ptr;
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
            next_state <= STORE_IDLE;
        end
        else begin
            unique case (state)
                STORE_IDLE: begin
                    if (store_en_in && !store_finished) begin
                        next_state <= STORE_MATRIX;
                    end
                    else begin
                        next_state <= STORE_IDLE;
                    end
                end
                STORE_MATRIX: begin
                    if (!store_finished) begin
                        next_state <= STORE_MATRIX;
                    end
                    else begin
                        next_state <= STORE_IDLE;
                    end
                end
            endcase
        end
    end : next_state_logic


    // Matrix register enable output
    always_comb begin
        if (rst) begin
            reg_store_en_out <= 0;
            mem_store_en_out <= 0;
        end
        else begin
            unique case (state)
                STORE_IDLE: begin
                    reg_store_en_out <= 0;
                    mem_store_en_out <= 0;
                end
                STORE_MATRIX: begin
                    reg_store_en_out <= 1;
                    mem_store_en_out <= 1;
                end
            endcase
        end
    end

endmodule : mpu_store
