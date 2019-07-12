// mpu_load_store_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench to check the load and store ability of the design. Eventually
// migrate to UVM.

import global_defs::*;

module mpu_load_store_tb;

    import mpu_pkg::*;

    // Test variables
    mpu_data_t data_in, data_out;
    bit [FPBITS:0] num [M_MEM*N_MEM];

    initial begin : main_test_sequence
        mpu_top.mpu_bfm.wait_for_reset();
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.matrix_addr = '0;
        foreach(data_in.matrix_in[i]) data_in.matrix_in[i] = '0;

        data_in.op = NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);
        
        data_in.op = LOAD;
        data_in.matrix_in = {
            32'h3f800000,        // 1.0
            32'h424951ec,        // 50.33
            32'hc0200000,        // -2.5
            32'h3e000000,        // 0.125          2x2 ends here
            32'hbeaaaa9f,        // 0.333333
            32'h4e932c06,        // 1234570000
            32'h00000000,        // 0.0
            32'hb6a7c5ac,        // -0.000005
            32'hd0132c06         // -9876540000    3x3 ends here
        };
        mpu_top.mpu_bfm.send_op(data_in, data_out);
        
        data_in.op = LOAD;
        data_in.matrix_addr = 1;
        data_in.matrix_in = {
            $shortrealtobits(1.0),
            $shortrealtobits(2.2),
            $shortrealtobits(0.0),
            $shortrealtobits(-4.4),
            $shortrealtobits(-0.05),
            $shortrealtobits(-666666.0),
            $shortrealtobits(77777777.0),
            $shortrealtobits(0.8),
            $shortrealtobits(9.0)
        };
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        data_in.op = NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);
        
        data_in.op = STORE;
        data_in.matrix_addr = '0;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        // Parse the output data into an unpacked array for analysis
        {>>{num}} = data_out.matrix_out;
        foreach(num[i])
            $display("num[%1d]: %f", i+1, $bitstoshortreal(num[i]));

        data_in.op = STORE;
        data_in.matrix_addr = 1;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        // Parse the output data into an unpacked array for analysis
        {>>{num}} = data_out.matrix_out;
        foreach(num[i])
            $display("num[%1d]: %f", i+1, $bitstoshortreal(num[i]));

        data_in.op = NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

/*
        //Register dump  DOES NOT WORK WITH EMULATOR
        @(posedge mpu_top.clk);        
        if (NUM_ELEMENTS == 4) begin
            // 2x2 test
            $display("\n\t2x2 MATRIX REGISTER[0] DUMP\n\t %f\t%f \n\t %f\t%f \n", 
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][0][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][0][1]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][1][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][1][1]));
        end
        else if (NUM_ELEMENTS == 9) begin
            // 3x3 test
            $display("\n\t3x3 MATRIX REGISTER[0] DUMP\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][0][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][0][1]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][0][2]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][1][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][1][1]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][1][2]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][2][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][2][1]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[0][2][2]));
            $display("\n\t3x3 MATRIX REGISTER[1] DUMP\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][0][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][0][1]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][0][2]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][1][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][1][1]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][1][2]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][2][0]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][2][1]),
                        $bitstoshortreal(mpu_top.matrix_register_file.matrix_register_array[1][2][2]));
        end
*/


        $finish;
    end : main_test_sequence

endmodule : mpu_load_store_tb
