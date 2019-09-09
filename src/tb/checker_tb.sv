// checker_tb.sv

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// The driver sends inputs into the bfm and checks results returned back
class checker_tb;

    virtual mpu_bfm bfm;
    mailbox #(mpu_data_sp) driver2checker;
    mailbox checker2scoreboard;
    mpu_data_sp data;
    int i, k, row, col;
    shortreal sum;
    float_sp ref_register_array [MATRIX_REGISTERS][M][N];   // Matrix Registers
    float_sp matrix_result [M][N];
    test_e test_result;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        forever begin
            driver2checker.get(data);
            unique case (data.op)
                MPU_NOP: begin
                    ;
                end
                MPU_LOAD: begin
                    i = 0;
                    for (row = 0; row < M; ++row) begin
                        for (col = 0; col < N; ++col) begin
                            ref_register_array[data.src_addr_0][row][col] = data.matrix_in[i++];
                        end
                    end
                end
                MPU_STORE: begin
                    i = 0;
                    for (row = 0; row < M; ++row) begin
                        for (col = 0; col < N; ++col) begin
                            matrix_result[row][col] = data.matrix_out[i++];
                        end
                    end
                    test_result = check_result(data.src_addr_0);
                    checker2scoreboard.put(test_result);
                end
                MPU_MULT: begin
                    sim_matrix_mult(data.src_addr_0, data.src_addr_1, data.dest_addr);
                end
            endcase
        end
    endtask : execute

    // Simulate matrix multiplication
    task automatic sim_matrix_mult(input int src_addr_0, input int src_addr_1, input int dest_addr);
        for (row = 0; row < M; ++row) begin
            for (col = 0; col < N; ++col) begin
                sum = 0.0;
                for (k = 0; k < N; ++k) begin
                    sum = sum + $bitstoshortreal(ref_register_array[src_addr_0][row][k]) * $bitstoshortreal(ref_register_array[src_addr_1][k][col]);
                end
                ref_register_array[dest_addr][row][col] = $shortrealtobits(sum);
            end
        end
    endtask : sim_matrix_mult

    // Check if total error is within tolerance
    function automatic test_e check_result(input int addr);
        shortreal total_error = 0.0;
        shortreal error = 0.0;
        // Accumulate total error
        for (row = 0; row < M; ++row) begin
            for (col = 0; col < N; ++col) begin
                error = $bitstoshortreal(ref_register_array[addr][row][col]) - $bitstoshortreal(matrix_result[row][col]);
                if (error < 0.0) begin
                    total_error = total_error - error;
                end
                else begin
                    total_error = total_error + error;
                end
            end
        end
        // Check if combined error is within the acceptable range
        if (total_error > MAX_ERROR) begin
            check_result = FAIL;
        end
        else begin
            check_result = PASS;
        end
    endfunction : check_result

endclass : checker_tb

