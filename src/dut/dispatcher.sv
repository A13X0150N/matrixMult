// dispatcher.sv

module dispatcher 
(
    input   clk,                                    // Clock
    input   rst,                                    // Synchronous reset active high
    input   start_in,                               // Start distributing data signal
    output  finished_out,                           // Finished data distribution signal

    // To matrix register file
    input bit disp_ready_in,                               // Dispatcher load ready sync signal
    output reg_disp_en_out,                                // Dispatcher load request
    output bit [MATRIX_REG_BITS:0] reg_disp_addr_0_out,    // Multiplicand address
    output bit [MATRIX_REG_BITS:0] reg_disp_addr_1_out,    // Multipier address
    output bit [MBITS:0] reg_disp_0_i_out,                 // Dispatcher output row location
    output bit [NBITS:0] reg_disp_0_j_out,                 // Dispatcher output column location
    output bit [MBITS:0] reg_disp_1_i_out,                 // Dispatcher output row location
    output bit [NBITS:0] reg_disp_1_j_out,                 // Dispatcher output column location
    input  float_sp reg_disp_element_0_in,                 // Dispatcher element 0 input
    input  float_sp reg_disp_element_1_in,                 // Dispatcher element 1 input

    // To FMA cluster
    input   busy_0_0_in, busy_0_1_in, busy_0_2_in, 
            busy_1_0_in,              busy_1_2_in,
            busy_2_0_in, busy_2_1_in, busy_2_2_in,

    output  float_0_req_0_0_out, float_0_req_0_2_out,
            float_0_req_1_0_out, float_0_req_1_2_out,
            float_0_req_2_0_out, float_0_req_2_2_out,

    output  float_1_req_0_0_out, float_1_req_0_1_out, float_1_req_0_2_out,
            float_1_req_2_0_out, float_1_req_2_1_out, float_1_req_2_2_out,

    output float_sp float_0_data_0_0_out, float_0_data_0_2_out,
                    float_0_data_1_0_out, float_0_data_1_2_out,
                    float_0_data_2_0_out, float_0_data_2_2_out,

    output float_sp float_1_data_0_0_out, float_1_data_0_1_out, float_1_data_0_2_out,
                    float_1_data_2_0_out, float_1_data_2_1_out, float_1_data_2_2_out,
);









endmodule : dispatcher
