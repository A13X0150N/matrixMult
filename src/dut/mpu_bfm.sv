// mpu_bfm.sv

import global_defs::*;

interface mpu_bfm;
    import mpu_pkg::*;

    // Control signals
    logic clk;                                  // Clock signal
    logic rst;                                  // Synchronous reset, active high
    logic load_en;                              // Load enable
    logic store_en;                             // Store enable 
    logic reg_load_en;                          // Register load enable
    logic reg_store_en;                         // Register store enable
    logic mem_load_error;                       // Error signal     
    logic mem_load_ack;                         // Acknowledge signal
    logic mem_store_en;                         // Memory store enable signal

    // Input/Output matrix from file or memory
    logic [FP-1:0] mem_load_element;            // [32|64]-bit float, matrix element
    logic [MBITS:0] mem_m_load_size;            // m-dimension of input matrix
    logic [NBITS:0] mem_n_load_size;            // n-dimension of input matrix
    logic [MATRIX_REG_SIZE-1:0] mem_load_addr;  // Matrix address to load matrix in
    logic [MATRIX_REG_SIZE-1:0] mem_store_addr; // Matrix address to load matrix in
    logic [FP-1:0] mem_store_element;           // Element to send out to memory
    logic [MBITS:0] mem_m_store_size;           // Row size of output matrix
    logic [NBITS:0] mem_n_store_size;           // Column size of output matrix

    // Output to register file
    logic [MATRIX_REG_SIZE-1:0] reg_load_addr;  // Matrix register address to load matrix in
    logic [MATRIX_REG_SIZE-1:0] reg_store_addr; // Matrix register address to write matix out
    logic [FP-1:0] reg_load_element;            // Matrix load data element
    logic [FP-1:0] reg_store_element;           // Matrix store data element
    logic [MBITS:0] reg_m_load_size;            // Register matrix row size
    logic [NBITS:0] reg_n_load_size;            // Register matrix column size
    logic [MBITS:0] reg_m_store_size;           // Register matrix row size
    logic [NBITS:0] reg_n_store_size;           // Register matrix column size
    logic [MBITS:0] reg_i_load_loc;             // Matrix load row location
    logic [NBITS:0] reg_j_load_loc;             // Matrix load column location
    logic [MBITS:0] reg_i_store_loc;            // Matrix store row location
    logic [NBITS:0] reg_j_store_loc;            // Matrix store column location
    
    // Vectorized matrix index
    logic [$clog2(M*N)-1:0] idx;                // Vectorized matrix index

    initial begin : clock_generator
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end : clock_generator

    // Reset the MPU
    task reset_mpu;
        load_en = 0;
        store_en = 0;
        mem_load_element = 'x;
        mem_m_load_size = '0;
        mem_n_load_size = '0;
        idx = '0;
        rst = 0;
        repeat (10) @(posedge clk);
        rst = 1;
        repeat (10) @(posedge clk);
        rst = 0;
        repeat (10) @(posedge clk);
    endtask : reset_mpu

    // Send an operation into an MPU
    task send_op(   input mpu_operation_t op,
                    input logic [FP-1:0] in_matrix [NUM_ELEMENTS], 
                    input logic [MBITS:0] in_m, 
                    input logic [NBITS:0] in_n,
                    input logic [MATRIX_REG_SIZE-1:0] matrix_addr1, matrix_addr2
                );
        unique case(op)
            NOP: begin
                $display("NOP");
                @(posedge clk);
            end

            LOAD: begin 
                $display("LOAD");
                @(posedge clk);
                mem_m_load_size = in_m;
                mem_n_load_size = in_n;
                mem_load_addr = matrix_addr1;
                idx = '0;
                load_en = 1;
                @(mem_load_ack);
                do begin
                    @(posedge clk);
                    mem_load_element = in_matrix[idx++];
                    @(posedge clk);
                end while (mem_load_ack);
                @(posedge clk);
                load_en = 0;
            end

            STORE: begin 
                $display("STORE");
                @(posedge clk);
                mem_store_addr = matrix_addr1;
                store_en = 1;
                @(mem_store_en);    
                do begin
                    @(posedge clk);
                end while (mem_store_en);
                //@(posedge clk);
                store_en = 0;
                $display("ENDSTORE");
            end

        endcase
    endtask : send_op

endinterface : mpu_bfm
