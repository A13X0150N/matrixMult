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
import mpu_data_types::*;

interface fpu_bfm(input clk, rst);
// pragma attribute fpu_bfm partition_interface_xif

    bit start;
    bit error;
    bit ready;    
    float_sp float_in;
    float_sp float_out;

    // Wait for reset task.
    task wait_for_reset(); // pragma tbx xtf
        @(negedge rst);
        //$display("rst: %b", rst);
        start <= FALSE;
        float_in <= '0;
    endtask

    // Send an operation into the FPU
    task send_op(input fpu_data_sp req, output fpu_data_sp rsp); // pragma tbx xtf
        @(posedge clk); // For a task to be synthesizable for veloce, it must be a clocked task
        case(req.op)

            FPU_NOP: begin
                @(posedge clk);
            end

            FPU_FMA: begin
                @(posedge clk);
                start <= TRUE;
                float_in <= req.a;
                @(posedge clk);
                start <= FALSE;
                float_in <= req.b;
                @(posedge clk);
                float_in <= req.c;
                do begin
                    @(posedge clk);
                end while (!ready);
                rsp.y <= float_out;
                @(posedge clk);
            end

            FPU_MULTIPLY: begin
                @(posedge clk);
            end

            FPU_ADD: begin
                @(posedge clk);
            end

        endcase
    endtask

endinterface : fpu_bfm
