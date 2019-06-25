// matrix_load_tb.sv

import mm_defs::*;

module matrix_load_tb;

	import matrix_pkg::*;

	matrix_bfm matrix_bfm();

	matrix_load dut (
		.clk  (matrix_bfm.clk),
		.rst  (matrix_bfm.rst)
	);


endmodule : matrix_load_tb
