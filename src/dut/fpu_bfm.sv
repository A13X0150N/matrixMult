// fpu_bfm.sv

import mm_defs::*;

interface fpu_bfm;
	import fpu_pkg::*;

	bit clk=0, rst=0;
	int input_a='0, input_b='0, output_z;
    bit input_a_stb=0, input_b_stb=0, output_z_stb;
    bit input_a_ack, input_b_ack, output_z_ack=0;


	initial begin : clock_generator
		clk = 0;
		forever #(CLOCK_PERIOD/2) clk = ~clk;
	end : clock_generator


	task reset_fpu;
		rst = 0;
		repeat (10) @(posedge clk);
		rst = 1;
		repeat (10) @(posedge clk);
		rst = 0;
		repeat (10) @(posedge clk);
	endtask : reset_fpu


	task send_op(input fpu_operation_t op, input int in1, input int in2, output int result);
		unique case(op)
			nop: $display("NOP");
			
			add: begin 
				$display("ADD   %f + %f", $bitstoshortreal(in1), $bitstoshortreal(in2));
				$display(" result:   %f\n", $bitstoshortreal(result));
			end

			mult: begin
				$display("MULTIPLY   %f * %f", $bitstoshortreal(in1), $bitstoshortreal(in2));
				// Load multiplicand
				@(posedge clk);
				input_a = in1;
				input_a_stb = 1;
				@(input_a_ack);
				@(posedge clk);
				input_a_stb = 0;
				
				// Load multiplier
				input_b = in2;
				input_b_stb = 1;
				@(input_b_ack);
				@(posedge clk);
				input_b_stb = 0;
				
				// Wait for result
				@(output_z_stb);
				@(posedge clk);
				result = output_z;
				output_z_ack = 1;
				@(posedge clk);
				output_z_ack = 0;
				$display(" result:   %f\n", $bitstoshortreal(result));
			end

		endcase
	endtask : send_op

endinterface : fpu_bfm
