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
import mpu_data_types::*;

module mpu_register_file 
(
    // Control signals
    input clk,                  // Clock
    input rst,                  // Synchronous reset, active high
    input reg_load_en_in,       // Matrix load request
    input reg_store_en_in,      // Matrix store request
    output bit load_ready_out,  // Matrix load ready signal
    output bit store_ready_out, // Matrix store ready signal

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

    float_sp matrix_register_array [MATRIX_REGISTERS][M][N];    // Matrix Registers
    bit [MBITS:0] size_m;                                       // Matrix total rows
    bit [NBITS:0] size_n;                                       // Matrix total columns

    bit [MATRIX_REGISTERS-1:0] currently_reading;               // One-hot set of registers being read from
    bit [MATRIX_REGISTERS-1:0] currently_writing;               // One-hot set of registers being read from

    assign load_ready_out = ~|(reg_load_addr_in & (currently_writing | currently_reading));
    assign store_ready_out = ~|(reg_store_addr_in & currently_writing);

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

    // Logic for tracking registers actively being written to
    always_ff @(posedge clk) begin : active_write
        if (rst) begin
            currently_writing <= '0;
        end
        else begin
            if (reg_load_en_in) begin
                currently_writing <= currently_writing | (1 << reg_load_addr_in);
            end
            else begin
                currently_writing <= currently_writing & ~(1 << reg_load_addr_in);
            end
        end
    end : active_write

    // Logic for tracking registers actively being read from
    always_ff @(posedge clk) begin : active_read
        if (rst) begin
            currently_reading <= '0;
        end
        else begin
            if (reg_store_en_in) begin
                currently_reading <= currently_reading | (1 << reg_store_addr_in);
            end
            else begin
                currently_reading <= currently_reading & ~(1 << reg_store_addr_in);
            end
        end
    end : active_read

endmodule : mpu_register_file
