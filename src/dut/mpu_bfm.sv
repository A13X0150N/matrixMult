// mpu_bfm.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Bus Functional Model interface for the matrix processor. Can currently
// perform nop, load, and store transactions on the design.

import global_defs::*;

interface mpu_bfm(input clk, rst);
// pragma attribute mpu_bfm partition_interface_xif
    import mpu_pkg::*;

    bit load_en;        // Load enable
    bit store_en;       // Store enable 
    bit reg_load_en;      // Register load enable
    bit reg_store_en;     // Register store enable
    bit mem_load_error;   // Error signal     
    bit mem_load_ack;     // Acknowledge signal
    bit mem_store_en;     // Memory store enable signal

    // Input/Output matrix from file or memory
    bit [FPBITS:0] mem_load_element;       // [32|64]-bit float, matrix element
    bit [MBITS:0] mem_m_load_size;         // m-dimension of input matrix
    bit [NBITS:0] mem_n_load_size;         // n-dimension of input matrix
    bit [MATRIX_REG_BITS:0] mem_load_addr;    // Matrix address to load matrix in
    bit [MATRIX_REG_BITS:0] mem_store_addr;   // Matrix address to load matrix in
    bit [FPBITS:0] mem_store_element;         // Element to send out to memory
    bit [MBITS:0] mem_m_store_size;           // Row size of output matrix
    bit [NBITS:0] mem_n_store_size;           // Column size of output matrix

    // Output to register file
    bit [MATRIX_REG_BITS:0] reg_load_addr;    // Matrix register address to load matrix in
    bit [MATRIX_REG_BITS:0] reg_store_addr;   // Matrix register address to write matix out
    bit [FPBITS:0] reg_load_element;          // Matrix load data element
    bit [FPBITS:0] reg_store_element;         // Matrix store data element
    bit [MBITS:0] reg_m_load_size;            // Register matrix row size
    bit [NBITS:0] reg_n_load_size;            // Register matrix column size
    bit [MBITS:0] reg_m_store_size;           // Register matrix row size
    bit [NBITS:0] reg_n_store_size;           // Register matrix column size
    bit [MBITS:0] reg_i_load_loc;             // Matrix load row location
    bit [NBITS:0] reg_j_load_loc;             // Matrix load column location
    bit [MBITS:0] reg_i_store_loc;            // Matrix store row location
    bit [NBITS:0] reg_j_store_loc;            // Matrix store column location
    
    // Interface metasignal
    bit [$clog2(M*N)-1:0] idx='0;    // Vectorized matrix index

    // Wait for reset task.
    task wait_for_reset(); // pragma tbx xtf
        @(negedge rst);
        load_en <= 0;
        store_en <= 0;
        mem_load_element <= '0;
        mem_m_load_size <= '0;
        mem_n_load_size <= '0;
    endtask

    // Send an operation into an MPU
    task send_op(input mpu_data_t req, output mpu_data_t rsp); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
        case(req.op)
            NOP: begin
                @(posedge clk);
            end

            LOAD: begin 
                idx <= '0;
                mem_m_load_size <= req.m_in;
                mem_n_load_size <= req.n_in;
                mem_load_addr <= req.matrix_addr;
                load_en <= 1;
                while (!mem_load_ack) begin
                    @(posedge clk);
                end;
                do begin
                    mem_load_element <= req.matrix_in[idx];
                    idx <= idx + 1;
                    @(posedge clk);
                end while (mem_load_ack);
                load_en <= 0;
            end

            STORE: begin
                mem_store_addr <= req.matrix_addr;
                idx <= '0;
                store_en <= 1;
                while (!mem_store_en) begin
                    @(posedge clk);
                end
                do begin
                    @(posedge clk);
                    rsp.matrix_out[idx] <= mem_store_element;
                    idx <= idx + 1;
                end while (mem_store_en);
                @(posedge clk);
                store_en <= 0;
            end

        endcase
    endtask : send_op

endinterface : mpu_bfm
