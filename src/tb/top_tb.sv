// top_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench to check the load and store ability of the design.

`include "src/tb/testbench.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

module top_tb;

    testbench testbench_h;

    initial begin
        testbench_h = new(mpu_top.mpu_bfm);
        testbench_h.execute();
    end
    
    initial #(CLOCK_PERIOD*MAX_CYCLES) $finish;   // Force finish after maximum cycles have passes

endmodule : top_tb

/*
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
        //data_in.m_in = M_MEM;
        //data_in.n_in = N_MEM;
        data_in.src_addr_0 = 0;
        $display("\tMatrix [%1d] LOAD", 0);
        //show_matrix(data_in.matrix_in);
        bfm.send_op(data_in, data_out);

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
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(1.0, 1.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 6;
        $display("\tMatrix [%1d] LOAD", 6);
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        generate_matrix(1.0, 1.0, data_in);
        data_in.op = MPU_LOAD;
        data_in.m_in = M_MEM;
        data_in.n_in = N_MEM;
        data_in.src_addr_0 = 7;
        $display("\tMatrix [%1d] LOAD", 7);
        //show_matrix(data_in.matrix_in);
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        display_message("Operation: MULT");
        data_in.op = MPU_MULT;
        data_in.src_addr_0 = 6;
        data_in.src_addr_1 = 7;
        data_in.dest_addr = 5;
        mpu_top.mpu_bfm.send_op(data_in, data_out);

        display_message("Operation: STORE");
        data_in.op = MPU_STORE;
        for (i = 0; i < MATRIX_REGISTERS; ++i) begin
            data_in.src_addr_0 = i;
            mpu_top.mpu_bfm.send_op(data_in, data_out);
            $display("\tMatrix [%1d] STORE", i);
            show_matrix(data_out.matrix_out);
        end

        $display("Total coverage %0.2f %%", $get_coverage());

        $display("\n");
        display_message("End of Testbench");
        $display("\n");
        $finish;

    endtask : execute

endclass : driver*/

/*
// Coverage defines the scope of the verification
class coverage;

    virtual mpu_bfm bfm;*/

   /* covergroup mpu_load @(posedge bfm.load_req);
        load_address: coverpoint bfm.mem_load_addr {
            bins addr_range[] = {[0:$]};
        }
    endgroup : mpu_load

    covergroup mpu_store @(posedge bfm.store_req);
        store_address: coverpoint bfm.mem_store_addr {
            bins addr_range[] = {[0:$]};
        }
    endgroup : mpu_store

    covergroup mpu_mult @(posedge bfm.start_mult);
        src_addr_0: coverpoint bfm.src_addr_0 {
            bins addr_range[] = {[0:$]};   
        }
        src_addr_1: coverpoint bfm.src_addr_1 {
            bins addr_range[] = {[0:$]};
        }
        dest_addr: coverpoint bfm.dest_addr {
            bins addr_range[] = {[0:$]};   
        }
        cross_addresses: cross src_addr_0, src_addr_1, dest_addr;
    endgroup : mpu_mult
*/

    /*function new (virtual mpu_bfm b);
        this.bfm = b;
        //this.mpu_load = new();
        //this.mpu_store = new();
        //this.mpu_mult = new();
    endfunction : new

    task execute();
        $display("coverage_h.execute()");
    endtask : execute

endclass : coverage*/



/*// Scoreboard tracks bugs that are discovered and tests that are passed
class scoreboard;

    virtual mpu_bfm bfm;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        $display("scoreboard_h.execute()");
    endtask : execute

endclass : scoreboard*/


/*// Top-level testbench
class testbench;

    virtual mpu_bfm bfm;

    tester tester_h;
    coverage coverage_h;
    scoreboard scoreboard_h;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        mpu_top.mpu_bfm.wait_for_reset();
        display_message("Reset Complete");
        $display("\n\n\n");
        display_message("Beginning Top-Level Testbench");
        this.tester_h = new(bfm);
        this.coverage_h = new(bfm);
        this.scoreboard_h = new(bfm);
        fork
            this.tester_h.execute();
            this.coverage_h.execute();
            this.scoreboard_h.execute();
        join_none
    endtask : execute

endclass : testbench*/

