// mpu_load_tb.sv

import global_defs::*;

module mpu_load_tb;

	import mpu_pkg::*;

	mpu_bfm mpu_bfm();

	mpu_register_file matrix_register_file (
		.clk 			(mpu_bfm.clk),
		.rst 			(mpu_bfm.rst),
		.write_en		(mpu_bfm.write_en),
		.reg_load_addr	(mpu_bfm.reg_load_addr),
		.element 		(mpu_bfm.element_out),
		.m 				(mpu_bfm.m),
		.n 				(mpu_bfm.n),
		.reg_store_addr	(mpu_bfm.reg_store_addr),
		.matrix_out		(mpu_bfm.matrix_out)
	);

	mpu_load dut (
		.clk  			(mpu_bfm.clk),
		.rst  			(mpu_bfm.rst),
		.en   			(mpu_bfm.en),

		// Input matrix from file or memory
		.element 		(mpu_bfm.element),
		.matrix_m_size 	(mpu_bfm.matrix_m_size),
		.matrix_n_size 	(mpu_bfm.matrix_n_size),
		.load_addr 		(mpu_bfm.load_addr),
		.error 			(mpu_bfm.error),
		.ack 			(mpu_bfm.ack),

		// Output to register file
		.write_en		(mpu_bfm.write_en),
		.reg_load_addr 	(mpu_bfm.reg_load_addr),
		.element_out 	(mpu_bfm.element_out),
		.m 				(mpu_bfm.m),
		.n 				(mpu_bfm.n)
	);

	mpu_operation_t op;
	logic [FP-1:0] in_matrix [M*N];
	logic [MBITS:0] in_m;
	logic [NBITS:0] in_n;
	logic [MATRIX_REG_SIZE-1:0] matrix_addr1, matrix_addr2;

	initial begin
		mpu_bfm.reset_mpu();
		op = NOP;
		in_m = 2;
		in_n = 2;
		matrix_addr1 = 0;
		matrix_addr2 = 1;
		foreach(in_matrix[i]) in_matrix[i] = '0;
		mpu_bfm.send_op(op, in_matrix, in_m, in_n, matrix_addr1, matrix_addr2);
		op = LOAD;
		in_matrix[0] = 32'h3f800000; 		// 1.0
		in_matrix[1] = 32'h424951ec; 		// 50.33
		in_matrix[2] = 32'hc0200000;		// -2.5
		in_matrix[3] = 32'h3e000000;		// 0.125
		mpu_bfm.send_op(op, in_matrix, in_m, in_n, matrix_addr1, matrix_addr2);
	end

	final $display("\n\tTEST MATRIX LOAD\n\t%f\t%f\n\t%f\t%f\n", 
					$bitstoshortreal(matrix_register_file.matrix_register_array[0][0][0]),
					$bitstoshortreal(matrix_register_file.matrix_register_array[0][0][1]),
					$bitstoshortreal(matrix_register_file.matrix_register_array[0][1][0]),
					$bitstoshortreal(matrix_register_file.matrix_register_array[0][1][1]));



endmodule : mpu_load_tb
