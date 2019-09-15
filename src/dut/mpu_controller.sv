// mpu_controller.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Controller for interfacing memory with functional units
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;

module mpu_controller 
(
    // Control Signals
    input      clk,                                             // Clock
    input      rst,                                             // Reset signal
    input  bit start_mult_in,                                   // Signal valid addresses on input
    input  bit [MATRIX_REG_BITS:0] src_addr_0_in,               // Matrix address 0
    input  bit [MATRIX_REG_BITS:0] src_addr_1_in,               // Matrix address 1
    input  bit [MATRIX_REG_BITS:0] dest_addr_in,                // Destination register address
   
    // To Dispatcher
    input  bit disp_finished_in,                                // Dispatcher finished
    output bit disp_start_out,                                  // Clear to dispatch signal

    // To Collector
    input  bit collector_active_write_in,                       // Signal active collector write

    // To Matrix Register File
    input  bit collector_ready_in,                              // Collector store ready sync signal
    input  bit disp_ready_in,                                   // Dispatcher load ready sync signal
    output bit reg_collector_req_out,                           // Collector matrix write request 
    output bit reg_disp_req_out,                                // Dispatcher load request
    output bit [MATRIX_REG_BITS:0] reg_src_addr_0_out,          // Multiplicand address
    output bit [MATRIX_REG_BITS:0] reg_src_addr_1_out,          // Multipier address
    output bit [MATRIX_REG_BITS:0] reg_dest_addr_out            // Destination address
);

    bit start_mult;                                             // Signal to start multiplication process

    // Track when to toggle start mult signal
    always_ff @(posedge clk) begin
        if (rst) begin
            start_mult <= FALSE;
        end
        else begin
            if (start_mult_in) begin
                start_mult <= TRUE;
            end
            else if (disp_finished_in) begin
                start_mult <= FALSE;
            end
            else begin
                start_mult <= start_mult;
            end
        end
    end

    // Assign requested addresses to get read permission from register file
    assign reg_src_addr_0_out = src_addr_0_in;
    assign reg_src_addr_1_out = src_addr_1_in;
    assign reg_dest_addr_out = dest_addr_in;

    // Begin dispersion after registers are cleared for load and store
    assign disp_start_out = collector_ready_in & disp_ready_in & start_mult;

    // Collector/Dispatcher memory requests
    assign reg_collector_req_out = collector_active_write_in;
    assign reg_disp_req_out = start_mult;

endmodule : mpu_controller
