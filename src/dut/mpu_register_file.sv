// mpu_register_file.sv

import global_defs::*;

module mpu_register_file 
(
    // Control signals
    input clk,                                              // Clock
    input rst,                                              // Synchronous reset, active high
    input logic reg_load_en_in,                             // Matrix load request
    input logic reg_store_en_in,                            // Matrix store request

    // Load signals
    input logic [MATRIX_REG_SIZE-1:0] reg_load_addr_in,     // Matrix address to load into  
    input logic [FP-1:0] reg_load_element_in,               // Matrix input data
    input logic [MBITS:0] reg_i_load_loc_in,                // Matrix input row location
    input logic [NBITS:0] reg_j_load_loc_in,                // Matrix input column location
    input logic [MBITS:0] reg_m_load_size_in,               // Matrix input row size
    input logic [NBITS:0] reg_n_load_size_in,               // Matrix input column size

    // Store signals
    input logic [MATRIX_REG_SIZE-1:0] reg_store_addr_in,    // Matrix address to write out from
    input logic [MBITS:0] reg_i_store_loc_in,               // Matrix output row location
    input logic [NBITS:0] reg_j_store_loc_in,               // Matrix output column location
    output logic [MBITS:0] reg_m_store_size_out,            // Matrix output total rows
    output logic [NBITS:0] reg_n_store_size_out,            // Matrix output total columns
    output logic [FP-1:0] reg_store_element_out,            // Matrix output data
    output logic reg_store_complete_out                     // Signal for end of matrix output
);

    import mpu_pkg::*;

    logic [FP-1:0] matrix_register_array [MATRIX_REGISTERS][M][N];      // Matrix Registers
    logic [MBITS:0] size_m;                                             // Matrix total rows
    logic [NBITS:0] size_n;                                             // Matrix total columns

    // Load a matrix into a register from memory
    always_ff @(posedge clk) begin : matrix_load
        if (rst) begin
            size_m <= '0;
            size_n <= '0;
        end
        else if (reg_load_en_in) begin
            size_m <= reg_m_load_size_in;
            size_n <= reg_n_load_size_in;
            matrix_register_array[reg_load_addr_in][reg_i_load_loc_in][reg_j_load_loc_in] <= reg_load_element_in;
        end
    end : matrix_load

    // Store a vectorized matrix from a register out to memory
    always_ff @(posedge clk) begin : matrix_store
        if (rst) begin
            reg_store_element_out <= '0;
            reg_store_complete_out <= 0;
            reg_m_store_size_out <= '0;
            reg_n_store_size_out <= '0;
        end
        else if (reg_store_en_in) begin
            reg_store_complete_out <= 0;
            reg_m_store_size_out <= size_m;
            reg_n_store_size_out <= size_n;
            reg_store_element_out <= matrix_register_array[reg_store_addr_in][reg_i_store_loc_in][reg_j_store_loc_in];
            //if ((reg_i_store_loc_in == size_m) && (reg_j_store_loc_in == size_n)) begin
            //    reg_store_complete_out <= 1;
            //end
        end
    end : matrix_store

    // TODO: add error checking for matrix input location vs matrix size

endmodule : mpu_register_file