// fpu_multiplier_tb.sv

module fpu_multiplier_tb (
	input clk,    // Clock
	input clk_en, // Clock Enable
	input rst_n   // Asynchronous reset active low
);

	bit [31:0] input_a='0, input_b='0, output_z;
    bit input_a_stb=0, input_b_stb=0, output_z_stb;
    bit input_a_ack, input_b_ack, output_z_ack=0;

    int test_a='0, test_b=32'h42b1cccd;

	fpu_multiplier dut(
		.clk 		 (clk & clk_en),
		.rst 		 (~rst_n),
		.input_a     (input_a),
		.input_a_ack (input_a_ack),
		.input_a_stb (input_a_stb),
		.input_b     (input_b),
		.input_b_ack (input_b_ack),
		.input_b_stb (input_b_stb),
		.output_z    (output_z),
		.output_z_ack(output_z_ack),
		.output_z_stb(output_z_stb)
	);

	initial begin : sanity_checks
		$display("\n\n\t$shortrealtobits(1.0): \t %x", $shortrealtobits(1.0));
		$display("\t$realtobits(1.0): \t %x \n\n", $realtobits(1.0));
	end : sanity_checks

	initial begin
		repeat (10) @(posedge clk);
		forever begin
			test_a += 1;
			test_b = 32'h42b1cccd;
			multiply(test_a, test_b);
		end
	end

	//initial $monitor($time, "\tA: %f    B: %f     Z: %f", $bitstoshortreal(input_a), $bitstoshortreal(input_b), $bitstoshortreal(output_z));
	initial $monitor("\tA: %f    B: %f     Z: %f", $bitstoshortreal(input_a), $bitstoshortreal(input_b), $bitstoshortreal(output_z));


	task multiply(input int in1, input int in2);

		// Load multiplicand
		@(posedge clk);
		input_a = $shortrealtobits($itor(in1));
		input_a_stb = 1;
		@(input_a_ack);
		@(posedge clk);
		input_a_stb = 0;
		
		// Load multiplier
		//input_b = $shortrealtobits($itor(in2));
		input_b = in2;
		input_b_stb = 1;
		@(input_b_ack);
		@(posedge clk);
		input_b_stb = 0;
		
		// Wait for result
		@(output_z_stb);
		@(posedge clk);
		output_z_ack = 1;
		@(posedge clk);
		output_z_ack = 0;			

	endtask : multiply

endmodule