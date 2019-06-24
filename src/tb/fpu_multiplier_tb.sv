// fpu_multiplier_tb.sv

import mm_defs::*;

module fpu_multiplier_tb;
    import fpu_pkg::*;

    fpu_bfm fpu_bfm();

    fpu_operation_t op_set=nop;
    int test_a='0, test_b=32'h42b1cccd, result='0;

    fpu_multiplier dut(
        .clk        (fpu_bfm.clk),
        .rst        (fpu_bfm.rst),
        .input_a    (fpu_bfm.input_a),
        .input_b    (fpu_bfm.input_b),
        .input_stb  (fpu_bfm.input_stb),                
        .input_ack  (fpu_bfm.input_ack),
        .output_z   (fpu_bfm.output_z),
        .output_ack (fpu_bfm.output_ack),
        .output_stb (fpu_bfm.output_stb)
    );

    initial begin
        fpu_bfm.reset_fpu();
        fpu_bfm.send_op(op_set, test_a, test_b, result);
        forever begin
            test_a += 1;
            test_b = 32'h42b1cccd;
            op_set = mult;
            fpu_bfm.send_op(op_set, $shortrealtobits($itor(test_a)), test_b, result);
        end
    end

endmodule