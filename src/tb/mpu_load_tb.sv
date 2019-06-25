// mpu_load_tb.sv

import mm_defs::*;

module mpu_load_tb;

	import mpu_pkg::*;

	mpu_bfm mpu_bfm();

	mpu_load dut (
		.clk  (mpu_bfm.clk),
		.rst  (mpu_bfm.rst)
	);


endmodule : mpu_load_tb
