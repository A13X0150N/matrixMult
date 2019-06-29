// mpu_store.sv
// register file --> external source

import global_defs::*;

module mpu_store
(
    // Control signals
    input clk,          // Clock
    input rst,          // Synchronous reset active high
    input store_en_in,  // Signal input data

    // To register file
    input logic [FP-1:0] reg_element_in,                    // [32|64]-bit float, matrix element
    input logic reg_store_complete_in,                      // Signal for end of matrix transfer
    input logic [MBITS:0] reg_m_store_size_in,              // Register matrix M total rows
    input logic [NBITS:0] reg_n_store_size_in,              // Register matrix N total columns
    output logic reg_store_en_out,                          // Store enable signal
    output logic [MBITS:0] reg_i_store_loc_out,             // Matrix row location
    output logic [NBITS:0] reg_j_store_loc_out,             // Matrix column location
    output logic [MATRIX_REG_SIZE-1:0] reg_store_addr_out,  // Matrix address store location

    // Output to file or memory
    output logic mem_store_en_out,                          // Signal for store enable
    output logic [FP-1:0] mem_store_element_out,            // Matrix element output
    output logic [MBITS:0] mem_m_store_size_out,            // M total rows
    output logic [NBITS:0] mem_n_store_size_out             // N total columns
);

    import mpu_pkg::*;

    logic [MBITS:0] row_ptr='x;
    logic [NBITS:0] col_ptr='x;

    store_state_t state=STORE_IDLE, next_state=STORE_IDLE;

    // State machine driver
    always_ff @(posedge clk) begin
        state <= rst ? STORE_IDLE : next_state;
    end

    // Matrix register output
    always_comb begin : matrix_store
        case (state)

            STORE_IDLE: begin : store_idle
                if (store_en_in) begin
                    next_state = STORE_MATRIX;
                    mem_m_store_size_out = reg_m_store_size_in;
                    mem_n_store_size_out = reg_n_store_size_in;
                    reg_i_store_loc_out = '0;
                    reg_j_store_loc_out = '0;
                    reg_store_en_out = 1;
                    mem_store_en_out = 1;
                    row_ptr = '0;
                    col_ptr = '0;
                end
                else begin
                    next_state = STORE_IDLE;
                    mem_m_store_size_out = '0;
                    mem_n_store_size_out = '0;
                    reg_i_store_loc_out = '0;
                    reg_j_store_loc_out = '0;
                    reg_store_en_out = 0;
                    mem_store_en_out = 0;
                    row_ptr = '0;
                    col_ptr = '0;
                end
            end : store_idle

            STORE_MATRIX: begin : store_matrix     // TODO
                // Next state logic
                if (reg_store_complete_in) begin  // posibly change to if(mem_store_en_out) if problems
                    next_state = STORE_IDLE;
                    mem_store_en_out = 0;
                    reg_store_en_out = 0;
                end
                else begin
                    next_state = STORE_MATRIX;
                    mem_store_en_out = 1;
                    reg_store_en_out = 1;
                    reg_i_store_loc_out = row_ptr;
                    reg_j_store_loc_out = col_ptr;
                    mem_store_element_out = reg_element_in;

                    // Traverse matrix pointers
                    ++col_ptr;
                    if (col_ptr == mem_n_store_size_out) begin
                        col_ptr = '0;
                        ++row_ptr;
                    end
                    // If finished storing data
                    if ((row_ptr == mem_m_store_size_out) && !col_ptr) begin
                        $display("!!!store check");
                        mem_store_en_out = 0;
                    end
                end
            end : store_matrix

        endcase
    end : matrix_store

endmodule : mpu_store
