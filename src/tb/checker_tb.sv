// checker_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench design checker. Uses a reference model with a set of identical
// matrix registers. Every interface transaction has a copy of placed in the
// mailbox and the result is sent in another mailbox to the scoreboard. Failing
// the checker means that the total accumulated difference of the design matrix
// result and the checker matrix result is greater than the tolerance defined
// in the testbench utilities package. Results are checked after a store.
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// The driver sends inputs into the bfm and checks results returned back
class checker_tb;

    virtual mpu_bfm bfm;                                    // Virtual BFM interface
    mailbox #(mpu_data_sp) driver2checker;                  // Mailbox to receive from driver
    mailbox checker2scoreboard;                             // Mailbox to send to scoreboard
    mpu_data_sp data;                                       // Interface data packet from mailbox
    int i, k, row, col;                                     // Various for-loop iterators
    shortreal sum;                                          // Sum of total error in a matrix
    float_sp ref_register_array [MATRIX_REGISTERS][M][N];   // Matrix Registers
    float_sp matrix_result [M][N];                          // Reference model result
    test_e test_result;                                     // Pass/Fail to send to scoreboard

    // Object instantiation
    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    // Reference model
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

