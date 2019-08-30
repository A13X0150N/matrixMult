// mpu_collector.sv

module mpu_collector (
	input  clk,                                    // Clock
    input  rst,                                    // Synchronous reset active high

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
                    ready_2_0_in, ready_2_1_in, ready_2_2_in
);

collector_state_e state, next_state;
bit write_to_memory;
bit write_finished;
bit [MBITS:0] dest_i;
bit [NBITS:0] dest_j;
float_sp buffer [M][N];
bit ready [M*N];

assign write_finished = (dest_i == M-1) & (dest_j == N-1);
assign reg_collector_i_out = dest_i;
assign reg_collector_j_out = dest_j;
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
        foreach(buffer[i]) buffer[i] = '0;
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
            write_to_memory = TRUE;
        end
        if (ready_1_2_in) buffer[1][2] <= result_1_2_in;
        if (ready_2_0_in) buffer[2][0] <= result_2_0_in;
        if (ready_2_1_in) buffer[2][1] <= result_2_1_in;
        if (ready_2_2_in) buffer[2][2] <= result_2_2_in;
    end
end

// State machine driver
always_ff @(posedge clk) begin
    state <= rst ? COLLECTOR_IDLE : COLLECTOR_WRITE;
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
        reg_collector_element_out <= '0;
    end
    else begin
        unique case (state)
            COLLECTOR_IDLE: begin
                reg_collector_element_out <= '0;
            end
            COLLECTOR_WRITE: begin
                reg_collector_element_out <= buffer[dest_i][dest_j];
            end
        endcase
    end
end


endmodule : mpu_collector
