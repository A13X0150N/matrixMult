// mpu_bfm.sv

import mm_defs::*;

interface mpu_bfm;
	import matrix_pkg::*;

	bit clk=0, rst=0;
    int input_a='0, input_b='0, output_z;
    bit input_stb=0, output_stb;
    bit input_ack, output_ack=0;

    initial begin : clock_generator
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end : clock_generator

    task reset_mpu;
        rst = 0;
        repeat (10) @(posedge clk);
        rst = 1;
        repeat (10) @(posedge clk);
        rst = 0;
        repeat (10) @(posedge clk);
    endtask : reset_mpu

endinterface : mpu_bfm
