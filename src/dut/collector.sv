// collector.sv

module collector (
	input   clk,                                    // Clock
    input   rst,                                    // Synchronous reset active high

    // To matrix register file
    output bit [MATRIX_REG_BITS:0] reg_collector_addr_out,  // Collector operand address
    output bit [MBITS:0] reg_collector_i_out,               // Collector input row location
    output bit [MBITS:0] reg_collector_j_out,               // Collector input column location
    output float_sp reg_collector_element_out,              // Collector element input

    // To FMA cluster
    input float_sp  result_0_0_in, result_0_1_in, result_0_2_in,
                    result_1_0_in, result_1_1_in, result_1_2_in,
                    result_2_0_in, result_2_1_in, result_2_2_in, 

    input bit       ready_0_0_in, ready_0_1_in, ready_0_2_in,
                    ready_1_0_in, ready_1_1_in, ready_1_2_in,
                    ready_2_0_in, ready_2_1_in, ready_2_2_in

);





endmodule : collector
