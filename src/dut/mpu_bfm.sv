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
import mpu_data_types::*;

interface mpu_bfm(input clk, rst); 
// pragma attribute mpu_bfm partition_interface_xif

    // Control signals
    bit load_req;                           // Load enable
    bit store_req;                          // Store enable 
    bit reg_load_req;                       // Register load (register write) request
    bit reg_store_req;                      // Register store (register read) request
    bit reg_disp_req;                       // Register dispenser (register read) request
    bit reg_collector_req;                  // Register collector (register write) request
    bit mem_load_error;                     // Error signal     
    bit mem_load_ack;                       // Acknowledge signal
    bit mem_store_en;                       // Memory store enable signal
    bit load_ready;                         // Load ready signal
    bit store_ready;                        // Store ready signal
    bit disp_ready;                         // Dispenser ready signal
    bit collector_ready;                    // Collector ready signal
    bit collector_finished;
    bit collector_active_write;
    bit start_mult;
    bit [MATRIX_REG_BITS:0] src_addr_0;
    bit [MATRIX_REG_BITS:0] src_addr_1;
    bit [MATRIX_REG_BITS:0] dest_addr;

    // Input/Output matrix from file or memory
    float_sp mem_load_element;              // Incoming float, matrix element
    bit [MBITS:0] mem_m_load_size;          // m-dimension of input matrix
    bit [NBITS:0] mem_n_load_size;          // n-dimension of input matrix
    bit [MATRIX_REG_BITS:0] mem_load_addr;  // Matrix address to load matrix in
    bit [MATRIX_REG_BITS:0] mem_store_addr; // Matrix address to load matrix in
    float_sp mem_store_element;             // Element to send out to memory
    bit [MBITS:0] mem_m_store_size;         // Row size of output matrix
    bit [NBITS:0] mem_n_store_size;         // Column size of output matrix

    // Output to register file
    bit [MATRIX_REG_BITS:0] reg_load_addr;  // Matrix register address to load matrix in
    bit [MATRIX_REG_BITS:0] reg_store_addr; // Matrix register address to write matix out
    float_sp reg_load_element;              // Matrix load data element
    float_sp reg_store_element;             // Matrix store data element
    bit [MBITS:0] reg_m_load_size;          // Register matrix row size
    bit [NBITS:0] reg_n_load_size;          // Register matrix column size
    bit [MBITS:0] reg_m_store_size;         // Register matrix row size
    bit [NBITS:0] reg_n_store_size;         // Register matrix column size
    bit [MBITS:0] reg_i_load_loc;           // Matrix load row location
    bit [NBITS:0] reg_j_load_loc;           // Matrix load column location
    bit [MBITS:0] reg_i_store_loc;          // Matrix store row location
    bit [NBITS:0] reg_j_store_loc;          // Matrix store column location
    bit [MATRIX_REG_BITS:0] reg_src_addr_0;
    bit [MATRIX_REG_BITS:0] reg_src_addr_1;
    bit [MATRIX_REG_BITS:0] reg_dest_addr;

    // Dipatcher signals
    bit disp_start;
    bit disp_ack;
    bit disp_finished;
    bit [MBITS:0] reg_disp_0_i;
    bit [NBITS:0] reg_disp_0_j;
    bit [MBITS:0] reg_disp_1_i;
    bit [NBITS:0] reg_disp_1_j;
    float_sp reg_disp_element_0;
    float_sp reg_disp_element_1;

    // Collector signals
    bit [MBITS:0] reg_collector_i;
    bit [NBITS:0] reg_collector_j;
    float_sp reg_collector_element;

    // FMA cluster signals
    bit busy_0_0;
    bit busy_0_1;
    bit busy_0_2;
    bit busy_1_0;
    bit busy_1_2;
    bit busy_2_0;
    bit busy_2_1;
    bit busy_2_2;

    bit float_0_req_0_0;
    bit float_0_req_0_2;
    bit float_0_req_1_0;
    bit float_0_req_1_2;
    bit float_0_req_2_0;
    bit float_0_req_2_2;

    bit float_1_req_0_0;
    bit float_1_req_0_1;
    bit float_1_req_0_2;
    bit float_1_req_2_0;
    bit float_1_req_2_1;
    bit float_1_req_2_2;

    bit ready_0_0;
    bit ready_0_1;
    bit ready_0_2;
    bit ready_1_0;
    bit ready_1_1;
    bit ready_1_2;
    bit ready_2_0;
    bit ready_2_1;
    bit ready_2_2;

    float_sp float_0_data_0_0;
    float_sp float_0_data_0_2;
    float_sp float_0_data_1_0;
    float_sp float_0_data_1_2;
    float_sp float_0_data_2_0;
    float_sp float_0_data_2_2;

    float_sp float_1_data_0_0;
    float_sp float_1_data_0_1;
    float_sp float_1_data_0_2;
    float_sp float_1_data_2_0;
    float_sp float_1_data_2_1;
    float_sp float_1_data_2_2;

    float_sp result_0_0;
    float_sp result_0_1;
    float_sp result_0_2;
    float_sp result_1_0;
    float_sp result_1_1;
    float_sp result_1_2;
    float_sp result_2_0;
    float_sp result_2_1;
    float_sp result_2_2;

    bit error_detected;
    
    // Interface metasignal
    bit [$clog2(M*N)-1:0] idx='0;    // Vectorized matrix index

    // Wait for reset task
    task wait_for_reset(); // pragma tbx xtf
        @(negedge rst);
        load_req <= FALSE;
        store_req <= FALSE;
        mem_load_element <= '0;
        mem_m_load_size <= '0;
        mem_n_load_size <= '0;
    endtask

    // Send an operation into an MPU
    task send_op(input mpu_data_sp req, output mpu_data_sp rsp); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
        case(req.op)
            
            MPU_NOP: begin
                @(posedge clk);
            end

            MPU_LOAD: begin 
                idx <= '0;
                mem_m_load_size <= req.m_in;
                mem_n_load_size <= req.n_in;
                mem_load_addr <= req.src_addr_0;
                mem_load_element <= req.matrix_in[idx];
                load_req <= TRUE;
                while (!mem_load_ack) begin
                    @(posedge clk);
                end;
                do begin
                    mem_load_element <= req.matrix_in[idx];
                    idx <= idx + 1;
                    @(posedge clk);
                end while (mem_load_ack);
                load_req <= FALSE;
            end

            MPU_STORE: begin
                idx <= '0;
                mem_store_addr <= req.src_addr_0;
                store_req <= TRUE;
                while (!mem_store_en) begin
                    @(posedge clk);
                end
                do begin
                    @(posedge clk);
                    rsp.matrix_out[idx] <= mem_store_element;
                    idx <= idx + 1;
                end while (mem_store_en);
                @(posedge clk);
                store_req <= FALSE;
            end

            MPU_MULT: begin
                src_addr_0 <= req.src_addr_0;
                src_addr_1 <= req.src_addr_1;
                dest_addr <= req.dest_addr;
                start_mult <= TRUE;
                while (!disp_ack) begin
                    @(posedge clk);
                end
                start_mult <= FALSE;
                
                // Remove after debugging for better parallel performance
                //while (!collector_finished) begin
                //    @(posedge clk);
                //end
                @(posedge clk);
            end

        endcase
    endtask : send_op

endinterface : mpu_bfm
