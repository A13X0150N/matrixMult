// driver_tb.sv

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// The driver sends inputs into the bfm and checks results returned back
class driver_tb;

    virtual mpu_bfm bfm;
    mailbox #(mpu_data_sp) driver2checker;
    mpu_data_sp data_in, data_out;
    int i;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        // Initialize request fields and start with a NOP
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = '0;
        foreach(data_in.matrix_in[i]) data_in.matrix_in[i] = '0;
        data_in.op = MPU_NOP;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(1.0, 100.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.src_addr_0 = 0;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(20.0, 0.001, data_in);
        data_in.src_addr_0 = 1;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(300.0, 2340000.4, data_in);
        data_in.src_addr_0 = 2;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(-41.0, 100.0, data_in);
        data_in.src_addr_0 = 3;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(-33331.0, 0.01, data_in);
        data_in.src_addr_0 = 4;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(-0.005, 1076570.0, data_in);
        data_in.src_addr_0 = 5;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(1.0, 1.0, data_in);
        data_in.src_addr_0 = 6;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        generate_matrix(1.0, 1.0, data_in);
        data_in.src_addr_0 = 7;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        data_in.op = MPU_MULT;
        data_in.src_addr_0 = 6;
        data_in.src_addr_1 = 7;
        data_in.dest_addr = 5;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        data_in.op = MPU_STORE;
        for (i = 0; i < MATRIX_REGISTERS; ++i) begin
            data_in.src_addr_0 = i;
            bfm.send_op(data_in, data_out);
            data_in.matrix_out = data_out.matrix_out;
            driver2checker.put(data_in);
        end

        data_in.op = MPU_NOP;
        bfm.send_op(data_in, data_out);
        driver2checker.put(data_in);

        $finish;
    endtask : execute

endclass : driver_tb
