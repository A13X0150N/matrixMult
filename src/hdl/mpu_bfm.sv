// mpu_bfm.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Bus Functional Model interface for the matrix processor. Can currently
// perform nop, load, store, and multiply transactions on the design.
//
// ----------------------------------------------------------------------------

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
    bit collector_finished;                 // Collector finished signal
    bit collector_active_write;             // Collector actively writing to memory signal
    bit start_mult;                         // Signal to begin dispatching numbers for multiplication
    bit [MATRIX_REG_BITS:0] src_addr_0;     // Matrix operand address 0
    bit [MATRIX_REG_BITS:0] src_addr_1;     // Matrix operand address 1
    bit [MATRIX_REG_BITS:0] dest_addr;      // Matrix destination address

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
    bit [MATRIX_REG_BITS:0] reg_src_addr_0; // Matrix operand address 0
    bit [MATRIX_REG_BITS:0] reg_src_addr_1; // Matrix operand address 1
    bit [MATRIX_REG_BITS:0] reg_dest_addr;  // Matrix destination address

    // Dipatcher signals
    bit disp_start;                         // Signal start dispatching process
    bit disp_ack;                           // Dispatcher signals that it has memory access
    bit disp_finished;                      // Dispatcher signals that is is finished
    bit [MBITS:0] reg_disp_0_i;             // Float 0 location i
    bit [NBITS:0] reg_disp_0_j;             // Float 0 location j
    bit [MBITS:0] reg_disp_1_i;             // Float 1 location i
    bit [NBITS:0] reg_disp_1_j;             // Float 1 location j
    float_sp reg_disp_element_0;            // Float 0
    float_sp reg_disp_element_1;            // Float 1

    // Collector signals
    bit [MBITS:0] reg_collector_i;          // Collected answer location i
    bit [NBITS:0] reg_collector_j;          // Collected answer location j
    float_sp reg_collector_element;         // Collected float answer

    // FMA cluster signals
    bit busy_0_0;                           // FMA cluster unit busy signals
    bit busy_0_1;
    bit busy_0_2;
    bit busy_0_3;
    bit busy_0_4;
    bit busy_0_5;
    bit busy_1_0;
    bit busy_1_5;
    bit busy_2_0;
    bit busy_2_5;
    bit busy_3_0;
    bit busy_3_5;
    bit busy_4_0;
    bit busy_4_5;
    bit busy_5_0;
    bit busy_5_1;
    bit busy_5_2;
    bit busy_5_3;
    bit busy_5_4;
    bit busy_5_5;

    bit float_0_req_0_0;                    // FMA cluster float 0 request signals
    bit float_0_req_0_5;
    bit float_0_req_1_0;
    bit float_0_req_1_5;
    bit float_0_req_2_0;
    bit float_0_req_2_5;
    bit float_0_req_3_0;
    bit float_0_req_3_5;
    bit float_0_req_4_0;
    bit float_0_req_4_5;
    bit float_0_req_5_0;
    bit float_0_req_5_5;

    bit float_1_req_0_0;                    // FMA cluster float 1 request signals
    bit float_1_req_0_1;
    bit float_1_req_0_2;
    bit float_1_req_0_3;
    bit float_1_req_0_4;
    bit float_1_req_0_5;
    bit float_1_req_5_0;
    bit float_1_req_5_1;
    bit float_1_req_5_2;
    bit float_1_req_5_3;
    bit float_1_req_5_4;
    bit float_1_req_5_5;

    bit ready_0_0;                          // FMA cluster unit ready signals
    bit ready_0_1;
    bit ready_0_2;
    bit ready_0_3;
    bit ready_0_4;
    bit ready_0_5;
    bit ready_1_0;
    bit ready_1_1;
    bit ready_1_2;
    bit ready_1_3;
    bit ready_1_4;
    bit ready_1_5;
    bit ready_2_0;
    bit ready_2_1;
    bit ready_2_2;
    bit ready_2_3;
    bit ready_2_4;
    bit ready_2_5;
    bit ready_3_0;
    bit ready_3_1;
    bit ready_3_2;
    bit ready_3_3;
    bit ready_3_4;
    bit ready_3_5;
    bit ready_4_0;
    bit ready_4_1;
    bit ready_4_2;
    bit ready_4_3;
    bit ready_4_4;
    bit ready_4_5;
    bit ready_5_0;
    bit ready_5_1;
    bit ready_5_2;
    bit ready_5_3;
    bit ready_5_4;
    bit ready_5_5;

    float_sp float_0_data_0_0;              // FMA cluster float 0 signals
    float_sp float_0_data_0_5;
    float_sp float_0_data_1_0;
    float_sp float_0_data_1_5;
    float_sp float_0_data_2_0;
    float_sp float_0_data_2_5;
    float_sp float_0_data_3_0;
    float_sp float_0_data_3_5;
    float_sp float_0_data_4_0;
    float_sp float_0_data_4_5;
    float_sp float_0_data_5_0;
    float_sp float_0_data_5_5;

    float_sp float_1_data_0_0;              // FMA cluster float 1 signals
    float_sp float_1_data_0_1;
    float_sp float_1_data_0_2;
    float_sp float_1_data_0_3;
    float_sp float_1_data_0_4;
    float_sp float_1_data_0_5;
    float_sp float_1_data_5_0;
    float_sp float_1_data_5_1;
    float_sp float_1_data_5_2;
    float_sp float_1_data_5_3;
    float_sp float_1_data_5_4;
    float_sp float_1_data_5_5;

    float_sp result_0_0;                    // FMA cluster float answer signals
    float_sp result_0_1;
    float_sp result_0_2;
    float_sp result_0_3;
    float_sp result_0_4;
    float_sp result_0_5;
    float_sp result_1_0;
    float_sp result_1_1;
    float_sp result_1_2;
    float_sp result_1_3;
    float_sp result_1_4;
    float_sp result_1_5;
    float_sp result_2_0;
    float_sp result_2_1;
    float_sp result_2_2;
    float_sp result_2_3;
    float_sp result_2_4;
    float_sp result_2_5;
    float_sp result_3_0;
    float_sp result_3_1;
    float_sp result_3_2;
    float_sp result_3_3;
    float_sp result_3_4;
    float_sp result_3_5;
    float_sp result_4_0;
    float_sp result_4_1;
    float_sp result_4_2;
    float_sp result_4_3;
    float_sp result_4_4;
    float_sp result_4_5;
    float_sp result_5_0;
    float_sp result_5_1;
    float_sp result_5_2;
    float_sp result_5_3;
    float_sp result_5_4;
    float_sp result_5_5;

    bit error_detected;                     // FMA cluster error detected signal
    
    // Interface metasignal
    bit [$clog2(M*N)-1:0] idx='0;           // Vectorized matrix input/output index

    // Wait for reset task
    task wait_for_reset(); // pragma tbx xtf
        @(negedge rst);
        load_req <= FALSE;
        store_req <= FALSE;
        mem_load_element <= '0;
        mem_m_load_size <= '0;
        mem_n_load_size <= '0;
    endtask

    // Burn a clock cycle
    task nop(); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
    endtask : nop

    // Load a matrix into the register
    task load(input mpu_load_sp data); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
        idx <= '0;
        mem_m_load_size <= data.m;
        mem_n_load_size <= data.n;
        mem_load_addr <= data.addr0;
        mem_load_element <= data.load_matrix.matrix[idx];
        load_req <= TRUE;
        while (!mem_load_ack) begin
            @(posedge clk);
        end;
        do begin
            mem_load_element <= data.load_matrix.matrix[idx];
            idx <= idx + 1;
            @(posedge clk);
        end while (mem_load_ack);
        load_req <= FALSE;
    endtask : load

    // Store a matrix from the register out to memory
    task store(input mpu_store_sp data_in, output mpu_store_sp data_out); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
        idx <= '0;
        mem_store_addr <= data_in.addr0;
        store_req <= TRUE;
        while (!mem_store_en) begin
            @(posedge clk);
        end
        do begin
            @(posedge clk);
            data_out.store_matrix.matrix[idx] <= mem_store_element;
            idx <= idx + 1;
        end while (mem_store_en);
        @(posedge clk);
        store_req <= FALSE;
    endtask : store

    task multiply(input mpu_multiply_sp data); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
        src_addr_0 <= data.addr0;
        src_addr_1 <= data.addr1;
        dest_addr <= data.dest;
        start_mult <= TRUE;
        while (!disp_ack) begin
            @(posedge clk);
        end
        start_mult <= FALSE;
        while (!collector_finished) begin
            @(posedge clk);
        end
    endtask : multiply

    task repeat_mult(input bit [MATRIX_REG_BITS:0] addr0,
                     input bit [MATRIX_REG_BITS:0] addr1,
                     input bit [MATRIX_REG_BITS:0] dest,
                     input int iterations); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
        src_addr_0 <= addr0;
        src_addr_1 <= addr1;
        dest_addr <= dest;
        repeat (iterations) begin
            @(posedge clk);
            start_mult <= TRUE;
            while (!disp_ack) begin
                @(posedge clk);
            end
            start_mult <= FALSE;
            while (!collector_finished) begin
                @(posedge clk);
            end
        end
    endtask : repeat_mult

endinterface : mpu_bfm
