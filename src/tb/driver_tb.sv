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
    //mpu_data_sp data_in, data_out, checker_data;    // Interface packets
    mpu_data_sp checker_data;                       // Checker model packet
    int i, num;                                     // Loop counters
    shortreal ii;                                   // Float iteration

    mpu_load_sp load_data;
    mpu_store_sp store_data;
    mpu_multiply_sp multiply_data;

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
        for (i = 0, ii = 0.0; i < MATRIX_REGISTERS; ++i, ii = ii + 1.0 * 9.0) begin
            generate_matrix(ii, 1.0, this.load_data);  // Each element is unique and sequential across all matrix registers
            this.checker_data.matrix_in = this.load_data.matrix;
            load(i);
        end
        store_registers();

        ///////////////////////////////////////////////////////////////
        // Next, check that the individual FMA units are all working //
        ///////////////////////////////////////////////////////////////
        generate_matrix(1.0, 0.0, this.load_data);     // Uniform 1.0 matrix
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        this.load_data.matrix = {$shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0),
                                 $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0),
                                 $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0),
                                 $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0),
                                 $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0),
                                 $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0)};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        this.load_data.matrix = {$shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
                                 $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
                                 $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
                                 $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
                                 $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
                                 $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0)};
        this.checker_data.matrix_in = this.load_data.matrix;
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
        generate_matrix(1.0, 1.0, this.load_data);
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        generate_matrix(1.0, 0.0, this.load_data);             // Uniform +1.0 matrix
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        generate_matrix_reverse(100.0, 100.0, this.load_data); // Matrix of large numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(2);
        generate_matrix(0.01, 0.01, this.load_data);           // Matrix of small numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(3);
        multiply(0, 1, 4);
        multiply(1, 1, 5);
        multiply(2, 1, 6);
        multiply(3, 1, 7);
        store_registers();
        //simulation_register_dump(mpu_top.mpu_register_file.matrix_register_array);


        ////////////////////////////////
        // Check multiply by -1 cases //
        ////////////////////////////////
        generate_matrix(1.0, 1.0, this.load_data);
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        generate_matrix(-1.0, 0.0, this.load_data);            // Uniform -1.0 matrix
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        generate_matrix(100.0, 100.0, this.load_data);         // Matrix of large numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(2);
        generate_matrix_reverse(0.01, 0.01, this.load_data);   // Matrix of small numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(3);
        multiply(0, 1, 4);
        multiply(1, 1, 5);
        multiply(2, 1, 6);
        multiply(3, 1, 7);
        store_registers();

        ///////////////////////////////
        // Check multiply by 0 cases //
        ///////////////////////////////
        generate_matrix(0.0, 0.0, this.load_data);             // Uniform 0.0 matrix
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        generate_matrix(-1.0, 0.0, this.load_data);            // Uniform -1.0 matrix
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        generate_matrix(100.0, 100.0, this.load_data);         // Matrix of large numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(2);
        generate_matrix(0.01, 0.01, this.load_data);           // Matrix of small numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(3);
        multiply(0, 0, 4);
        multiply(0, 1, 5);
        multiply(0, 2, 6);
        multiply(3, 0, 7);
        store_registers();
        //show_matrix(this.load_data.matrix);

        ////////////////////////////////////////
        // Check inverse multiplication cases //
        ////////////////////////////////////////
        /*
        this.load_data.matrix = {$shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(3.0),
                                 $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(4.0),
                                 $shortrealtobits(5.0), $shortrealtobits(6.0), $shortrealtobits(0.0)};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        this.load_data.matrix = {$shortrealtobits(-24.0), $shortrealtobits(18.0), $shortrealtobits(5.0),
                                 $shortrealtobits(20.0), $shortrealtobits(-15.0), $shortrealtobits(-4.0),
                                 $shortrealtobits(-5.0), $shortrealtobits(4.0), $shortrealtobits(1.0)};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        this.load_data.matrix = {$shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0),
                                 $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(1.0),
                                 $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(0.0)};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(2);
        this.load_data.matrix = {$shortrealtobits(-1.0), $shortrealtobits(0.0), $shortrealtobits(1.0),
                                 $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(1.0),
                                 $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(-1.0)};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(3);
        multiply(0, 1, 4);
        multiply(1, 0, 5);
        multiply(2, 3, 6);
        multiply(3, 2, 7);
        store_registers();*/

        ///////////////////////////////
        // Run the bulk of the tests //
        ///////////////////////////////
        for (num = NUM_TESTS; num; --num) begin
            generate_matrix(random()*-1.0/num, random()*-1.0, this.load_data);
            this.checker_data.matrix_in = this.load_data.matrix;
            load(0);
            generate_matrix_reverse(0.001, random()/num, this.load_data);
            this.checker_data.matrix_in = this.load_data.matrix;
            load(1);
            generate_matrix(0.1, random()*0.07, this.load_data);
            this.checker_data.matrix_in = this.load_data.matrix;
            load(2);
            multiply($urandom_range(0,2), $urandom_range(0,2), 3);
            multiply($urandom_range(0,3), $urandom_range(0,3), 4);
            multiply($urandom_range(0,4), $urandom_range(0,4), 5);
            multiply($urandom_range(0,5), $urandom_range(0,5), 6);
            multiply($urandom_range(1,2), $urandom_range(1,2), 7);
            store_registers();
        end

        //////////////////////////////////////////
        // Run back-to-back multiply operations //
        //////////////////////////////////////////
        /*generate_matrix(1.0, 1.0, this.load_data);
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        generate_matrix(1.0, 0.0, this.load_data);             // Uniform +1.0 matrix
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        this.bfm.repeat_mult(0, 1, 2, NUM_TESTS);
        store(2);*/

        ///////////////////////////////////////////////////////
        // Check multiplication overflow and underflow cases //
        ///////////////////////////////////////////////////////
        this.load_data.matrix = {BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        this.load_data.matrix = {BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                                 BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        this.load_data.matrix = {SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32};
        this.checker_data.matrix_in = this.load_data.matrix;
        load(2);
        this.load_data.matrix = {SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                                 SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32};
        load(3);
        multiply(0, 1, 4);      // Overflow
        multiply(1, 0, 5);      // Overflow
        multiply(2, 3, 6);      // Underflow
        multiply(3, 2, 7);      // Underflow
        store_registers();

        //////////////////////
        // Finish Testbench //
        //////////////////////
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
        foreach(this.checker_data.matrix_in[i]) this.checker_data.matrix_in[i] = '0;
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
        this.checker_data.matrix_out = this.store_data.matrix;
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
        this.bfm.multiply(multiply_data);
        this.driver2checker.put(this.checker_data);
    endtask : multiply

    // Store all registers
    task automatic store_registers();
        for (i = 0; i < MATRIX_REGISTERS; ++i) begin
            store(i);
        end 
        nop();
    endtask

endclass : driver_tb
