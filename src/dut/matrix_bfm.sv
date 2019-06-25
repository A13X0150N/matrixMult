// matrix_bfm.sv

import mm_defs::*;

interface matrix_bfm;
	import matrix_pkg::*;

	bit clk=0, rst=0;
    int input_a='0, input_b='0, output_z;
    bit input_stb=0, output_stb;
    bit input_ack, output_ack=0;

endinterface : matrix_bfm
