// mpu_collector.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Floating point collector that writes the results collected from FMA cluster
// to the register file. The collector waits for an answer ready signal from
// the center of the cluster (last answer to arrive).
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;

module mpu_collector (
	input  clk,                                    // Clock
    input  rst,                                    // Synchronous reset active high
    output bit collector_finished,                 // Collector finished
    output bit collector_active_write_out,         // Collector is writing back to register file

    // To matrix register file
    output bit [MBITS:0] reg_collector_i_out,      // Collector input row location
    output bit [MBITS:0] reg_collector_j_out,      // Collector input column location
    output float_sp reg_collector_element_out,     // Collector element input

    // To FMA cluster
    input  float_sp result_0_0_in, result_0_1_in, result_0_2_in, result_0_3_in, result_0_4_in, result_0_5_in,
                    result_1_0_in, result_1_1_in, result_1_2_in, result_1_3_in, result_1_4_in, result_1_5_in,
                    result_2_0_in, result_2_1_in, result_2_2_in, result_2_3_in, result_2_4_in, result_2_5_in,
                    result_3_0_in, result_3_1_in, result_3_2_in, result_3_3_in, result_3_4_in, result_3_5_in,
                    result_4_0_in, result_4_1_in, result_4_2_in, result_4_3_in, result_4_4_in, result_4_5_in,
                    result_5_0_in, result_5_1_in, result_5_2_in, result_5_3_in, result_5_4_in, result_5_5_in,

    input  bit      ready_0_0_in, ready_0_1_in, ready_0_2_in, ready_0_3_in, ready_0_4_in, ready_0_5_in,
                    ready_1_0_in, ready_1_1_in, ready_1_2_in, ready_1_3_in, ready_1_4_in, ready_1_5_in,
                    ready_2_0_in, ready_2_1_in, ready_2_2_in, ready_2_3_in, ready_2_4_in, ready_2_5_in,
                    ready_3_0_in, ready_3_1_in, ready_3_2_in, ready_3_3_in, ready_3_4_in, ready_3_5_in,
                    ready_4_0_in, ready_4_1_in, ready_4_2_in, ready_4_3_in, ready_4_4_in, ready_4_5_in,
                    ready_5_0_in, ready_5_1_in, ready_5_2_in, ready_5_3_in, ready_5_4_in, ready_5_5_in,

    input  bit error_detected_in                    // Detect an error on the input
);

collector_state_e state, next_state;                // Collector state
bit write_to_memory;                                // Signal to track when to start the memory write
bit write_finished;                                 // Signal finished writing to memory
bit [MBITS:0] dest_i;                               // Destination i location
bit [MBITS:0] dest_i_delay;                         // Destination i location delay
bit [NBITS:0] dest_j;                               // Destination j location
bit [NBITS:0] dest_j_delay;                         // Destination j location delay
float_sp buffer [M][N];                             // pragma attribute buffer logic_block 1
bit ready [M*N];                                    // Array of unit read signals

// Write delayed signals
always_ff @(posedge clk) begin
    if (rst) begin
        dest_i_delay <= '0;
        dest_j_delay <= '0;
    end
    else begin
        dest_i_delay <= dest_i;
        dest_j_delay <= dest_j;
    end
end

assign write_finished = (dest_i_delay == M-1) & (dest_j_delay == N-1);
assign collector_finished = write_finished;
assign reg_collector_i_out = dest_i_delay;
assign reg_collector_j_out = dest_j_delay;
assign ready[0] = ready_0_0_in;
assign ready[1] = ready_0_1_in;
assign ready[2] = ready_0_2_in;
assign ready[3] = ready_0_3_in;
assign ready[4] = ready_0_4_in;
assign ready[5] = ready_0_5_in;
assign ready[6] = ready_1_0_in;
assign ready[7] = ready_1_1_in;
assign ready[8] = ready_1_2_in;
assign ready[9] = ready_1_3_in;
assign ready[10] = ready_1_4_in;
assign ready[11] = ready_1_5_in;
assign ready[12] = ready_2_0_in;
assign ready[13] = ready_2_1_in;
assign ready[14] = ready_2_2_in;
assign ready[15] = ready_2_3_in;
assign ready[16] = ready_2_4_in;
assign ready[17] = ready_2_5_in;
assign ready[18] = ready_3_0_in;
assign ready[19] = ready_3_1_in;
assign ready[20] = ready_3_2_in;
assign ready[21] = ready_3_3_in;
assign ready[22] = ready_3_4_in;
assign ready[23] = ready_3_5_in;
assign ready[24] = ready_4_0_in;
assign ready[25] = ready_4_1_in;
assign ready[26] = ready_4_2_in;
assign ready[27] = ready_4_3_in;
assign ready[28] = ready_4_4_in;
assign ready[29] = ready_4_5_in;
assign ready[30] = ready_5_0_in;
assign ready[31] = ready_5_1_in;
assign ready[32] = ready_5_2_in;
assign ready[33] = ready_5_3_in;
assign ready[34] = ready_5_4_in;
assign ready[35] = ready_5_5_in;

