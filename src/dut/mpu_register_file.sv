// mpu_register_file.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// An array of MxN registers that can be either for calculation. Must be loaded
// from memory. Matrices may also be stored out to memory from the registers.
// I/O is currently performed with a single floating point number at a time.
// The registers are designed to be load/store dual-ported.

import global_defs::*;

module mpu_register_file 
(
    // Control signals
    input clk,              // Clock
    input rst,              // Synchronous reset, active high
    input reg_load_en_in,   // Matrix load request
    input reg_store_en_in,  // Matrix store request

    // Load signals
    input  bit [MATRIX_REG_BITS:0] reg_load_addr_in,       // Matrix address to load into  
    input  bit [MBITS:0] reg_i_load_loc_in,                // Matrix input row location
    input  bit [NBITS:0] reg_j_load_loc_in,                // Matrix input column location
    input  bit [MBITS:0] reg_m_load_size_in,               // Matrix input row size
    input  bit [NBITS:0] reg_n_load_size_in,               // Matrix input column size
    input  bit [FPBITS:0] reg_load_element_in,             // Matrix input data

    // Store signals
    input  bit [MATRIX_REG_BITS:0] reg_store_addr_in,      // Matrix address to write out from
    input  bit [MBITS:0] reg_i_store_loc_in,               // Matrix output row location
    input  bit [NBITS:0] reg_j_store_loc_in,               // Matrix output column location
    output bit [MBITS:0] reg_m_store_size_out,             // Matrix output total rows
    output bit [NBITS:0] reg_n_store_size_out,             // Matrix output total columns
    output bit [FPBITS:0] reg_store_element_out            // Matrix output data
);

    import mpu_pkg::*;

    bit [FPBITS:0] matrix_register_array [MATRIX_REGISTERS][M][N];    // Matrix Registers
    bit [MBITS:0] size_m;                                             // Matrix total rows
    bit [NBITS:0] size_n;                                             // Matrix total columns

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
        if (reg_store_en_in) begin
            reg_m_store_size_out <= size_m;
            reg_n_store_size_out <= size_n;
            reg_store_element_out <= matrix_register_array[reg_store_addr_in][reg_i_store_loc_in][reg_j_store_loc_in];    
        end
    end : matrix_store

endmodule : mpu_register_file
