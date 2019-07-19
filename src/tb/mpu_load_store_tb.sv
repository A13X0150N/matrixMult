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
            32'h42de0000,        // 111.0
            32'h424951ec,        // 50.33
            32'hc0200000,        // -2.5
            32'h3e000000,        // 0.125          2x2 ends here
            32'hbeaaaa9f,        // 0.333333
            32'h4e932c06,        // 1234570000
            32'h00000000,        // 0.0
            32'hb6a7c5ac,        // -0.000005
            32'hd0132c06         // -9876540000    3x3 ends here
        };
        // Display the result of the first load command
        $display("\nMatrix 1 LOAD");
        show_matrix(data_in.matrix_in);
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
            $shortrealtobits(77777.0),
            $shortrealtobits(0.8),
            $shortrealtobits(9.0)
        };
        // Display the result of the second load command
        $display("\nMatrix 2 LOAD");
        show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        data_in.op = NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);
     
        data_in.op = STORE;
        data_in.matrix_addr = '0;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        // Display the result of the first store command
        $display("\nMatrix 1 STORE");
        show_matrix(data_out.matrix_out);

        data_in.op = STORE;
        data_in.matrix_addr = 1;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        // Display the result of the second store command
        $display("\nMatrix 2 STORE",);
        show_matrix(data_out.matrix_out);

        data_in.op = NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(data_in);
        show_matrix(data_in.matrix_in);

        $finish;
    end : main_test_sequence


    task generate_matrix(output mpu_data_t genmat);
        for (int i = 0; i < NUM_ELEMENTS; ++i) begin
            genmat.matrix_in = {(genmat.matrix_in), $shortrealtobits(1.0 + i) + i};
        end
    endtask : generate_matrix


    // Matrix Output
    task show_matrix(input bit [0:NUM_ELEMENTS-1][FPBITS:0] matrix_in);
        bit [FPBITS:0] matrix [NUM_ELEMENTS];
        {>>{matrix}} = matrix_in;
        if (NUM_ELEMENTS == 4) begin
            $display("\t2x2 MATRIX REGISTER\n\t %f\t%f \n\t %f\t%f \n", 
                        $bitstoshortreal(matrix[0]),
                        $bitstoshortreal(matrix[1]),
                        $bitstoshortreal(matrix[2]),
                        $bitstoshortreal(matrix[3]));
        end
        else if (NUM_ELEMENTS == 9) begin
            $display("\t3x3 MATRIX REGISTER\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                        $bitstoshortreal(matrix[0]),
                        $bitstoshortreal(matrix[1]),
                        $bitstoshortreal(matrix[2]),
                        $bitstoshortreal(matrix[3]),
                        $bitstoshortreal(matrix[4]),
                        $bitstoshortreal(matrix[5]),
                        $bitstoshortreal(matrix[6]),
                        $bitstoshortreal(matrix[7]),
                        $bitstoshortreal(matrix[8]));
        end
    endtask

endmodule : mpu_load_store_tb