// Capture output of FMA cluster into buffer
always_ff @(posedge clk) begin
    if (rst) begin
        write_to_memory <= FALSE;
        buffer[0][0] <= '0;
        buffer[0][1] <= '0;
        buffer[0][2] <= '0;
        buffer[0][3] <= '0;
        buffer[0][4] <= '0;
        buffer[0][5] <= '0;
        buffer[1][0] <= '0;
        buffer[1][1] <= '0;
        buffer[1][2] <= '0;
        buffer[1][3] <= '0;
        buffer[1][4] <= '0;
        buffer[1][5] <= '0;
        buffer[2][0] <= '0;
        buffer[2][1] <= '0;
        buffer[2][2] <= '0;
        buffer[2][3] <= '0;
        buffer[2][4] <= '0;
        buffer[2][5] <= '0;
        buffer[3][0] <= '0;
        buffer[3][1] <= '0;
        buffer[3][2] <= '0;
        buffer[3][3] <= '0;
        buffer[3][4] <= '0;
        buffer[3][5] <= '0;
        buffer[4][0] <= '0;
        buffer[4][1] <= '0;
        buffer[4][2] <= '0;
        buffer[4][3] <= '0;
        buffer[4][4] <= '0;
        buffer[4][5] <= '0;
        buffer[5][0] <= '0;
        buffer[5][1] <= '0;
        buffer[5][2] <= '0;
        buffer[5][3] <= '0;
        buffer[5][4] <= '0;
        buffer[5][5] <= '0;
    end
    else begin
        write_to_memory <= FALSE;
        if (ready_0_0_in) buffer[0][0] <= result_0_0_in;
        if (ready_0_1_in) buffer[0][1] <= result_0_1_in;
        if (ready_0_2_in) buffer[0][2] <= result_0_2_in;
        if (ready_0_3_in) buffer[0][3] <= result_0_3_in;
        if (ready_0_4_in) buffer[0][4] <= result_0_4_in;
        if (ready_0_5_in) buffer[0][5] <= result_0_5_in;
        if (ready_1_0_in) buffer[1][0] <= result_1_0_in;
        if (ready_1_1_in) buffer[1][1] <= result_1_1_in;
        if (ready_1_2_in) buffer[1][2] <= result_1_2_in;
        if (ready_1_3_in) buffer[1][3] <= result_1_3_in;
        if (ready_1_4_in) buffer[1][4] <= result_1_4_in;
        if (ready_1_5_in) buffer[1][5] <= result_1_5_in;
        if (ready_2_0_in) buffer[2][0] <= result_2_0_in;
        if (ready_2_1_in) buffer[2][1] <= result_2_1_in;
        // The center element is always last, so time to output
        if (ready_2_2_in) begin 
            buffer[2][2] <= result_2_2_in;
            write_to_memory <= TRUE;
        end
        if (ready_2_3_in) buffer[2][3] <= result_2_3_in;
        if (ready_2_4_in) buffer[2][4] <= result_2_4_in;
        if (ready_2_5_in) buffer[2][5] <= result_2_5_in;
        if (ready_3_0_in) buffer[3][0] <= result_3_0_in;
        if (ready_3_1_in) buffer[3][1] <= result_3_1_in;
        if (ready_3_2_in) buffer[3][2] <= result_3_2_in;
        if (ready_3_3_in) buffer[3][3] <= result_3_3_in;
        if (ready_3_4_in) buffer[3][4] <= result_3_4_in;
        if (ready_3_5_in) buffer[3][5] <= result_3_5_in;
        if (ready_4_0_in) buffer[4][0] <= result_4_0_in;
        if (ready_4_1_in) buffer[4][1] <= result_4_1_in;
        if (ready_4_2_in) buffer[4][2] <= result_4_2_in;
        if (ready_4_3_in) buffer[4][3] <= result_4_3_in;
        if (ready_4_4_in) buffer[4][4] <= result_4_4_in;
        if (ready_4_5_in) buffer[4][5] <= result_4_5_in;
        if (ready_5_0_in) buffer[5][0] <= result_5_0_in;
        if (ready_5_1_in) buffer[5][1] <= result_5_1_in;
        if (ready_5_2_in) buffer[5][2] <= result_5_2_in;
        if (ready_5_3_in) buffer[5][3] <= result_5_3_in;
        if (ready_5_4_in) buffer[5][4] <= result_5_4_in;
        if (ready_5_5_in) buffer[5][5] <= result_5_5_in;
    end
end

// State machine driver
always_ff @(posedge clk) begin
    state <= rst ? COLLECTOR_IDLE : next_state;
end

// Next state logic
always_comb begin
    unique case (state)
        COLLECTOR_IDLE: begin
            if (write_to_memory) begin
                next_state <= COLLECTOR_WRITE;
            end
            else begin
                next_state <= COLLECTOR_IDLE;
            end
        end
        COLLECTOR_WRITE: begin
            if (write_finished) begin
                next_state <= COLLECTOR_IDLE;
            end
            else begin
                next_state <= COLLECTOR_WRITE;
            end
        end
    endcase
end

// Incremental pointer logic
always_ff @(posedge clk) begin
    if (rst) begin
        dest_i <= '0;
        dest_j <= '0;
    end
    else begin
        unique case (state)
            COLLECTOR_IDLE: begin
                dest_i <= '0;
                dest_j <= '0;
            end
            COLLECTOR_WRITE: begin
                if (write_finished) begin
                    dest_i <= dest_i;
                    dest_j <= dest_j;
                end
                else if (dest_j == N-1) begin
                    dest_i <= dest_i + 1;
                    dest_j <= '0;
                end
                else begin
                    dest_i <= dest_i;
                    dest_j <= dest_j + 1;
                end
            end
        endcase
    end
end

// Output buffer to matrix register file
always_ff @(posedge clk) begin
    if (rst) begin
        collector_active_write_out <= FALSE;
        reg_collector_element_out <= '0;
    end
    else begin
        unique case (state)
            COLLECTOR_IDLE: begin
                collector_active_write_out <= FALSE;
                reg_collector_element_out <= '0;
            end
            COLLECTOR_WRITE: begin
                collector_active_write_out <= TRUE;
                reg_collector_element_out <= buffer[dest_i][dest_j];
            end
        endcase
    end
end

endmodule : mpu_collector
