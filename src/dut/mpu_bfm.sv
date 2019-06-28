// mpu_bfm.sv

import global_defs::*;

interface mpu_bfm;
	import mpu_pkg::*;

	// Control signals
	logic clk;			// Clock signal
	logic rst;			// Synchronous reset, active high
	logic en;			// Chip enable
	logic write_en;		// Write enable
	logic ack;			// Acknowledge signal
	logic error;		// Error signal

	// Input matrix from file or memory
	logic [FP-1:0] element;						// [32|64]-bit float, matrix element
	logic [MBITS:0] matrix_m_size;				// m-dimension of input matrix
	logic [NBITS:0] matrix_n_size;				// n-dimension of input matrix
	logic [MATRIX_REG_SIZE-1:0] load_addr;		// Matrix address to read matrix in

	// Output to register file
	logic [MATRIX_REG_SIZE-1:0] reg_load_addr;	// Matrix register address to read matrix in
	logic [MATRIX_REG_SIZE-1:0] reg_store_addr;	// Matrix register address to write matix out
	logic [FP-1:0] element_out;					// Matrix data
	logic [MBITS:0] m;							// Matrix row location
	logic [NBITS:0] n;							// Matrix column location

	logic [FP-1:0] matrix_out [M][N];			// Entire matrix output, a 2x2 32-bit matrix will have 128 signals for arithmetic!
	logic [$clog2(M*N)-1:0] idx;				// Vectorized matrix index

    initial begin : clock_generator
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end : clock_generator

    // Reset the MPU
    task reset_mpu;
    	en = 0;
    	element = 'x;
    	matrix_m_size = '0;
    	matrix_n_size = '0;
    	//reg_load_addr = 'x;
    	reg_store_addr = 'x;
    	idx = '0;
        rst = 0;
        repeat (10) @(posedge clk);
        rst = 1;
        repeat (10) @(posedge clk);
        rst = 0;
        repeat (10) @(posedge clk);
    endtask : reset_mpu

    // Send an operation into an MPU
    task send_op(	input mpu_operation_t op,
    				input logic [FP-1:0] in_matrix [M*N], 
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
            	matrix_m_size = in_m;
            	matrix_n_size = in_n;
            	reg_load_addr = matrix_addr1;
            	idx = '0;
            	en = 1;
            	@(ack);
            	do begin
            		@(posedge clk);
            		element = in_matrix[idx++];
            		@(posedge clk);
            	end while (ack);
            	@(posedge clk);
            	en = 0;
            end

            STORE: begin 
            	$display("STORE");
            	@(posedge clk);

            end

        endcase
    endtask : send_op

endinterface : mpu_bfm
