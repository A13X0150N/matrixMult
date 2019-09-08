// fpu_fma_tb.sv

import global_defs::*;
import mpu_data_types::*;

// Testbench
module fpu_fma_tb;
    import testbench_utilities::*;

    // Test variables
    fpu_data_sp data_in, data_out;
    float_sp float_in, float_in1, float_in2, float_in3, calc_float, float_out;
    bit error_out, start_in, ready_out;
    shortreal a, b, c;

    // Main Test Sequence
    initial begin
        $display("\n\n\n");
        display_message("Beginning FPU Testbench");
        mpu_top.fpu_bfm.wait_for_reset();
        display_message("Reset Complete");

        display_message("Operation: NOP");
        data_in.op = FPU_NOP;
        mpu_top.fpu_bfm.send_op(data_in, data_out);

        display_message("Operation: FMA");
        data_in.op = FPU_FMA;
        a = 1.0;
        b = 2.0;
        c = 1.0;
        data_in.a = $shortrealtobits(a);
        data_in.b = $shortrealtobits(b);
        data_in.c = $shortrealtobits(c);
        mpu_top.fpu_bfm.send_op(data_in, data_out);
        calc_float = $shortrealtobits(a * b + c);
        $display("\n ---- PREDICTED VALUES ----\ncalc_float: %f\n\tcalc_float.exp: %d\n\tcalc_float.man: %d \n\n", $bitstoshortreal(calc_float), calc_float.exponent, calc_float.mantissa);
        $display("\n ---- OUTPUT VALUES ----\ny: %f\n\ty.exp: %d\n\ty.man: %d\n\n", $bitstoshortreal(data_out.y), data_out.y.exponent, data_out.y.mantissa);

        display_message("Operation: NOP");
        data_in.op = FPU_NOP;
        mpu_top.fpu_bfm.send_op(data_in, data_out);


        $display("\n");
        display_message("End of FMA Testbench");
        $display("\n");
        $finish;
    end

endmodule: fpu_fma_tb