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

    // Control signals
    bit [NBITS:0] size;

    // Left connections
    float_sp float_left_in;      // Left float input
    bit      ready_left_in;      // Left input ready
    bit      ack_left_out;       // Signal ready to receive next left input

    // Up connections
    float_sp float_up_in;        // Up float input
    bit      ready_up_in;        // Signal up input ready
    bit      ack_up_out;         // Signal ready to receive next up input

    // Right connections
    float_sp float_right_out;    // Right float output
    bit      ack_right_out;      // Signal right output ready
    bit      ready_right_in;     // Signal ready to send next right input

    // Down connections
    float_sp float_down_out;     // Down float output
    bit      ack_down_out;       // Signal down output ready
    bit      ready_down_in;      // Signal ready to send next down input

    // Answer output
    float_sp float_answer_out;   // Answer float output
    bit      ready_answer_out;   // Signal answer output ready
    bit      error_out;           // Signal error detection output

    // Wait for reset task
    task wait_for_reset(); // pragma tbx xtf
        @(negedge rst);
        $display("rst: %b", rst);
        //start <= FALSE;
        //float_in <= '0;
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

                do begin
                    @(posedge clk);
                end while (!ready_answer_out);
                rsp.y <= error_out ? '1 : float_answer_out;
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
