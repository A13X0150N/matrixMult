// matrix_store_tb.sv

import mm_defs::*;

module matrix_store_tb;

	import matrix_pkg::*;

	matrix_bfm matrix_bfm();

	matrix_store dut (
		.clk  (matrix_bfm.clk),
		.rst  (matrix_bfm.rst)
	);


	

endmodule : matrix_store_tb
