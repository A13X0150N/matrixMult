// mpu_load_store_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench to check the load and store ability of the design.

import global_defs::*;
import mpu_data_types::*;

module mpu_load_store_tb;
    import testbench_utilities::*;

    // Test variables
    mpu_data_sp data_in, data_out;
    int i;

    // Stop the test after too many cycles have passed
    initial #(CLOCK_PERIOD*CYCLES) $finish;

    initial begin : main_test_sequence
        $display("\n\n\n");
        display_message("Beginning LOAD and STORE Testbench");

        mpu_top.mpu_bfm.wait_for_reset();
        display_message("Reset Complete");

        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = '0;
        foreach(data_in.matrix_in[i]) data_in.matrix_in[i] = '0;

        display_message("Test Matrix Dimensions");
        $display("\t %2d rows \n\t %2d columns", data_in.m_in, data_in.n_in);

        display_message("Operation: NOP");
        data_in.op = MPU_NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);
        
        display_message("Operation: LOAD");
        $display("\tGenerating and loading %2d matrices into MPU to fill internal matrix registers\n", MATRIX_REGISTERS);
        data_in.op = MPU_LOAD;

        generate_matrix(1.0, 100.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 0;
        $display("\tMatrix [%1d] LOAD", 0);
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(20.0, 0.001, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 1;
        $display("\tMatrix [%1d] LOAD", 1);
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(300.0, 2340000.4, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 2;
        $display("\tMatrix [%1d] LOAD", 2);
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(-41.0, 100.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 3;
        $display("\tMatrix [%1d] LOAD", 3);
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(-33331.0, 0.01, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 4;
        $display("\tMatrix [%1d] LOAD", 4);
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(-0.005, 1076570.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 5;
        $display("\tMatrix [%1d] LOAD", 5);
        show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(1.0, -1.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 6;
        $display("\tMatrix [%1d] LOAD", 6);
        show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(1.0, 1.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 7;
        $display("\tMatrix [%1d] LOAD", 7);
        show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        display_message("Operation: NOP");
        data_in.op = MPU_NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);
        simulation_register_dump(mpu_top.mpu_register_file.matrix_register_array);

        display_message("Operation: STORE");
        data_in.op = MPU_STORE;
        for (i = 0; i < MATRIX_REGISTERS; ++i) begin
            data_in.src_addr_0 = i;
            mpu_top.mpu_bfm.send_op(data_in, data_out);
            $display("\tMatrix [%1d] STORE", i);
            //show_matrix(data_out.matrix_out);
        end

        display_message("Operation: NOP");
        data_in.op = MPU_NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        display_message("Operation: MULT");
        data_in.op = MPU_MULT;
        data_in.src_addr_0 = 6;
        data_in.src_addr_1 = 7;
        data_in.dest_addr = 5;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        display_message("Operation: NOP");
        data_in.op = MPU_NOP;
        mpu_top.mpu_bfm.send_op(data_in, data_out);
        simulation_register_dump(mpu_top.mpu_register_file.matrix_register_array);

        $display("\n");
        display_message("End of LOAD and STORE Testbench");
        $display("\n");
        $finish;
    end : main_test_sequence

endmodule : mpu_load_store_tb
