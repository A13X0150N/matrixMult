// mpu_top.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Top-level design for DUT. 
//
// ----------------------------------------------------------------------------
 
import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::CLOCK_PERIOD;

module mpu_top;

    bit clk=0;      // System clock
    bit rst=0;      // Synchronous reset, active high

    // Interface
    mpu_bfm mpu_bfm(.clk(clk), .rst(rst));

    // MPU Controller
    mpu_controller mpu_controller(
        //Control signals
        .clk                        (clk),
        .rst                        (rst),
        .start_mult_in              (mpu_bfm.start_mult),
        .src_addr_0_in              (mpu_bfm.src_addr_0),
        .src_addr_1_in              (mpu_bfm.src_addr_1),
        .dest_addr_in               (mpu_bfm.dest_addr),
       
        // To Dispatcher
        .disp_finished_in           (mpu_bfm.disp_finished),
        .disp_start_out             (mpu_bfm.disp_start),

        // To Collector
        .collector_active_write_in  (mpu_bfm.collector_active_write),

        // To Matrix Register File
        .collector_ready_in         (mpu_bfm.collector_ready),
        .disp_ready_in              (mpu_bfm.disp_ready),
        .reg_collector_req_out      (mpu_bfm.reg_collector_req), 
        .reg_disp_req_out           (mpu_bfm.reg_disp_req),
        .reg_src_addr_0_out         (mpu_bfm.reg_src_addr_0),
        .reg_src_addr_1_out         (mpu_bfm.reg_src_addr_1),
        .reg_dest_addr_out          (mpu_bfm.reg_dest_addr)
    );

    // Register file
    mpu_register_file mpu_register_file(
        // Control Signals
        .clk                        (clk),
        .rst                        (rst),
        .reg_load_req_in            (mpu_bfm.reg_load_req),
        .reg_store_req_in           (mpu_bfm.reg_store_req),
        .reg_disp_req_in            (mpu_bfm.reg_disp_req),
        .reg_collector_req_in       (mpu_bfm.reg_collector_req),
        .reg_disp_ready_out         (mpu_bfm.disp_ready),
        .reg_collector_ready_out    (mpu_bfm.collector_ready),

        // To MPU Load
        .load_ready_out             (mpu_bfm.load_ready),
        .reg_load_addr_in           (mpu_bfm.reg_load_addr),
        .reg_load_element_in        (mpu_bfm.reg_load_element),         
        .reg_i_load_loc_in          (mpu_bfm.reg_i_load_loc),
        .reg_j_load_loc_in          (mpu_bfm.reg_j_load_loc),
        .reg_m_load_size_in         (mpu_bfm.reg_m_load_size),
        .reg_n_load_size_in         (mpu_bfm.reg_n_load_size),

        // To MPU Store
        .store_ready_out            (mpu_bfm.store_ready),
        .reg_store_addr_in          (mpu_bfm.reg_store_addr),
        .reg_i_store_loc_in         (mpu_bfm.reg_i_store_loc),
        .reg_j_store_loc_in         (mpu_bfm.reg_j_store_loc),
        .reg_m_store_size_out       (mpu_bfm.reg_m_store_size),
        .reg_n_store_size_out       (mpu_bfm.reg_n_store_size),
        .reg_store_element_out      (mpu_bfm.reg_store_element),

        // To Dispatcher
        .reg_disp_addr_0_in         (mpu_bfm.reg_src_addr_0),
        .reg_disp_addr_1_in         (mpu_bfm.reg_src_addr_1), 
        .reg_disp_0_i_in            (mpu_bfm.reg_disp_0_i),
        .reg_disp_0_j_in            (mpu_bfm.reg_disp_0_j),
        .reg_disp_1_i_in            (mpu_bfm.reg_disp_1_i),
        .reg_disp_1_j_in            (mpu_bfm.reg_disp_1_j),
        .reg_disp_element_0_out     (mpu_bfm.reg_disp_element_0),
        .reg_disp_element_1_out     (mpu_bfm.reg_disp_element_1),

        // To Collector
        .reg_collector_addr_in      (mpu_bfm.reg_dest_addr),
        .reg_collector_i_in         (mpu_bfm.reg_collector_i),
        .reg_collector_j_in         (mpu_bfm.reg_collector_j),
        .reg_collector_element_in   (mpu_bfm.reg_collector_element)

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
        .reg_load_req_out           (mpu_bfm.reg_load_req),
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
        .reg_store_req_out          (mpu_bfm.reg_store_req),
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
    mpu_dispatcher mpu_dispatcher(
        // Control Signals
        .clk                        (clk),
        .rst                        (rst),
        .disp_start_in              (mpu_bfm.disp_start),
        .disp_ack_out               (mpu_bfm.disp_ack),
        .disp_finished_out          (mpu_bfm.disp_finished),

        // To matrix register file
        .reg_disp_0_i_out           (mpu_bfm.reg_disp_0_i),
        .reg_disp_0_j_out           (mpu_bfm.reg_disp_0_j),
        .reg_disp_1_i_out           (mpu_bfm.reg_disp_1_i),
        .reg_disp_1_j_out           (mpu_bfm.reg_disp_1_j),
        .reg_disp_element_0_in      (mpu_bfm.reg_disp_element_0),
        .reg_disp_element_1_in      (mpu_bfm.reg_disp_element_1),

        // To FMA cluster
        .busy_0_0_in                (mpu_bfm.busy_0_0),
        .busy_0_1_in                (mpu_bfm.busy_0_1),
        .busy_0_2_in                (mpu_bfm.busy_0_2),
        .busy_0_3_in                (mpu_bfm.busy_0_3),
        .busy_0_4_in                (mpu_bfm.busy_0_4),
        .busy_0_5_in                (mpu_bfm.busy_0_5), 
        .busy_1_0_in                (mpu_bfm.busy_1_0),
        .busy_1_5_in                (mpu_bfm.busy_1_5),
        .busy_2_0_in                (mpu_bfm.busy_2_0),
        .busy_2_5_in                (mpu_bfm.busy_2_5),
        .busy_3_0_in                (mpu_bfm.busy_3_0),
        .busy_3_5_in                (mpu_bfm.busy_3_5),
        .busy_4_0_in                (mpu_bfm.busy_4_0),
        .busy_4_5_in                (mpu_bfm.busy_4_5),
        .busy_5_0_in                (mpu_bfm.busy_5_0),
        .busy_5_1_in                (mpu_bfm.busy_5_1),
        .busy_5_2_in                (mpu_bfm.busy_5_2),
        .busy_5_3_in                (mpu_bfm.busy_5_3),
        .busy_5_4_in                (mpu_bfm.busy_5_4),
        .busy_5_5_in                (mpu_bfm.busy_5_5), 

        .float_0_req_0_0_out        (mpu_bfm.float_0_req_0_0),
        .float_0_req_0_5_out        (mpu_bfm.float_0_req_0_5),
        .float_0_req_1_0_out        (mpu_bfm.float_0_req_1_0),
        .float_0_req_1_5_out        (mpu_bfm.float_0_req_1_5),
        .float_0_req_2_0_out        (mpu_bfm.float_0_req_2_0),
        .float_0_req_2_5_out        (mpu_bfm.float_0_req_2_5),
        .float_0_req_3_0_out        (mpu_bfm.float_0_req_3_0),
        .float_0_req_3_5_out        (mpu_bfm.float_0_req_3_5),
        .float_0_req_4_0_out        (mpu_bfm.float_0_req_4_0),
        .float_0_req_4_5_out        (mpu_bfm.float_0_req_4_5),
        .float_0_req_5_0_out        (mpu_bfm.float_0_req_5_0),
        .float_0_req_5_5_out        (mpu_bfm.float_0_req_5_5),

        .float_1_req_0_0_out        (mpu_bfm.float_1_req_0_0),
        .float_1_req_0_1_out        (mpu_bfm.float_1_req_0_1),
        .float_1_req_0_2_out        (mpu_bfm.float_1_req_0_2),
        .float_1_req_0_3_out        (mpu_bfm.float_1_req_0_3),
        .float_1_req_0_4_out        (mpu_bfm.float_1_req_0_4),
        .float_1_req_0_5_out        (mpu_bfm.float_1_req_0_5),
        .float_1_req_5_0_out        (mpu_bfm.float_1_req_5_0),
        .float_1_req_5_1_out        (mpu_bfm.float_1_req_5_1),
        .float_1_req_5_2_out        (mpu_bfm.float_1_req_5_2),
        .float_1_req_5_3_out        (mpu_bfm.float_1_req_5_3),
        .float_1_req_5_4_out        (mpu_bfm.float_1_req_5_4),
        .float_1_req_5_5_out        (mpu_bfm.float_1_req_5_5),

        .float_0_data_0_0_out       (mpu_bfm.float_0_data_0_0),
        .float_0_data_0_5_out       (mpu_bfm.float_0_data_0_5),
        .float_0_data_1_0_out       (mpu_bfm.float_0_data_1_0),
        .float_0_data_1_5_out       (mpu_bfm.float_0_data_1_5),
        .float_0_data_2_0_out       (mpu_bfm.float_0_data_2_0),
        .float_0_data_2_5_out       (mpu_bfm.float_0_data_2_5),
        .float_0_data_3_0_out       (mpu_bfm.float_0_data_3_0),
        .float_0_data_3_5_out       (mpu_bfm.float_0_data_3_5),
        .float_0_data_4_0_out       (mpu_bfm.float_0_data_4_0),
        .float_0_data_4_5_out       (mpu_bfm.float_0_data_4_5),
        .float_0_data_5_0_out       (mpu_bfm.float_0_data_5_0),
        .float_0_data_5_5_out       (mpu_bfm.float_0_data_5_5),

        .float_1_data_0_0_out       (mpu_bfm.float_1_data_0_0),
        .float_1_data_0_1_out       (mpu_bfm.float_1_data_0_1),
        .float_1_data_0_2_out       (mpu_bfm.float_1_data_0_2),
        .float_1_data_0_3_out       (mpu_bfm.float_1_data_0_3),
        .float_1_data_0_4_out       (mpu_bfm.float_1_data_0_4),
        .float_1_data_0_5_out       (mpu_bfm.float_1_data_0_5),
        .float_1_data_5_0_out       (mpu_bfm.float_1_data_5_0),
        .float_1_data_5_1_out       (mpu_bfm.float_1_data_5_1),
        .float_1_data_5_2_out       (mpu_bfm.float_1_data_5_2),
        .float_1_data_5_3_out       (mpu_bfm.float_1_data_5_3),
        .float_1_data_5_4_out       (mpu_bfm.float_1_data_5_4),
        .float_1_data_5_5_out       (mpu_bfm.float_1_data_5_5)
    );

    // Collect answers from execution cluster and return to memory
    mpu_collector mpu_collector(
        .clk                        (clk),
        .rst                        (rst),
        .collector_finished         (mpu_bfm.collector_finished),
        .collector_active_write_out (mpu_bfm.collector_active_write),

        // To matrix register file
        .reg_collector_i_out        (mpu_bfm.reg_collector_i),
        .reg_collector_j_out        (mpu_bfm.reg_collector_j),
        .reg_collector_element_out  (mpu_bfm.reg_collector_element),

        // To FMA cluster
        .result_0_0_in              (mpu_bfm.result_0_0),
        .result_0_1_in              (mpu_bfm.result_0_1),
        .result_0_2_in              (mpu_bfm.result_0_2),
        .result_0_3_in              (mpu_bfm.result_0_3),
        .result_0_4_in              (mpu_bfm.result_0_4),
        .result_0_5_in              (mpu_bfm.result_0_5),
        .result_1_0_in              (mpu_bfm.result_1_0),
        .result_1_1_in              (mpu_bfm.result_1_1),
        .result_1_2_in              (mpu_bfm.result_1_2),
        .result_1_3_in              (mpu_bfm.result_1_3),
        .result_1_4_in              (mpu_bfm.result_1_4),
        .result_1_5_in              (mpu_bfm.result_1_5),
        .result_2_0_in              (mpu_bfm.result_2_0),
        .result_2_1_in              (mpu_bfm.result_2_1),
        .result_2_2_in              (mpu_bfm.result_2_2),
        .result_2_3_in              (mpu_bfm.result_2_3),
        .result_2_4_in              (mpu_bfm.result_2_4), 
        .result_2_5_in              (mpu_bfm.result_2_5),
        .result_3_0_in              (mpu_bfm.result_3_0),
        .result_3_1_in              (mpu_bfm.result_3_1),
        .result_3_2_in              (mpu_bfm.result_3_2),
        .result_3_3_in              (mpu_bfm.result_3_3),
        .result_3_4_in              (mpu_bfm.result_3_4),
        .result_3_5_in              (mpu_bfm.result_3_5),
        .result_4_0_in              (mpu_bfm.result_4_0),
        .result_4_1_in              (mpu_bfm.result_4_1),
        .result_4_2_in              (mpu_bfm.result_4_2),
        .result_4_3_in              (mpu_bfm.result_4_3),
        .result_4_4_in              (mpu_bfm.result_4_4),
        .result_4_5_in              (mpu_bfm.result_4_5),
        .result_5_0_in              (mpu_bfm.result_5_0),
        .result_5_1_in              (mpu_bfm.result_5_1),
        .result_5_2_in              (mpu_bfm.result_5_2),
        .result_5_3_in              (mpu_bfm.result_5_3),
        .result_5_4_in              (mpu_bfm.result_5_4),
        .result_5_5_in              (mpu_bfm.result_5_5),

        .ready_0_0_in               (mpu_bfm.ready_0_0),
        .ready_0_1_in               (mpu_bfm.ready_0_1),
        .ready_0_2_in               (mpu_bfm.ready_0_2),
        .ready_0_3_in               (mpu_bfm.ready_0_3),
        .ready_0_4_in               (mpu_bfm.ready_0_4),
        .ready_0_5_in               (mpu_bfm.ready_0_5),
        .ready_1_0_in               (mpu_bfm.ready_1_0),
        .ready_1_1_in               (mpu_bfm.ready_1_1),
        .ready_1_2_in               (mpu_bfm.ready_1_2),
        .ready_1_3_in               (mpu_bfm.ready_1_3),
        .ready_1_4_in               (mpu_bfm.ready_1_4),
        .ready_1_5_in               (mpu_bfm.ready_1_5),
        .ready_2_0_in               (mpu_bfm.ready_2_0),
        .ready_2_1_in               (mpu_bfm.ready_2_1),
        .ready_2_2_in               (mpu_bfm.ready_2_2),
        .ready_2_3_in               (mpu_bfm.ready_2_3),
        .ready_2_4_in               (mpu_bfm.ready_2_4),
        .ready_2_5_in               (mpu_bfm.ready_2_5),
        .ready_3_0_in               (mpu_bfm.ready_3_0),
        .ready_3_1_in               (mpu_bfm.ready_3_1),
        .ready_3_2_in               (mpu_bfm.ready_3_2),
        .ready_3_3_in               (mpu_bfm.ready_3_3),
        .ready_3_4_in               (mpu_bfm.ready_3_4),
        .ready_3_5_in               (mpu_bfm.ready_3_5),
        .ready_4_0_in               (mpu_bfm.ready_4_0),
        .ready_4_1_in               (mpu_bfm.ready_4_1),
        .ready_4_2_in               (mpu_bfm.ready_4_2),
        .ready_4_3_in               (mpu_bfm.ready_4_3),
        .ready_4_4_in               (mpu_bfm.ready_4_4),
        .ready_4_5_in               (mpu_bfm.ready_4_5),
        .ready_5_0_in               (mpu_bfm.ready_5_0),
        .ready_5_1_in               (mpu_bfm.ready_5_1),
        .ready_5_2_in               (mpu_bfm.ready_5_2),
        .ready_5_3_in               (mpu_bfm.ready_5_3),
        .ready_5_4_in               (mpu_bfm.ready_5_4),
        .ready_5_5_in               (mpu_bfm.ready_5_5),

        .error_detected_in          (mpu_bfm.error_detected)//
    );

    fma_cluster fma_cluster(
        // Control Signals
        .clk                        (clk),
        .rst                        (rst),

        .busy_0_0_out               (mpu_bfm.busy_0_0),
        .busy_0_1_out               (mpu_bfm.busy_0_1),
        .busy_0_2_out               (mpu_bfm.busy_0_2),
        .busy_0_3_out               (mpu_bfm.busy_0_3),
        .busy_0_4_out               (mpu_bfm.busy_0_4),
        .busy_0_5_out               (mpu_bfm.busy_0_5),
        .busy_1_0_out               (mpu_bfm.busy_1_0),
        .busy_1_5_out               (mpu_bfm.busy_1_5),
        .busy_2_0_out               (mpu_bfm.busy_2_0),
        .busy_2_5_out               (mpu_bfm.busy_2_5),
        .busy_3_0_out               (mpu_bfm.busy_3_0),
        .busy_3_5_out               (mpu_bfm.busy_3_5),
        .busy_4_0_out               (mpu_bfm.busy_4_0),
        .busy_4_5_out               (mpu_bfm.busy_4_5),
        .busy_5_0_out               (mpu_bfm.busy_5_0),
        .busy_5_1_out               (mpu_bfm.busy_5_1),
        .busy_5_2_out               (mpu_bfm.busy_5_2),
        .busy_5_3_out               (mpu_bfm.busy_5_3),
        .busy_5_4_out               (mpu_bfm.busy_5_4),
        .busy_5_5_out               (mpu_bfm.busy_5_5),

        .float_0_req_0_0_in         (mpu_bfm.float_0_req_0_0),
        .float_0_req_0_5_in         (mpu_bfm.float_0_req_0_5),
        .float_0_req_1_0_in         (mpu_bfm.float_0_req_1_0),
        .float_0_req_1_5_in         (mpu_bfm.float_0_req_1_5),
        .float_0_req_2_0_in         (mpu_bfm.float_0_req_2_0),
        .float_0_req_2_5_in         (mpu_bfm.float_0_req_2_5),
        .float_0_req_3_0_in         (mpu_bfm.float_0_req_3_0),
        .float_0_req_3_5_in         (mpu_bfm.float_0_req_3_5),
        .float_0_req_4_0_in         (mpu_bfm.float_0_req_4_0),
        .float_0_req_4_5_in         (mpu_bfm.float_0_req_4_5),
        .float_0_req_5_0_in         (mpu_bfm.float_0_req_5_0),
        .float_0_req_5_5_in         (mpu_bfm.float_0_req_5_5),

        .float_1_req_0_0_in         (mpu_bfm.float_1_req_0_0),
        .float_1_req_0_1_in         (mpu_bfm.float_1_req_0_1),
        .float_1_req_0_2_in         (mpu_bfm.float_1_req_0_2),
        .float_1_req_0_3_in         (mpu_bfm.float_1_req_0_3),
        .float_1_req_0_4_in         (mpu_bfm.float_1_req_0_4),
        .float_1_req_0_5_in         (mpu_bfm.float_1_req_0_5),
        .float_1_req_5_0_in         (mpu_bfm.float_1_req_5_0),
        .float_1_req_5_1_in         (mpu_bfm.float_1_req_5_1),
        .float_1_req_5_2_in         (mpu_bfm.float_1_req_5_2),
        .float_1_req_5_3_in         (mpu_bfm.float_1_req_5_3),
        .float_1_req_5_4_in         (mpu_bfm.float_1_req_5_4),
        .float_1_req_5_5_in         (mpu_bfm.float_1_req_5_5),

        .float_0_data_0_0_in        (mpu_bfm.float_0_data_0_0),
        .float_0_data_0_5_in        (mpu_bfm.float_0_data_0_5),
        .float_0_data_1_0_in        (mpu_bfm.float_0_data_1_0),
        .float_0_data_1_5_in        (mpu_bfm.float_0_data_1_5),
        .float_0_data_2_0_in        (mpu_bfm.float_0_data_2_0),
        .float_0_data_2_5_in        (mpu_bfm.float_0_data_2_5),
        .float_0_data_3_0_in        (mpu_bfm.float_0_data_3_0),
        .float_0_data_3_5_in        (mpu_bfm.float_0_data_3_5),
        .float_0_data_4_0_in        (mpu_bfm.float_0_data_4_0),
        .float_0_data_4_5_in        (mpu_bfm.float_0_data_4_5),
        .float_0_data_5_0_in        (mpu_bfm.float_0_data_5_0),
        .float_0_data_5_5_in        (mpu_bfm.float_0_data_5_5),

        .float_1_data_0_0_in        (mpu_bfm.float_1_data_0_0),
        .float_1_data_0_1_in        (mpu_bfm.float_1_data_0_1),
        .float_1_data_0_2_in        (mpu_bfm.float_1_data_0_2),
        .float_1_data_0_3_in        (mpu_bfm.float_1_data_0_3),
        .float_1_data_0_4_in        (mpu_bfm.float_1_data_0_4),
        .float_1_data_0_5_in        (mpu_bfm.float_1_data_0_5),
        .float_1_data_5_0_in        (mpu_bfm.float_1_data_5_0),
        .float_1_data_5_1_in        (mpu_bfm.float_1_data_5_1),
        .float_1_data_5_2_in        (mpu_bfm.float_1_data_5_2),
        .float_1_data_5_3_in        (mpu_bfm.float_1_data_5_3),
        .float_1_data_5_4_in        (mpu_bfm.float_1_data_5_4),
        .float_1_data_5_5_in        (mpu_bfm.float_1_data_5_5),

        .result_0_0_out             (mpu_bfm.result_0_0),
        .result_0_1_out             (mpu_bfm.result_0_1),
        .result_0_2_out             (mpu_bfm.result_0_2),
        .result_0_3_out             (mpu_bfm.result_0_3),
        .result_0_4_out             (mpu_bfm.result_0_4),
        .result_0_5_out             (mpu_bfm.result_0_5),
        .result_1_0_out             (mpu_bfm.result_1_0),
        .result_1_1_out             (mpu_bfm.result_1_1),
        .result_1_2_out             (mpu_bfm.result_1_2),
        .result_1_3_out             (mpu_bfm.result_1_3),
        .result_1_4_out             (mpu_bfm.result_1_4),
        .result_1_5_out             (mpu_bfm.result_1_5),
        .result_2_0_out             (mpu_bfm.result_2_0),
        .result_2_1_out             (mpu_bfm.result_2_1),
        .result_2_2_out             (mpu_bfm.result_2_2),
        .result_2_3_out             (mpu_bfm.result_2_3),
        .result_2_4_out             (mpu_bfm.result_2_4),
        .result_2_5_out             (mpu_bfm.result_2_5),
        .result_3_0_out             (mpu_bfm.result_3_0),
        .result_3_1_out             (mpu_bfm.result_3_1),
        .result_3_2_out             (mpu_bfm.result_3_2),
        .result_3_3_out             (mpu_bfm.result_3_3),
        .result_3_4_out             (mpu_bfm.result_3_4),
        .result_3_5_out             (mpu_bfm.result_3_5),
        .result_4_0_out             (mpu_bfm.result_4_0),
        .result_4_1_out             (mpu_bfm.result_4_1),
        .result_4_2_out             (mpu_bfm.result_4_2),
        .result_4_3_out             (mpu_bfm.result_4_3),
        .result_4_4_out             (mpu_bfm.result_4_4),
        .result_4_5_out             (mpu_bfm.result_4_5),
        .result_5_0_out             (mpu_bfm.result_5_0),
        .result_5_1_out             (mpu_bfm.result_5_1),
        .result_5_2_out             (mpu_bfm.result_5_2),
        .result_5_3_out             (mpu_bfm.result_5_3),
        .result_5_4_out             (mpu_bfm.result_5_4),
        .result_5_5_out             (mpu_bfm.result_5_5),

        .ready_0_0_out              (mpu_bfm.ready_0_0),
        .ready_0_1_out              (mpu_bfm.ready_0_1),
        .ready_0_2_out              (mpu_bfm.ready_0_2),
        .ready_0_3_out              (mpu_bfm.ready_0_3),
        .ready_0_4_out              (mpu_bfm.ready_0_4),
        .ready_0_5_out              (mpu_bfm.ready_0_5),
        .ready_1_0_out              (mpu_bfm.ready_1_0),
        .ready_1_1_out              (mpu_bfm.ready_1_1),
        .ready_1_2_out              (mpu_bfm.ready_1_2),
        .ready_1_3_out              (mpu_bfm.ready_1_3),
        .ready_1_4_out              (mpu_bfm.ready_1_4),
        .ready_1_5_out              (mpu_bfm.ready_1_5),
        .ready_2_0_out              (mpu_bfm.ready_2_0),
        .ready_2_1_out              (mpu_bfm.ready_2_1),
        .ready_2_2_out              (mpu_bfm.ready_2_2),
        .ready_2_3_out              (mpu_bfm.ready_2_3),
        .ready_2_4_out              (mpu_bfm.ready_2_4),
        .ready_2_5_out              (mpu_bfm.ready_2_5),
        .ready_3_0_out              (mpu_bfm.ready_3_0),
        .ready_3_1_out              (mpu_bfm.ready_3_1),
        .ready_3_2_out              (mpu_bfm.ready_3_2),
        .ready_3_3_out              (mpu_bfm.ready_3_3),
        .ready_3_4_out              (mpu_bfm.ready_3_4),
        .ready_3_5_out              (mpu_bfm.ready_3_5),
        .ready_4_0_out              (mpu_bfm.ready_4_0),
        .ready_4_1_out              (mpu_bfm.ready_4_1),
        .ready_4_2_out              (mpu_bfm.ready_4_2),
        .ready_4_3_out              (mpu_bfm.ready_4_3),
        .ready_4_4_out              (mpu_bfm.ready_4_4),
        .ready_4_5_out              (mpu_bfm.ready_4_5),
        .ready_5_0_out              (mpu_bfm.ready_5_0),
        .ready_5_1_out              (mpu_bfm.ready_5_1),
        .ready_5_2_out              (mpu_bfm.ready_5_2),
        .ready_5_3_out              (mpu_bfm.ready_5_3),
        .ready_5_4_out              (mpu_bfm.ready_5_4),
        .ready_5_5_out              (mpu_bfm.ready_5_5),

        .error_detected_out         (mpu_bfm.error_detected)
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
