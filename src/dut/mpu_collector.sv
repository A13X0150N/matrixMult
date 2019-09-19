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
    input  float_sp result_0_0_in, result_0_1_in, result_0_2_in,
                    result_1_0_in, result_1_1_in, result_1_2_in,
                    result_2_0_in, result_2_1_in, result_2_2_in, 

    input  bit      ready_0_0_in, ready_0_1_in, ready_0_2_in,
                    ready_1_0_in, ready_1_1_in, ready_1_2_in,
                    ready_2_0_in, ready_2_1_in, ready_2_2_in,

    input  bit error_detected_in                    // Detect an error on the input
);

collector_state_e state, next_state;                // Collector state
bit write_to_memory;                                // Signal to track when to start the memory write
bit write_finished;                                 // Signal finished writing to memory
bit [MBITS:0] dest_i;                               // Destination i location
bit [MBITS:0] dest_i_delay;                         // Destination i location delay
bit [NBITS:0] dest_j;                               // Destination j location
bit [NBITS:0] dest_j_delay;                         // Destination j location delay
float_sp buffer [M][N];                             // pragma attribute buffer ram_block 1
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
assign ready[3] = ready_1_0_in;
assign ready[4] = ready_1_1_in;
assign ready[5] = ready_1_2_in;
assign ready[6] = ready_2_0_in;
assign ready[7] = ready_2_1_in;
assign ready[8] = ready_2_2_in;

// Capture output of FMA cluster into buffer
always_ff @(posedge clk) begin
    if (rst) begin
        write_to_memory <= FALSE;
        buffer[0][0] <= '0;
        buffer[0][1] <= '0;
        buffer[0][2] <= '0;
        buffer[1][0] <= '0;
        buffer[1][1] <= '0;
        buffer[1][2] <= '0;
        buffer[2][0] <= '0;
        buffer[2][1] <= '0;
        buffer[2][2] <= '0;
    end
    else begin
        write_to_memory <= FALSE;
        if (ready_0_0_in) buffer[0][0] <= result_0_0_in;
        if (ready_0_1_in) buffer[0][1] <= result_0_1_in;
        if (ready_0_2_in) buffer[0][2] <= result_0_2_in;
        if (ready_1_0_in) buffer[1][0] <= result_1_0_in;
        // The center element is always last, so time to output
        if (ready_1_1_in) begin 
            buffer[1][1] <= result_1_1_in;
            write_to_memory <= TRUE;
        end
        if (ready_1_2_in) buffer[1][2] <= result_1_2_in;
        if (ready_2_0_in) buffer[2][0] <= result_2_0_in;
        if (ready_2_1_in) buffer[2][1] <= result_2_1_in;
        if (ready_2_2_in) buffer[2][2] <= result_2_2_in;
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
