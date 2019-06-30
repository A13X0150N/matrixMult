// fpu_bfm.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Contains the signals and transactions for IEEE 754 single-precision addition
// and multiplication. Operations are sent using the send_op task.

import global_defs::*;

interface fpu_bfm;
    import fpu_pkg::*;

    bit clk=0, rst=0;
    int input_a='0, input_b='0, output_z;
    bit input_stb=0, output_stb;
    bit input_ack, output_ack=0;


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
            NOP: begin
                $display("FPU NOP");
                @(posedge clk);
            end
            
            ADD: begin 
                // Load inputs
                @(posedge clk);
                input_a = in1;
                input_b = in2;
                input_stb = 1;
                @(input_ack);
                @(posedge clk);
                input_stb = 0;
                
                // Wait for result
                @(output_stb);
                result = output_z;
                output_ack = 1;
                @(posedge clk);
                output_ack = 0;
                $display((($time+(CLOCK_PERIOD/2))/CLOCK_PERIOD), " clock cycles\nFPU ADD result:\t %f + %f = %f\n", $bitstoshortreal(in1), $bitstoshortreal(in2), $bitstoshortreal(result));
            end

            MULT: begin
                // Load inputs
                @(posedge clk);
                input_a = in1;
                input_b = in2;
                input_stb = 1;
                @(input_ack);
                @(posedge clk);
                input_stb = 0;
                
                // Wait for result
                @(output_stb);
                result = output_z;
                output_ack = 1;
                @(posedge clk);
                output_ack = 0;
                $display((($time+(CLOCK_PERIOD/2))/CLOCK_PERIOD), " clock cycles\nFPU MULTIPLY result:\t %f * %f = %f\n", $bitstoshortreal(in1), $bitstoshortreal(in2), $bitstoshortreal(result));
            end

        endcase
    endtask : send_op

endinterface : fpu_bfm
