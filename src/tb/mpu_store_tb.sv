// mpu_store_tb.sv

import mm_defs::*;

module mpu_store_tb;

	import mpu_pkg::*;

	mpu_bfm mpu_bfm();

	mpu_store dut (
		.clk  (mpu_bfm.clk),
		.rst  (mpu_bfm.rst)
	);


	

endmodule : mpu_store_tb
