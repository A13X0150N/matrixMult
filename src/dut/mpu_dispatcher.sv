// mpu_dispatcher.sv

import global_defs::*;
import mpu_data_types::*;

module mpu_dispatcher 
(
    // Control signals
    input  clk,                                             // Clock
    input  rst,                                             // Synchronous reset active high
    input  bit disp_start_in,                               // Start distributing data signal
    output bit disp_ack_out,                                // Signal data distribution started
    output bit disp_finished_out,                           // Signal finished dispatching

    // To matrix register file
    output bit [MBITS:0] reg_disp_0_i_out,                  // Dispatcher output row location
    output bit [NBITS:0] reg_disp_0_j_out,                  // Dispatcher output column location
    output bit [MBITS:0] reg_disp_1_i_out,                  // Dispatcher output row location
    output bit [NBITS:0] reg_disp_1_j_out,                  // Dispatcher output column location
    input  float_sp reg_disp_element_0_in,                  // Dispatcher element 0 input
    input  float_sp reg_disp_element_1_in,                  // Dispatcher element 1 input

    // To FMA cluster
    input  bit  busy_0_0_in, busy_0_1_in, busy_0_2_in, 
                busy_1_0_in,              busy_1_2_in,
                busy_2_0_in, busy_2_1_in, busy_2_2_in,

    output bit  float_0_req_0_0_out, float_0_req_0_2_out,
                float_0_req_1_0_out, float_0_req_1_2_out,
                float_0_req_2_0_out, float_0_req_2_2_out,

    output bit  float_1_req_0_0_out, float_1_req_0_1_out, float_1_req_0_2_out,
                float_1_req_2_0_out, float_1_req_2_1_out, float_1_req_2_2_out,

    output float_sp float_0_data_0_0_out, float_0_data_0_2_out,
                    float_0_data_1_0_out, float_0_data_1_2_out,
                    float_0_data_2_0_out, float_0_data_2_2_out,

    output float_sp float_1_data_0_0_out, float_1_data_0_1_out, float_1_data_0_2_out,
                    float_1_data_2_0_out, float_1_data_2_1_out, float_1_data_2_2_out
);

    disp_state_e state, next_state;
    bit [MBITS:0] float_0_i;
    bit [NBITS:0] float_0_j;
    bit [MBITS:0] float_1_i;
    bit [NBITS:0] float_1_j;
    bit finished;
    bit cluster_free;
    bit time_to_wait;

    // Request out signals
    bit float_0_req_0;
    bit float_0_req_1;
    bit float_0_req_2;
    bit float_1_req_0;
    bit float_1_req_1;
    bit float_1_req_2;

    // Data out signals
    float_sp float_0_data_0;
    float_sp float_0_data_1;
    float_sp float_0_data_2;
    float_sp float_1_data_0;
    float_sp float_1_data_1;
    float_sp float_1_data_2;

    // Matrix register index load locations
    assign reg_disp_0_i_out = float_0_i;
    assign reg_disp_0_j_out = float_0_j;
    assign reg_disp_1_i_out = float_1_i;
    assign reg_disp_1_j_out = float_1_j;

    // Assign output partners for the FMA cluster
    assign float_0_req_0_0_out = float_0_req_0;
    assign float_0_req_0_2_out = float_0_req_0;
    assign float_0_req_1_0_out = float_0_req_1;
    assign float_0_req_1_2_out = float_0_req_1;
    assign float_0_req_2_0_out = float_0_req_2;
    assign float_0_req_2_2_out = float_0_req_2;
    assign float_1_req_0_0_out = float_1_req_0;
    assign float_1_req_2_0_out = float_1_req_0;
    assign float_1_req_0_1_out = float_1_req_1;
    assign float_1_req_2_1_out = float_1_req_1;
    assign float_1_req_0_2_out = float_1_req_2;
    assign float_1_req_2_2_out = float_1_req_2;

    assign float_0_data_0_0_out = float_0_data_0;
    assign float_0_data_0_2_out = float_0_data_0;
    assign float_0_data_1_0_out = float_0_data_1;
    assign float_0_data_1_2_out = float_0_data_1;
    assign float_0_data_2_0_out = float_0_data_2;
    assign float_0_data_2_2_out = float_0_data_2;
    assign float_1_data_0_0_out = float_1_data_0;
    assign float_1_data_2_0_out = float_1_data_0;
    assign float_1_data_0_1_out = float_1_data_1;
    assign float_1_data_2_1_out = float_1_data_1;
    assign float_1_data_0_2_out = float_1_data_2;
    assign float_1_data_2_2_out = float_1_data_2;

    // Determine if the FMA cluster can receive new input
    assign cluster_free = ~(busy_0_0_in | busy_0_1_in | busy_0_2_in | busy_1_0_in | busy_1_2_in | busy_2_0_in | busy_2_1_in | busy_2_2_in);
    
    // Determine if it is time to wait for the next vector to load
    assign time_to_wait = (float_0_i == M-1);

    // Acknowledge that the dispatcher has began to work on a task
    assign disp_ack_out = (state != DISP_IDLE);

    // Track when the float dispatching is complete 
    assign finished = (float_0_i == M-1) & !float_0_j;
    assign disp_finished_out = finished;

    // Matrix indexing
    always_ff @(posedge clk) begin
        if (rst) begin
            float_0_i <= '0;
            float_0_j <= N-1;
            float_1_i <= M-1;
            float_1_j <= '0;
        end
        else begin
            unique case (state)
                DISP_IDLE: begin
                    float_0_i <= '0;
                    float_0_j <= N-1;
                    float_1_i <= M-1;
                    float_1_j <= '0;
                end
                DISP_MATRIX: begin
                    if (finished) begin
                        float_0_i <= float_0_i;
                        float_0_j <= float_0_j;
                        float_1_i <= float_1_i;
                        float_1_j <= float_1_j;
                    end
                    else if (time_to_wait) begin
                        float_0_i <= '0;
                        float_0_j <= float_0_j - 1;
                        float_1_i <= float_1_i - 1;
                        float_1_j <= '0;
                    end
                    else begin
                        float_0_i <= float_0_i + 1;
                        float_0_j <= float_0_j;
                        float_1_i <= float_1_i;
                        float_1_j <= float_1_j + 1;
                    end
                end
                DISP_WAIT: begin
                    float_0_i <= float_0_i;
                    float_0_j <= float_0_j;
                    float_1_i <= float_1_i;
                    float_1_j <= float_1_j;
                end
            endcase
        end
    end

    // State machine driver
    always_ff @(posedge clk) begin
        state <= rst ? DISP_IDLE : next_state;
    end

    // Next-state logic
    always_comb begin
        unique case (state)
            DISP_IDLE: begin
                if (disp_start_in & cluster_free) begin
                    next_state <= DISP_MATRIX;
                end
                else begin
                    next_state <= DISP_IDLE;
                end
            end
            DISP_MATRIX: begin
                if (finished) begin
                    next_state <= DISP_IDLE;
                end
                else if (time_to_wait) begin
                    next_state <= DISP_WAIT;
                end
                else begin
                    next_state <= DISP_MATRIX;
                end
            end
            DISP_WAIT: begin
                if (finished) begin
                    next_state <= DISP_IDLE;
                end
                else if (cluster_free) begin
                    next_state <= DISP_MATRIX;
                end
                else begin
                    next_state <= DISP_WAIT;
                end
            end
        endcase
    end

    // Output logic
    always_ff @(posedge clk) begin
        if (rst) begin
            float_0_req_0 <= FALSE;
            float_0_req_1 <= FALSE;
            float_0_req_2 <= FALSE;
            float_1_req_0 <= FALSE;
            float_1_req_1 <= FALSE;
            float_1_req_2 <= FALSE;
            float_0_data_0 <= '0;
            float_0_data_1 <= '0;
            float_0_data_2 <= '0;
            float_1_data_0 <= '0;
            float_1_data_1 <= '0;
            float_1_data_2 <= '0;
        end
        else begin
            unique case (state)
                DISP_IDLE: begin
                    float_0_req_0 <= FALSE;
                    float_0_req_1 <= FALSE;
                    float_0_req_2 <= FALSE;
                    float_1_req_0 <= FALSE;
                    float_1_req_1 <= FALSE;
                    float_1_req_2 <= FALSE;
                    float_0_data_0 <= '0;
                    float_0_data_1 <= '0;
                    float_0_data_2 <= '0;
                    float_1_data_0 <= '0;
                    float_1_data_1 <= '0;
                    float_1_data_2 <= '0;
                end
                DISP_MATRIX: begin
                    if (float_0_i == 0) begin
                        float_0_req_0 <= TRUE;
                        float_0_req_1 <= FALSE;
                        float_0_req_2 <= FALSE;
                        float_1_req_0 <= TRUE;
                        float_1_req_1 <= FALSE;
                        float_1_req_2 <= FALSE;
                        float_0_data_0 <= reg_disp_element_0_in;
                        float_0_data_1 <= '0;
                        float_0_data_2 <= '0;
                        float_1_data_0 <= reg_disp_element_1_in;
                        float_1_data_1 <= '0;
                        float_1_data_2 <= '0;
                    end
                    else if (float_0_i == 1) begin
                        float_0_req_0 <= FALSE;
                        float_0_req_1 <= TRUE;
                        float_0_req_2 <= FALSE;
                        float_1_req_0 <= FALSE;
                        float_1_req_1 <= TRUE;
                        float_1_req_2 <= FALSE;
                        float_0_data_0 <= '0;
                        float_0_data_1 <= reg_disp_element_0_in;
                        float_0_data_2 <= '0;
                        float_1_data_0 <= '0;
                        float_1_data_1 <= reg_disp_element_1_in;
                        float_1_data_2 <= '0;
                    end
                    else if (float_0_i == 2) begin
                        float_0_req_0 <= FALSE;
                        float_0_req_1 <= FALSE;
                        float_0_req_2 <= TRUE;
                        float_1_req_0 <= FALSE;
                        float_1_req_1 <= FALSE;
                        float_1_req_2 <= TRUE;
                        float_0_data_0 <= '0;
                        float_0_data_1 <= '0;
                        float_0_data_2 <= reg_disp_element_0_in;
                        float_1_data_0 <= '0;
                        float_1_data_1 <= '0;
                        float_1_data_2 <= reg_disp_element_1_in;
                    end
                    else begin
                        float_0_req_0 <= FALSE;
                        float_0_req_1 <= FALSE;
                        float_0_req_2 <= FALSE;
                        float_1_req_0 <= FALSE;
                        float_1_req_1 <= FALSE;
                        float_1_req_2 <= FALSE;
                        float_0_data_0 <= '0;
                        float_0_data_1 <= '0;
                        float_0_data_2 <= '0;
                        float_1_data_0 <= '0;
                        float_1_data_1 <= '0;
                        float_1_data_2 <= '0;
                    end
                end
                DISP_WAIT: begin
                    float_0_req_0 <= FALSE;
                    float_0_req_1 <= FALSE;
                    float_0_req_2 <= FALSE;
                    float_1_req_0 <= FALSE;
                    float_1_req_1 <= FALSE;
                    float_1_req_2 <= FALSE;
                    float_0_data_0 <= '0;
                    float_0_data_1 <= '0;
                    float_0_data_2 <= '0;
                    float_1_data_0 <= '0;
                    float_1_data_1 <= '0;
                    float_1_data_2 <= '0;
                end
            endcase
        end
    end

endmodule : mpu_dispatcher
