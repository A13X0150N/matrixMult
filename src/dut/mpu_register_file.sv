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
// Modules that use this must use their assigned ready out signal to know when it
// is ok to read/write to the registers.
 
import global_defs::*;
import mpu_data_types::*;

module mpu_register_file 
(
    // Control Signals
    input  clk,                                             // Clock
    input  rst,                                             // Synchronous reset, active high
    input  bit reg_load_req_in,                             // Matrix load request
    input  bit reg_store_req_in,                            // Matrix store request
    input  bit reg_disp_req_in,                             // Dispatcher matrix read request
    input  bit reg_collector_req_in,                        // Collector matrix write request

    // To Load
    output bit load_ready_out,                              // Matrix load ready sync signal    
    input  bit [MATRIX_REG_BITS:0] reg_load_addr_in,        // Matrix address to load into  
    input  bit [MBITS:0] reg_i_load_loc_in,                 // Matrix input row location
    input  bit [NBITS:0] reg_j_load_loc_in,                 // Matrix input column location
    input  bit [MBITS:0] reg_m_load_size_in,                // Matrix input row size
    input  bit [NBITS:0] reg_n_load_size_in,                // Matrix input column size
    input  float_sp reg_load_element_in,                    // Matrix input data

    // To Store
    output bit store_ready_out,                             // Matrix store ready sync signal
    input  bit [MATRIX_REG_BITS:0] reg_store_addr_in,       // Matrix address to write out from
    input  bit [MBITS:0] reg_i_store_loc_in,                // Matrix output row location
    input  bit [NBITS:0] reg_j_store_loc_in,                // Matrix output column location
    output bit [MBITS:0] reg_m_store_size_out,              // Matrix output total rows
    output bit [NBITS:0] reg_n_store_size_out,              // Matrix output total columns
    output float_sp reg_store_element_out                   // Matrix output data

    // To Controller
    output bit reg_disp_ready_out,                          // Dispatcher read ready sync signal
    output bit reg_collector_ready_out,                     // Collector write ready sync signal
    input  bit [MATRIX_REG_BITS:0] reg_disp_addr_0_in,      // Dispatcher operand address 0
    input  bit [MATRIX_REG_BITS:0] reg_disp_addr_1_in,      // Dispatcher operand address 1 
    input  bit [MATRIX_REG_BITS:0] reg_collector_addr_in,   // Collector operand address

    // To Dispatcher
    input  bit [MBITS:0] reg_disp_0_i_in,                   // Dispatcher input row location
    input  bit [NBITS:0] reg_disp_0_j_in,                   // Dispatcher input column location
    input  bit [MBITS:0] reg_disp_1_i_in,                   // Dispatcher input row location
    input  bit [NBITS:0] reg_disp_1_j_in,                   // Dispatcher input column location
    output float_sp reg_disp_element_0_out,                 // Dispatcher element 0 output
    output float_sp reg_disp_element_1_out,                 // Dispatcher element 1 output

    // To Collector
    input  bit [MBITS:0] reg_collector_i_in,                // Collector input row location
    input  bit [MBITS:0] reg_collector_j_in,                // Collector input column location
    input  float_sp reg_collector_element_in                // Collector element input
);

    float_sp matrix_register_array [MATRIX_REGISTERS][M][N];// Matrix Registers
    bit [MBITS:0] size_m;                                   // Matrix total rows
    bit [NBITS:0] size_n;                                   // Matrix total columns
    bit [MATRIX_REGISTERS-1:0] currently_reading;           // One-hot set of registers being read from
    bit [MATRIX_REGISTERS-1:0] currently_writing;           // One-hot set of registers being written to

    // Broadcast if a requested address is busy
    assign load_ready_out = ~|(reg_load_addr_in & (currently_writing | currently_reading));     // Only write to unused registers
    assign store_ready_out = ~|(reg_store_addr_in & currently_writing);                         // Only read from registers NOT being written to
    assign reg_disp_ready_out = ~|((reg_disp_addr_0_in & currently_writing) | (reg_disp_addr_1_in & currently_writing));  // Dispatcher check
    assign reg_collector_ready_out = ~|(reg_collector_addr_in & (currently_writing | currently_reading));  // Collector check

    // Load a matrix into a register from memory
    always_ff @(posedge clk) begin : matrix_load
        if (rst) begin
            size_m <= '0;
            size_n <= '0;
        end
        else if (reg_load_req_in & load_ready_out) begin //check
            size_m <= reg_m_load_size_in;
            size_n <= reg_n_load_size_in;
            matrix_register_array[reg_load_addr_in][reg_i_load_loc_in][reg_j_load_loc_in] <= reg_load_element_in;
        end
    end : matrix_load

    // Store a vectorized matrix from a register out to memory
    always_ff @(posedge clk) begin : matrix_store
        if (reg_store_req_in & store_ready_out) begin // check
            reg_m_store_size_out <= size_m;
            reg_n_store_size_out <= size_n;
            reg_store_element_out <= matrix_register_array[reg_store_addr_in][reg_i_store_loc_in][reg_j_store_loc_in];    
        end
    end : matrix_store

    // Dispatch a matrix to the execution unit
    always_ff @(posedge clk) begin : matrix_dispatch
        if (reg_disp_req_in & reg_disp_ready_out) begin // check
            reg_disp_element_0_out <= matrix_register_array[reg_disp_addr_0_in][reg_disp_0_i_in][reg_disp_0_j_in];
            reg_disp_element_1_out <= matrix_register_array[reg_disp_addr_1_in][reg_disp_1_i_in][reg_disp_1_j_in];
        end
    end : matrix_dispatch

    // Collect a matrix from the execution unit 
    always_ff @(posedge clk) begin : matrix_collect
        if (reg_collector_req_in & reg_collector_ready_out) begin // check
            matrix_register_array[reg_collector_addr_in][reg_collector_i_in][reg_collector_j_in] <= reg_collector_element_in;
        end
    end : matrix_collect

    // Logic for tracking registers actively being written to
    always_ff @(posedge clk) begin : active_write
        if (rst) begin
            currently_writing <= '0;
        end
        else begin
            if (reg_load_req_in & reg_collector_req_in) begin
                currently_writing <= currently_writing | (1 << reg_load_addr_in) | (1 << reg_collector_addr_in);
            end
            else if (reg_load_req_in) begin
                currently_writing <= currently_writing | (1 << reg_load_addr_in);
            end
            else if (reg_collector_req_in) begin
                currently_writing <= currently_writing | (1 << reg_collector_addr_in);
            end
            else begin
                currently_writing <= currently_writing & ~((1 << reg_load_addr_in) | (1 << reg_collector_addr_in));
            end
        end
    end : active_write

    // Logic for tracking registers actively being read from
    always_ff @(posedge clk) begin : active_read
        if (rst) begin
            currently_reading <= '0;
        end
        else begin
            if (reg_store_req_in & reg_disp_req_in) begin
                currently_reading <= currently_reading | (1 << reg_store_addr_in) | (1 << reg_disp_addr_0_in) | (1 << reg_disp_addr_1_in);
            end
            else if (reg_store_req_in) begin
                currently_reading <= currently_reading | (1 << reg_store_addr_in);
            end
            else if (disp_en_in) begin
                currently_reading <= currently_reading | (1 << reg_disp_addr_0_in) | (1 << reg_disp_addr_1_in);
            end
            else begin
                currently_reading <= currently_reading & ~((1 << reg_store_addr_in) | (1 << reg_disp_addr_0_in) | (1 << reg_disp_addr_1_in));
            end
        end
    end : active_read

endmodule : mpu_register_file
