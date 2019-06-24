// fpu_multiplier_tb.sv

import mm_defs::*;

module fpu_multiplier_tb;
	import fpu_pkg::*;

	int input_a='0, input_b='0, output_z;
    bit input_a_stb=0, input_b_stb=0, output_z_stb;
    bit input_a_ack, input_b_ack, output_z_ack=0;

    int test_a='0, test_b=32'h42b1cccd, result='0;

    fpu_operation_t op_set;

    fpu_bfm fpu_bfm();

	fpu_multiplier dut(
		.clk 		 (fpu_bfm.clk),
		.rst 		 (fpu_bfm.rst),
		.input_a     (fpu_bfm.input_a),
		.input_a_ack (fpu_bfm.input_a_ack),
		.input_a_stb (fpu_bfm.input_a_stb),
		.input_b     (fpu_bfm.input_b),
		.input_b_ack (fpu_bfm.input_b_ack),
		.input_b_stb (fpu_bfm.input_b_stb),
		.output_z    (fpu_bfm.output_z),
		.output_z_ack(fpu_bfm.output_z_ack),
		.output_z_stb(fpu_bfm.output_z_stb)
	);

	initial begin : sanity_checks
		$display("\n\n\t$shortrealtobits(1.0): \t %x", $shortrealtobits(1.0));
		$display("\t$realtobits(1.0): \t %x \n\n", $realtobits(1.0));
	end : sanity_checks

	initial begin
		fpu_bfm.reset_fpu();
		forever begin
			test_a += 1;
			test_b = 32'h42b1cccd;
			op_set = mult;
			fpu_bfm.send_op(op_set, $shortrealtobits($itor(test_a)), test_b, result);
		end
	end

	//initial $monitor($time, "\tA: %f    B: %f     Z: %f", $bitstoshortreal(fpu_bfm.input_a), $bitstoshortreal(fpu_bfm.input_b), $bitstoshortreal(fpu_bfm.output_z));
	//initial $monitor("\tA: %f    B: %f     Z: %f", $bitstoshortreal(fpu_bfm.input_a), $bitstoshortreal(fpu_bfm.input_b), $bitstoshortreal(fpu_bfm.output_z));

endmodule