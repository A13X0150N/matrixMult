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
    mpu_data_sp data_in, data_out;                  // Interface packets
    int i, num;                                     // Loop counters
    shortreal ii;                                   // Float iteration
    real random1;                                   // Random float variable

    // Object instantiation
    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    // Generate a 'random' 32-bit float
    function shortreal random();
        random = 1+($urandom%1000)/1000.0;
    endfunction

    // Run the tests
    task execute();
        init();
        
        ///////////////////////////////////////////////////////////
        // First, check load and store of all internal registers //
        ///////////////////////////////////////////////////////////
        data_in.op = MPU_LOAD;
        for (i = 0, ii = 0.0; i < MATRIX_REGISTERS; ++i, ii = ii + 1.0 * 9.0) begin
            generate_matrix(ii, 1.0, data_in);  // Each element is unique and sequential across all matrix registers
            load(i);
        end
        store_registers();

        ///////////////////////////////////////////////////////////////
        // Next, check that the individual FMA units are all working //
        ///////////////////////////////////////////////////////////////
        generate_matrix(1.0, 0.0, data_in);     // Uniform 1.0 matrix
        load(0);
        data_in.matrix_in = {$shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0),
                             $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0),
                             $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0)};
        load(1);
        data_in.matrix_in = {$shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0),
                             $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0),
                             $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0)};
        load(2);
        multiply(0, 1, 3);
        multiply(1, 0, 4);
        multiply(0, 2, 5);
        multiply(2, 0, 6);
        multiply(0, 0, 7);
        store_registers();

        ////////////////////////////////
        // Check multiply by +1 cases //
        ////////////////////////////////
        generate_matrix(1.0, 1.0, data_in);
        load(0);
        generate_matrix(1.0, 0.0, data_in);             // Uniform +1.0 matrix
        load(1);
        generate_matrix_reverse(100.0, 100.0, data_in); // Matrix of large numbers
        load(2);
        generate_matrix(0.01, 0.01, data_in);           // Matrix of small numbers
        load(3);
        multiply(0, 1, 4);
        multiply(1, 1, 5);
        multiply(2, 1, 6);
        multiply(3, 1, 7);
        store_registers();

        ////////////////////////////////
        // Check multiply by -1 cases //
        ////////////////////////////////
        generate_matrix(1.0, 1.0, data_in);
        load(0);
        generate_matrix(-1.0, 0.0, data_in);            // Uniform -1.0 matrix
        load(1);
        generate_matrix(100.0, 100.0, data_in);         // Matrix of large numbers
        load(2);
        generate_matrix_reverse(0.01, 0.01, data_in);   // Matrix of small numbers
        load(3);
        multiply(0, 1, 4);
        multiply(1, 1, 5);
        multiply(2, 1, 6);
        multiply(3, 1, 7);
        store_registers();

        ///////////////////////////////
        // Check multiply by 0 cases //
        ///////////////////////////////
        generate_matrix(0.0, 0.0, data_in);             // Uniform 0.0 matrix
        load(0);
        generate_matrix(-1.0, 0.0, data_in);            // Uniform -1.0 matrix
        load(1);
        generate_matrix(100.0, 100.0, data_in);         // Matrix of large numbers
        load(2);
        generate_matrix(0.01, 0.01, data_in);           // Matrix of small numbers
        load(3);
        multiply(0, 0, 4);
        multiply(0, 1, 5);
        multiply(0, 2, 6);
        multiply(3, 0, 7);
        store_registers();

        ///////////////////////////////
        // Run the bulk of the tests //
        ///////////////////////////////
        for (num = 0; num < NUM_TESTS; ++num) begin
            generate_matrix(random()*-1.0, random()*-1.0, data_in);
            load(0);
            generate_matrix_reverse(0.001, random(), data_in);
            load(1);
            generate_matrix(0.1, random()*0.07, data_in);
            load(2);
            multiply($urandom_range(0,2), $urandom_range(0,2), 3);
            multiply($urandom_range(0,3), $urandom_range(0,3), 4);
            multiply($urandom_range(0,4), $urandom_range(0,4), 5);
            multiply($urandom_range(0,5), $urandom_range(0,5), 6);
            multiply($urandom_range(1,2), $urandom_range(1,2), 7);
            store_registers();
        end

        // Send out a NOP before finishing tests
        nop();
        $finish;
    endtask : execute

    // Initialize interface and design
    task automatic init();
        this.data_in.m_in = M_MEM;
        this.data_in.n_in = N_MEM;
        this.data_in.src_addr_0 = '0;
        foreach(this.data_in.matrix_in[i]) this.data_in.matrix_in[i] = '0;
        this.data_in.op = MPU_NOP;
        this.bfm.send_op(this.data_in, this.data_out);
        this.driver2checker.put(this.data_in);
    endtask : init

    // Send a NOP into the design and reference model
    task automatic nop();
        this.data_in.op = MPU_NOP;
        this.bfm.send_op(this.data_in, this.data_out);
        this.driver2checker.put(this.data_in);
    endtask : nop

    // LOAD a matrix into an address
    task automatic load(input int src_addr_0);
        this.data_in.op = MPU_LOAD;
        this.data_in.src_addr_0 = src_addr_0;
        this.bfm.send_op(this.data_in, this.data_out);
        this.driver2checker.put(this.data_in);
    endtask : load

    // STORE a matrix from an address
    task automatic store(input int src_addr_0);
        this.data_in.op = MPU_STORE;
        this.data_in.src_addr_0 = src_addr_0;
        this.bfm.send_op(this.data_in, this.data_out);
        this.data_in.matrix_out = this.data_out.matrix_out;
        this.driver2checker.put(this.data_in);
    endtask : store

    // Multilply the matrices from two addresses and put the result in a third address
    task automatic multiply(input int src_addr_0, input int src_addr_1, input int dest_addr);
        this.data_in.op = MPU_MULT;
        this.data_in.src_addr_0 = src_addr_0;
        this.data_in.src_addr_1 = src_addr_1;
        this.data_in.dest_addr = dest_addr;
        this.bfm.send_op(this.data_in, this.data_out);
        this.driver2checker.put(this.data_in);
    endtask : multiply

    // Store all registers
    task automatic store_registers();
        for (i = 0; i < MATRIX_REGISTERS; ++i) begin
            store(i);
        end 
        nop();
    endtask

endclass : driver_tb
