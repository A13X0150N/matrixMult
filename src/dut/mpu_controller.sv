// mpu_controller.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Controller for interfacing with memory with functional units

module mpu_controller 
(
    // Control Signals
    input  bit start_mult_in,									// Signal valid addresses on input
    input  bit [MATRIX_REG_BITS:0] src_addr0_in,                // Matrix address 0
    input  bit [MATRIX_REG_BITS:0] src_addr1_in,                // Matrix address 1
    input  bit [MATRIX_REG_BITS:0] dest_addr_in,     			// Destination register address
   
    // To Dispatcher
    output bit disp_start_out, 									// Clear to dispatch signal   

    // To matrix Register File
    input  bit reg_collector_ready_in,							// Collector store ready sync signal
    input  bit reg_disp_ready_in,                           	// Dispatcher load ready sync signal
    output bit reg_collector_req_out,                           // Collector matrix write request 
    output bit reg_disp_req_out,                             	// Dispatcher load request
    output bit [MATRIX_REG_BITS:0] reg_src_addr_0_out,     		// Multiplicand address
    output bit [MATRIX_REG_BITS:0] reg_src_addr_1_out,     		// Multipier address
    output bit [MATRIX_REG_BITS:0] reg_dest_addr_out,     		// Destination address
);

    // Assign requested addresses to get read permission from register file
    assign reg_src_addr_0_out = src_addr0_in;
    assign reg_src_addr_1_out = src_addr1_in;
	assign reg_dest_addr_out = dest_addr_in;

	// Begin dispersion after registers are cleared for load and store
	assign disp_start_out = reg_collector_ready_in & reg_disp_ready_in;

	// Collector/Dispatcher memory requests
	assign reg_collector_req_out = start_mult_in;
	assign reg_disp_req_out = start_mult_in;

endmodule : mpu_controller
