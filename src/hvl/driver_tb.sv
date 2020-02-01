// driver_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench driver that generates matrices and drives different types of tests
// into the design as well as the reference model.
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// The driver sends inputs into the bfm and checks results returned back
class driver_tb;

    virtual mpu_bfm bfm;                            // Virtual BFM interface
    mailbox #(mpu_data_sp) driver2checker;          // Mailbox to reference model
    mailbox #(stim_data_sp) stimulus2driver;        // Generated stimulus
    mpu_data_sp checker_data;                       // Checker model packet
    int num;                                        // Loop counters

    mpu_load_sp load_data;
    mpu_store_sp store_data;
    mpu_multiply_sp multiply_data;
    stim_data_sp stim_data;

    // Object instantiation
    function new(virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    // Run the tests
    task execute(input int unsigned iterations);
        init();
        this.stimulus2driver.peek(this.stim_data);
        if (this.stim_data.ready_to_multiply_repeat) begin
            this.stimulus2driver.get(this.stim_data);
            if (this.stim_data.ready_to_load) begin
                this.load_data.load_matrix = this.stim_data.generated_matrix;
                this.checker_data.matrix_in = this.stim_data.generated_matrix;
                load(this.stim_data.addr0);
            end
            if (this.stim_data.ready_to_load) begin
                this.stimulus2driver.get(this.stim_data);
                this.load_data.load_matrix = this.stim_data.generated_matrix;
                this.checker_data.matrix_in = this.stim_data.generated_matrix;
                load(this.stim_data.addr0);
            end
            this.stimulus2driver.get(this.stim_data);
            if (this.stim_data.ready_to_multiply) begin
                this.checker_data.op = MPU_MULT;
                this.checker_data.src_addr_0 = this.stim_data.addr0;
                this.checker_data.src_addr_1 = this.stim_data.addr1;
                this.checker_data.dest_addr = this.stim_data.dest;
                this.bfm.repeat_mult(this.stim_data.addr0, this.stim_data.addr1, this.stim_data.dest, iterations);
                this.driver2checker.put(this.checker_data);
            end
            store_registers();
        end
        else begin
            repeat (iterations) begin
                do begin
                    this.stimulus2driver.get(this.stim_data);
                    if (this.stim_data.ready_to_load) begin
                        this.load_data.load_matrix = this.stim_data.generated_matrix;
                        this.checker_data.matrix_in = this.stim_data.generated_matrix;
                        load(this.stim_data.addr0);
                    end
                    if (this.stim_data.ready_to_multiply) begin
                        multiply(this.stim_data.addr0, this.stim_data.addr1, this.stim_data.dest);
                    end
                end while (!this.stim_data.ready_to_store);
                store_registers();
            end
        end
        nop();
        $finish;
    endtask : execute

    // Initialize interface and design
    task automatic init();
        this.checker_data.op = MPU_NOP;
        this.checker_data.m_in = M_MEM;
        this.checker_data.n_in = N_MEM;
        this.checker_data.src_addr_0 = '0;
        this.checker_data.src_addr_1 = '0;
        this.checker_data.dest_addr = '0;
        foreach(this.checker_data.matrix_in.matrix[i]) this.checker_data.matrix_in.matrix[i] = '0;
        this.load_data.m = M_MEM;
        this.load_data.n = N_MEM;
        this.driver2checker.put(this.checker_data);       
        this.bfm.nop();
    endtask : init

    // Send a nop into the design and reference model
    task automatic nop();
        this.checker_data.op = MPU_NOP;
        this.driver2checker.put(this.checker_data);
        this.bfm.nop();        
    endtask : nop

    // Load a matrix into an address
    task automatic load(input int src_addr_0);
        this.checker_data.op = MPU_LOAD;
        this.checker_data.m_in = M_MEM;
        this.checker_data.n_in = N_MEM;
        this.checker_data.src_addr_0 = src_addr_0;
        this.load_data.m = M_MEM;
        this.load_data.n = N_MEM;
        this.load_data.addr0 = src_addr_0;
        this.bfm.load(this.load_data);
        this.driver2checker.put(this.checker_data);
    endtask : load

    // Store a matrix from an address
    task automatic store(input int src_addr_0);
        this.checker_data.op = MPU_STORE;
        this.checker_data.src_addr_0 = src_addr_0;
        this.store_data.addr0 = src_addr_0;
        this.bfm.store(this.store_data, this.store_data);
        this.checker_data.matrix_out = this.store_data.store_matrix;
        this.driver2checker.put(this.checker_data);
    endtask : store

    // Multiply the matrices from two addresses and put the result in a third address
    task automatic multiply(input int src_addr_0, input int src_addr_1, input int dest_addr);
        this.checker_data.op = MPU_MULT;
        this.checker_data.src_addr_0 = src_addr_0;
        this.checker_data.src_addr_1 = src_addr_1;
        this.checker_data.dest_addr = dest_addr;
        this.multiply_data.addr0 = src_addr_0;
        this.multiply_data.addr1 = src_addr_1;
        this.multiply_data.dest = dest_addr;
        this.bfm.multiply(this.multiply_data);
        this.driver2checker.put(this.checker_data);
    endtask : multiply

    // Store all registers
    task automatic store_registers();
        for (int i = 0; i < MATRIX_REGISTERS; ++i) begin
            store(i);
        end 
        nop();
    endtask

endclass : driver_tb
