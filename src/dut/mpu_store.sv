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
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;

module mpu_store
(
    // Control signals
    input       clk,                                        // Clock
    input       rst,                                        // Synchronous reset active high
    input   bit store_req_in,                               // Signal input data

    // To register file
    input  bit store_ready_in,                              // Matrix store ready signal
    input  float_sp reg_store_element_in,                   // Incoming float, matrix element
    input  bit [MBITS:0] reg_m_store_size_in,               // Register matrix M total rows
    input  bit [NBITS:0] reg_n_store_size_in,               // Register matrix N total columns
    output bit reg_store_req_out,                           // Store request signal
    output bit [MBITS:0] reg_i_store_loc_out,               // Matrix row location
    output bit [NBITS:0] reg_j_store_loc_out,               // Matrix column location
    output bit [MATRIX_REG_BITS:0] reg_store_addr_out,      // Matrix address store location

    // To memory
    input  bit [MATRIX_REG_BITS:0] mem_store_addr_in,       // Matrix address store location
    output bit mem_store_en_out,                            // Signal for store enable
    output bit [MBITS:0] mem_m_store_size_out,              // M total rows
    output bit [NBITS:0] mem_n_store_size_out,              // N total columns
    output float_sp mem_store_element_out                   // Matrix element output
);

    bit [MBITS:0] row_ptr;                                  // Row location pointer
    bit [NBITS:0] col_ptr;                                  // Column location pointer
    bit store_finished;                                     // Store finished signal
    bit row_end;                                            // End of row signal
    bit col_end;                                            // End of column signal

    store_state_e state, next_state;                        // Store states

    // Matrix address and element
    assign reg_store_addr_out = mem_store_addr_in;
    assign mem_store_element_out = reg_store_element_in;

    // Size and location pointers
    assign mem_m_store_size_out = reg_m_store_size_in;
    assign mem_n_store_size_out = reg_n_store_size_in;
    assign reg_i_store_loc_out = row_ptr;
    assign reg_j_store_loc_out = col_ptr;

    // End of transfer logic
    assign row_end = (row_ptr == (reg_m_store_size_in));
    assign col_end = (col_ptr == (reg_n_store_size_in-1));
    assign store_finished = row_end & col_end;

    // State machine driver
    always_ff @(posedge clk) begin : state_machine_driver
        state <= rst ? STORE_IDLE : next_state;
    end : state_machine_driver

    // Register (i,j) incremental pointer counter
    always_ff @(posedge clk) begin : matrix_indexing
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
                STORE_REQUEST: begin
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
    end : matrix_indexing

    // Next state logic
    always_comb begin : next_state_logic
        if (rst) begin
            next_state <= STORE_IDLE;
        end
        else begin
            unique case (state)
                STORE_IDLE: begin
                    if (store_req_in) begin
                        next_state <= STORE_REQUEST;
                    end
                    else begin
                        next_state <= STORE_IDLE;
                    end
                end
                STORE_REQUEST: begin
                    if (store_ready_in) begin
                        next_state <= STORE_MATRIX;
                    end
                    else begin
                        next_state <= STORE_REQUEST;
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
    always_comb begin : matrix_store_output
        if (rst) begin
            reg_store_req_out <= FALSE;
            mem_store_en_out <= FALSE;
        end
        else begin
            unique case (state)
                STORE_IDLE: begin
                    reg_store_req_out <= FALSE;
                    mem_store_en_out <= FALSE;
                end
                STORE_REQUEST: begin
                    reg_store_req_out <= FALSE;
                    mem_store_en_out <= FALSE;
                end
                STORE_MATRIX: begin
                    if (!store_finished) begin
                        reg_store_req_out <= TRUE;
                        mem_store_en_out <= TRUE;
                    end
                    else begin
                        reg_store_req_out <= FALSE;
                        mem_store_en_out <= FALSE;
                    end
                end
            endcase
        end
    end : matrix_store_output

endmodule : mpu_store
