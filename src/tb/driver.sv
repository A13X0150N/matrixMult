// driver.sv

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// The driver sends inputs into the bfm and checks results returned back
class driver;

    virtual mpu_bfm bfm;
    mpu_data_sp data_in, data_out;
    int i;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        $display("tester_h.execute()");
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = '0;
        foreach(data_in.matrix_in[i]) data_in.matrix_in[i] = '0;
        data_in.op = MPU_NOP;
        bfm.send_op(data_in, data_out);

        generate_matrix(1.0, 100.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.src_addr_0 = 0;
        $display("\tMatrix [%1d] LOAD", 0);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        generate_matrix(20.0, 0.001, data_in);
        data_in.src_addr_0 = 1;
        $display("\tMatrix [%1d] LOAD", 1);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        generate_matrix(300.0, 2340000.4, data_in);
        data_in.src_addr_0 = 2;
        $display("\tMatrix [%1d] LOAD", 2);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        generate_matrix(-41.0, 100.0, data_in);
        data_in.src_addr_0 = 3;
        $display("\tMatrix [%1d] LOAD", 3);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        generate_matrix(-33331.0, 0.01, data_in);
        data_in.src_addr_0 = 4;
        $display("\tMatrix [%1d] LOAD", 4);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        generate_matrix(-0.005, 1076570.0, data_in);
        data_in.src_addr_0 = 5;
        $display("\tMatrix [%1d] LOAD", 5);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        generate_matrix(1.0, 1.0, data_in);
        data_in.src_addr_0 = 6;
        $display("\tMatrix [%1d] LOAD", 6);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        generate_matrix(1.0, 1.0, data_in);
        data_in.src_addr_0 = 7;
        $display("\tMatrix [%1d] LOAD", 7);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

        display_message("Operation: MULT");
        data_in.op = MPU_MULT;
        data_in.src_addr_0 = 6;
        data_in.src_addr_1 = 7;
        data_in.dest_addr = 5;
        bfm.send_op(data_in, data_out);

        display_message("Operation: STORE");
        data_in.op = MPU_STORE;
        for (i = 0; i < MATRIX_REGISTERS; ++i) begin
            data_in.src_addr_0 = i;
            bfm.send_op(data_in, data_out);
            $display("\tMatrix [%1d] STORE", i);
            show_matrix(data_out.matrix_out);
        end

        $display("Total coverage %0.2f %%", $get_coverage());

        $display("\n");
        display_message("End of Testbench");
        $display("\n");
        $finish;

    endtask : execute

endclass : driver
