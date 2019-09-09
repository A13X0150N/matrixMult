// coverage_tb.sv

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// Coverage defines the scope of the verification
class coverage_tb;

    virtual mpu_bfm bfm;

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

    function new (virtual mpu_bfm b);
        this.bfm = b;
        //this.mpu_load = new();
        //this.mpu_store = new();
        //this.mpu_mult = new();
    endfunction : new

    task execute();
        //$display("coverage_h.execute()");
    endtask : execute

endclass : coverage_tb
