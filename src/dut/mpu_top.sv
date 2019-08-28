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
    mpu_bfm mpu_bfm(.clk(clk), .rst(rst));


    // Register file
    mpu_register_file matrix_register_file(
        // Control Signals
        .clk                        (clk),
        .rst                        (rst),
        .reg_load_en_in             (mpu_bfm.reg_load_en),
        .reg_store_en_in            (mpu_bfm.reg_store_en),
        .load_ready_out             (mpu_bfm.load_ready),
        .store_ready_out            (mpu_bfm.store_ready),
        .collector_ready_out        (),
        .disp_ready_out             (),   

        // To MPU Load
        .reg_load_addr_in           (mpu_bfm.reg_load_addr),
        .reg_load_element_in        (mpu_bfm.reg_load_element),         
        .reg_i_load_loc_in          (mpu_bfm.reg_i_load_loc),
        .reg_j_load_loc_in          (mpu_bfm.reg_j_load_loc),
        .reg_m_load_size_in         (mpu_bfm.reg_m_load_size),
        .reg_n_load_size_in         (mpu_bfm.reg_n_load_size),

        // To MPU Store
        .reg_store_addr_in          (mpu_bfm.reg_store_addr),
        .reg_i_store_loc_in         (mpu_bfm.reg_i_store_loc),
        .reg_j_store_loc_in         (mpu_bfm.reg_j_store_loc),
        .reg_m_store_size_out       (mpu_bfm.reg_m_store_size),
        .reg_n_store_size_out       (mpu_bfm.reg_n_store_size),
        .reg_store_element_out      (mpu_bfm.reg_store_element),

        // To Dispatcher
        .reg_disp_addr_0_in         (),
        .reg_disp_addr_1_in         (), 
        .reg_disp_0_i_in            (),
        .reg_disp_0_j_in            (),
        .reg_disp_1_i_in            (),
        .reg_disp_1_j_in            (),
        .reg_disp_element_0_out     (),
        .reg_disp_element_1_out     (),

        // To Collector
        .reg_collector_addr_in      (),
        .reg_collector_i_in         (),
        .reg_collector_j_in         (),
        .reg_collector_element_in   ()

    );


    // Move matrix from external memory into internal registers
    mpu_load mpu_load(
        // Control signals
        .clk                        (clk),
        .rst                        (rst),
        .load_req_in                (mpu_bfm.load_req),

        // To memory
        .mem_load_element_in        (mpu_bfm.mem_load_element),
        .mem_m_load_size_in         (mpu_bfm.mem_m_load_size),
        .mem_n_load_size_in         (mpu_bfm.mem_n_load_size),
        .mem_load_addr_in           (mpu_bfm.mem_load_addr),
        .mem_load_error_out         (mpu_bfm.mem_load_error),
        .mem_load_ack_out           (mpu_bfm.mem_load_ack),

        // To matrix register file
        .load_ready_in              (mpu_bfm.load_ready),
        .reg_load_en_out            (mpu_bfm.reg_load_en),
        .reg_load_addr_out          (mpu_bfm.reg_load_addr),
        .reg_load_element_out       (mpu_bfm.reg_load_element),
        .reg_i_load_loc_out         (mpu_bfm.reg_i_load_loc),
        .reg_j_load_loc_out         (mpu_bfm.reg_j_load_loc),
        .reg_m_load_size_out        (mpu_bfm.reg_m_load_size),
        .reg_n_load_size_out        (mpu_bfm.reg_n_load_size)
    );


    // Move matrix from internal register out to memory
    mpu_store mpu_store(
        // Control signals
        .clk                        (clk),
        .rst                        (rst),
        .store_req_in               (mpu_bfm.store_req),

        // To matrix register file
        .store_ready_in             (mpu_bfm.store_ready),
        .reg_store_element_in       (mpu_bfm.reg_store_element),
        .reg_m_store_size_in        (mpu_bfm.reg_m_store_size),
        .reg_n_store_size_in        (mpu_bfm.reg_n_store_size),
        .reg_store_en_out           (mpu_bfm.reg_store_en),
        .reg_i_store_loc_out        (mpu_bfm.reg_i_store_loc),
        .reg_j_store_loc_out        (mpu_bfm.reg_j_store_loc),
        .reg_store_addr_out         (mpu_bfm.reg_store_addr),        

        // To memory
        .mem_store_addr_in          (mpu_bfm.mem_store_addr),
        .mem_store_en_out           (mpu_bfm.mem_store_en),
        .mem_m_store_size_out       (mpu_bfm.mem_m_store_size),
        .mem_n_store_size_out       (mpu_bfm.mem_n_store_size),
        .mem_store_element_out      (mpu_bfm.mem_store_element)
    );


    // Dipatch matrix elements into exectuion cluster
    dipatcher dispatcher(
        // Control Signals
        .clk                        (clk),
        .rst                        (rst),
        .start_in                   (),
        .finished_out               (),

        // To matrix register file
        .disp_ready_in              (),
        .reg_disp_en_out            (),
        .reg_disp_addr_0_out        (),
        .reg_disp_addr_1_out        (),
        .reg_disp_0_i_out           (),
        .reg_disp_0_j_out           (),
        .reg_disp_1_i_out           (),
        .reg_disp_1_j_out           (),
        .reg_disp_element_0_in      (),
        .reg_disp_element_1_in      (),

        // To FMA cluster
        .busy_0_0_in                (),
        .busy_0_1_in                (),
        .busy_0_2_in                (), 
        .busy_1_0_in                (),
        .busy_1_2_in                (),
        .busy_2_0_in                (),
        .busy_2_1_in                (),
        .busy_2_2_in                (),

        .float_0_req_0_0_out        (),
        .float_0_req_0_2_out        (),
        .float_0_req_1_0_out        (),
        .float_0_req_1_2_out        (),
        .float_0_req_2_0_out        (),
        .float_0_req_2_2_out        (),

        .float_1_req_0_0_out        (),
        .float_1_req_0_1_out        (),
        .float_1_req_0_2_out        (),
        .float_1_req_2_0_out        (),
        .float_1_req_2_1_out        (),
        .float_1_req_2_2_out        (),

        .float_0_data_0_0_out       (),
        .float_0_data_0_2_out       (),
        .float_0_data_1_0_out       (),
        .float_0_data_1_2_out       (),
        .float_0_data_2_0_out       (),
        .float_0_data_2_2_out       (),

        .float_1_data_0_0_out       (),
        .float_1_data_0_1_out       (),
        .float_1_data_0_2_out       (),
        .float_1_data_2_0_out       (),
        .float_1_data_2_1_out       (),
        .float_1_data_2_2_out       ()
    );


    // Collect answers from execution cluster and return to memory
    collector collector(
        .clk                        (clk),
        .rst                        (rst),

        // To matrix register file
        .reg_collector_addr_out     (),
        .reg_collector_i_out        (),
        .reg_collector_j_out        (),
        .reg_collector_element_out  (),

        // To FMA cluster
        .result_0_0_in              (),
        .result_0_1_in              (),
        .result_0_2_in              (),
        .result_1_0_in              (),
        .result_1_1_in              (),
        .result_1_2_in              (),
        .result_2_0_in              (),
        .result_2_1_in              (),
        .result_2_2_in              (), 

        .ready_0_0_in               (),
        .ready_0_1_in               (),
        .ready_0_2_in               (),
        .ready_1_0_in               (),
        .ready_1_1_in               (),
        .ready_1_2_in               (),
        .ready_2_0_in               (),
        .ready_2_1_in               (),
        .ready_2_2_in               ()
    );


    // Controller
    mpu_controller mpu_controller(
        //Control signals
        .clk    (clk),
        .rst    (rst)
    );


    // Free running clock
    // tbx clkgen
    initial begin
        clk = 0;
        forever begin
          #(CLOCK_PERIOD/2) clk = ~clk;
        end
    end

    // Reset generator
    // tbx clkgen
    initial begin
        rst = 1;
        #(CLOCK_PERIOD*5) rst = 0;
    end

endmodule : mpu_top
