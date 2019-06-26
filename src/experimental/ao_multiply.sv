// ao_multiply.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// HDL to multiply two binary numbers. Output double the length of the input.

import global_defs::*;

module ao_multiply
#(
	parameter  INWIDTH  = 16,					// Input width that captures the input size
	localparam OUTWIDTH = INWIDTH * 2			// The output has double the width of the input
)
( 
	input  logic 				clk, rst_n, start,
	input  logic [INWIDTH-1:0] 	A, B,
	output logic [OUTWIDTH-1:0] Y,
	output logic 				ready
);

	logic [OUTWIDTH:0] 			product;
    logic [$clog2(INWIDTH):0]   count = 0; 
    logic           			lostbit;
    logic [INWIDTH:0]   		multsx;

	assign Y = ready ? product[OUTWIDTH-1:0] : 'x;
	assign ready = !count;
	assign multsx = {A[INWIDTH-1], A};

	// Simulation
	if (MULT_SIMULATION) begin
		initial $display("Multiplication method: Simulation");		
		always_comb begin
			count = 1;
			product = A * B;
			count = '0;
		end
	end

	// Radix-4 Booth Recoding
	else if (MULT_BOOTH_RADIX4) begin
		initial $display("Multiplication method: Booth Radix-4");
		always_ff @(posedge clk) begin

		 	// Begin multiplication process
     		if(ready && start) begin
        		//count = 8;
        		count = 16;
        		product = B;
        		lostbit = 0;
        	end

        	// Carry out recoded multiplication process
        	else if(count) begin
        		case ({product[1:0], lostbit})
          			3'b001: product[OUTWIDTH:INWIDTH] = product[OUTWIDTH:INWIDTH] + multsx;
          			3'b010: product[OUTWIDTH:INWIDTH] = product[OUTWIDTH:INWIDTH] + multsx;
          			3'b011: product[OUTWIDTH:INWIDTH] = product[OUTWIDTH:INWIDTH] + 2 * A;
          			3'b100: product[OUTWIDTH:INWIDTH] = product[OUTWIDTH:INWIDTH] - 2 * A;
          			3'b101: product[OUTWIDTH:INWIDTH] = product[OUTWIDTH:INWIDTH] - multsx;
          			3'b110: product[OUTWIDTH:INWIDTH] = product[OUTWIDTH:INWIDTH] - multsx;
        		endcase
        		lostbit = product[1];
        		product = {product[OUTWIDTH], product[OUTWIDTH], product[OUTWIDTH:2]};
        		--count;
    		end
    	end
	end

	// Invalid selection
	else begin
		initial $error("Select a multiplication algorithm in the \"packages.sv\" file");
	end

endmodule : ao_multiply
