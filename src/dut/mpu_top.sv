// mpu_top.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Top-level design for DUT and testbench. Eventually migrate to UVM.
 
import global_defs::*;
import mpu_data_types::*;

module mpu_top;
    import testbench_utilities::CLOCK_PERIOD;

    bit clk=0;      // System clock
    bit rst=0;      // Synchronous reset, active high

    // Interface
    mpu_bfm mpu_bfm(clk, rst);

    // Register file
    mpu_register_file matrix_register_file(
        // Control signals
        .clk                    (clk),
        .rst                    (rst),
        .reg_load_en_in         (mpu_bfm.reg_load_en),
        .reg_store_en_in        (mpu_bfm.reg_store_en),
        .load_ready_out         (mpu_bfm.load_ready),
        .store_ready_out        (mpu_bfm.store_ready),

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
    mpu_load load_dut(
        // Control signals
        .clk                    (clk),
        .rst                    (rst),
        .load_req_in            (mpu_bfm.load_req),

        // To memory
        .mem_load_element_in    (mpu_bfm.mem_load_element),
        .mem_m_load_size_in     (mpu_bfm.mem_m_load_size),
        .mem_n_load_size_in     (mpu_bfm.mem_n_load_size),
        .mem_load_addr_in       (mpu_bfm.mem_load_addr),
        .mem_load_error_out     (mpu_bfm.mem_load_error),
        .mem_load_ack_out       (mpu_bfm.mem_load_ack),

        // To matrix register file
        .load_ready_in          (mpu_bfm.load_ready),
        .reg_load_en_out        (mpu_bfm.reg_load_en),
        .reg_load_addr_out      (mpu_bfm.reg_load_addr),
        .reg_load_element_out   (mpu_bfm.reg_load_element),
        .reg_i_load_loc_out     (mpu_bfm.reg_i_load_loc),
        .reg_j_load_loc_out     (mpu_bfm.reg_j_load_loc),
        .reg_m_load_size_out    (mpu_bfm.reg_m_load_size),
        .reg_n_load_size_out    (mpu_bfm.reg_n_load_size)
    );

    // Move matrix from internal register out to memory
    mpu_store store_dut(
        // Control signals
        .clk                    (clk),
        .rst                    (rst),
        .store_req_in           (mpu_bfm.store_req),

        // To matrix register file
        .store_ready_in         (mpu_bfm.store_ready),
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
        .mem_m_store_size_out   (mpu_bfm.mem_m_store_size),
        .mem_n_store_size_out   (mpu_bfm.mem_n_store_size),
        .mem_store_element_out  (mpu_bfm.mem_store_element)
    );

    // Free running clock
    // tbx clkgen
    initial begin
        clk = 0;
        forever begin
          #(CLOCK_PERIOD/2) clk = ~clk;
        end
    end

    // Reset
    // tbx clkgen
    initial begin
        rst = 1;
        #(CLOCK_PERIOD*5) rst = 0;
    end

endmodule : mpu_top
