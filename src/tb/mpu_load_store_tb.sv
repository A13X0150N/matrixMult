// mpu_load_store_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench to check the load and store ability of the design. Eventually
// migrate to UVM.

import global_defs::*;

module mpu_load_store_tb;

    import mpu_pkg::*;

    mpu_bfm mpu_bfm();

    mpu_register_file matrix_register_file (
        // Control signals
        .clk                    (mpu_bfm.clk),
        .rst                    (mpu_bfm.rst),
        .reg_load_en_in         (mpu_bfm.reg_load_en),
        .reg_store_en_in        (mpu_bfm.reg_store_en),

        // To MPU load
        .reg_load_addr_in       (mpu_bfm.reg_load_addr),
        .reg_load_element_in    (mpu_bfm.reg_load_element),         
        .reg_i_load_loc_in      (mpu_bfm.reg_i_load_loc),
        .reg_j_load_loc_in      (mpu_bfm.reg_j_load_loc),
        .reg_m_load_size_in     (mpu_bfm.reg_m_load_size),
        .reg_n_load_size_in     (mpu_bfm.reg_n_load_size),

        // To MPU store
        .reg_store_addr_in      (mpu_bfm.reg_store_addr),
        .reg_i_store_loc_in     (mpu_bfm.reg_i_store_loc),
        .reg_j_store_loc_in     (mpu_bfm.reg_j_store_loc),
        .reg_m_store_size_out   (mpu_bfm.reg_m_store_size),
        .reg_n_store_size_out   (mpu_bfm.reg_n_store_size),
        .reg_store_element_out  (mpu_bfm.reg_store_element)
    );

    // Move matrix from external memory into internal registers
    mpu_load load_dut (
        // Control signals
        .clk                    (mpu_bfm.clk),
        .rst                    (mpu_bfm.rst),
        .load_en_in             (mpu_bfm.load_en),

        // To memory
        .mem_load_element_in    (mpu_bfm.mem_load_element),
        .mem_m_load_size_in     (mpu_bfm.mem_m_load_size),
        .mem_n_load_size_in     (mpu_bfm.mem_n_load_size),
        .mem_load_addr_in       (mpu_bfm.mem_load_addr),
        .mem_load_error_out     (mpu_bfm.mem_load_error),
        .mem_load_ack_out       (mpu_bfm.mem_load_ack),

        // To matrix register file
        .reg_load_en_out        (mpu_bfm.reg_load_en),
        .reg_load_addr_out      (mpu_bfm.reg_load_addr),
        .reg_load_element_out   (mpu_bfm.reg_load_element),
        .reg_i_load_loc_out     (mpu_bfm.reg_i_load_loc),
        .reg_j_load_loc_out     (mpu_bfm.reg_j_load_loc),
        .reg_m_load_size_out    (mpu_bfm.reg_m_load_size),
        .reg_n_load_size_out    (mpu_bfm.reg_n_load_size)
    );

    // Move matrix from internal register out to memory
    mpu_store store_dut (
        // Control signals
        .clk                    (mpu_bfm.clk),
        .rst                    (mpu_bfm.rst),
        .store_en_in            (mpu_bfm.store_en),

        // To matrix register file
        .reg_store_element_in   (mpu_bfm.reg_store_element),
        .reg_m_store_size_in    (mpu_bfm.reg_m_store_size),
        .reg_n_store_size_in    (mpu_bfm.reg_n_store_size),
        .reg_store_en_out       (mpu_bfm.reg_store_en),
        .reg_i_store_loc_out    (mpu_bfm.reg_i_store_loc),
        .reg_j_store_loc_out    (mpu_bfm.reg_j_store_loc),
        .reg_store_addr_out     (mpu_bfm.reg_store_addr),        
        
        // To memory
        .mem_store_addr_in      (mpu_bfm.mem_store_addr),
        .mem_store_en_out       (mpu_bfm.mem_store_en),
        .mem_store_element_out  (mpu_bfm.mem_store_element),
        .mem_m_store_size_out   (mpu_bfm.mem_m_store_size),
        .mem_n_store_size_out   (mpu_bfm.mem_n_store_size)
    );

    // Test variables
    mpu_operation_t op;
    logic [FPBITS:0] in_matrix [NUM_ELEMENTS];
    logic [MBITS:0] in_m;
    logic [NBITS:0] in_n;
    logic [MATRIX_REG_BITS:0] matrix_addr1, matrix_addr2;

    initial $monitor("\n", (($time+(CLOCK_PERIOD/2))/CLOCK_PERIOD), " clock cycles\nmem_store_en: %b \noutdata: %f    M: %d    N: %d \n\n", 
                    mpu_bfm.mem_store_en, $bitstoshortreal(mpu_bfm.mem_store_element), mpu_bfm.mem_m_store_size,  mpu_bfm.mem_n_store_size);

    initial begin
        mpu_bfm.reset_mpu();
        
        op = NOP;
        in_m = M_MEM;
        in_n = N_MEM;
        matrix_addr1 = 0;
        matrix_addr2 = 1;
        foreach(in_matrix[i]) in_matrix[i] = '0;
        mpu_bfm.send_op(op, in_matrix, in_m, in_n, matrix_addr1, matrix_addr2);
        
        op = LOAD;
        in_matrix[0] = 32'h3f800000;        // 1.0
        in_matrix[1] = 32'h424951ec;        // 50.33
        in_matrix[2] = 32'hc0200000;        // -2.5
        in_matrix[3] = 32'h3e000000;        // 0.125          2x2 ends here
        in_matrix[4] = 32'hbeaaaa9f;        // 0.333333
        in_matrix[5] = 32'h4e932c06;        // 1234570000
        in_matrix[6] = 32'h00000000;        // 0.0
        in_matrix[7] = 32'hb6a7c5ac;        // -0.000005
        in_matrix[8] = 32'hd0132c06;        // -9876540000    3x3 ends here
        mpu_bfm.send_op(op, in_matrix, in_m, in_n, matrix_addr1, matrix_addr2);
        
        op = NOP;
        mpu_bfm.send_op(op, in_matrix, in_m, in_n, matrix_addr1, matrix_addr2);
        
        op = STORE;
        mpu_bfm.send_op(op, in_matrix, in_m, in_n, matrix_addr1, matrix_addr2);

        //Register dumep
        @(posedge mpu_bfm.clk);        
        if (NUM_ELEMENTS == 4) begin
            // 2x2 test
            $display("\n\t2x2 MATRIX REGISTER[0] DUMP\n\t %f\t%f \n\t %f\t%f \n", 
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][0][0]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][0][1]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][1][0]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][1][1]));
        end
        else if (NUM_ELEMENTS == 9) begin
            // 3x3 test
            $display("\n\t3x3 MATRIX REGISTER[0] DUMP\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][0][0]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][0][1]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][0][2]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][1][0]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][1][1]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][1][2]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][2][0]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][2][1]),
                        $bitstoshortreal(matrix_register_file.matrix_register_array[0][2][2]));
        end  
    end

endmodule : mpu_load_store_tb
