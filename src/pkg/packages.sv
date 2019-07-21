// packages.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Contains packages with definitions for design and testbench.


// Definitions for global space
package global_defs;

    // Type defines
    typedef enum bit {FALSE, TRUE} bool_e;

    // Floating point sizes
    parameter SP = 32;                      // Single precision
    parameter DP = 64;                      // Double precions [untested]
    parameter FP = SP;                      // Selection for design
    parameter FPBITS = FP-1;                // Floating point bit number

    // Multiplication methods, only make one selection (For experimental directory)
    parameter MULT_SIMULATION = 0;
    parameter MULT_BOOTH = 1;
    parameter MULT_WALLACE = 0;
    
    // Testbench
    parameter CLOCK_PERIOD = 10;
    parameter CYCLES = 100;

    // Maximum working matrix dimensions (m x k)(k x n)
    parameter M = 5;                        // Maximum register row size
    parameter K = 3;                        // Maximum register intermediate size [untested]
    parameter N = 5;                        // Maximum register  column size
    parameter MBITS = $clog2(M)-1;          // Register row bits
    parameter KBITS = $clog2(K)-1;          // Register intermediate bits
    parameter NBITS = $clog2(N)-1;          // Register column bits
    parameter M_MEM = 3;                    // Testbench input matrix rows     MUST BE LESS THAN M (remove?)
    parameter N_MEM = 3;                    // Testbench input matrix columns  MUST BE LESS THAN N (remove?)
    parameter NUM_ELEMENTS = M_MEM * N_MEM; // Number of input elements for testbench

    // Size of matrix register file
    parameter MATRIX_REGISTERS = 8;
    parameter MATRIX_REG_BITS = $clog2(MATRIX_REGISTERS)-1;

endpackage : global_defs


// Input/Output bit width for multiplication
package bit_width;
    parameter  INWIDTH  = 16;
    localparam OUTWIDTH = INWIDTH * 2;
endpackage : bit_width


// FPU BFM interface definitions
package fpu_pkg;
    typedef enum bit [1:0] {
        NOP  = 2'b00,
        ADD  = 2'b01,
        MULT = 2'b10
    } fpu_operation_t;
endpackage : fpu_pkg


// MPU BFM interface definitions
package mpu_pkg;

    import global_defs::FPBITS;
    import global_defs::NUM_ELEMENTS;
    import global_defs::MBITS;
    import global_defs::NBITS;
    import global_defs::MATRIX_REG_BITS;

    typedef enum bit [1:0] {
        NOP   = 2'd0,
        LOAD  = 2'd1,
        STORE = 2'd2
    } mpu_operation_e;

    typedef enum bit {
        LOAD_IDLE   = 1'b0,
        LOAD_MATRIX = 1'b1
    } load_state_e;

    typedef enum bit {
        STORE_IDLE   = 1'b0,
        STORE_MATRIX = 1'b1
    } store_state_e;


    // Bus sequence item struct
    typedef struct packed {
        // Request fields
        mpu_operation_e op;
        bit [0:NUM_ELEMENTS-1][FPBITS:0] matrix_in;
        bit [MBITS:0] m_in;
        bit [NBITS:0] n_in;
        bit [MATRIX_REG_BITS:0] matrix_addr;
      
        // Response fields
        bit [0:NUM_ELEMENTS-1][FPBITS:0] matrix_out;
    } mpu_data_sp;

endpackage : mpu_pkg


// Testbench functions and tasks
package testbench_utilities;

    import global_defs::NUM_ELEMENTS;
    import global_defs::FPBITS;
    import global_defs::MATRIX_REGISTERS;
    import global_defs::M;
    import global_defs::N;
    import mpu_pkg::mpu_data_sp;

    task generate_matrix(input shortreal seed, input shortreal scale, output mpu_data_sp genmat);
        for (int i = 0; i < NUM_ELEMENTS; i = i + 1) begin
            genmat.matrix_in = {(genmat.matrix_in), $shortrealtobits(seed + i * scale)};
        end
    endtask : generate_matrix

    // Matrix Output
    task show_matrix(input bit [0:NUM_ELEMENTS-1][FPBITS:0] matrix_in);
        bit [FPBITS:0] matrix [NUM_ELEMENTS];
        {>>{matrix}} = matrix_in;
        if (NUM_ELEMENTS == 4) begin
            $display("\t2x2 MATRIX REGISTER\n\t %f\t%f \n\t %f\t%f \n", 
                        $bitstoshortreal(matrix[0]),
                        $bitstoshortreal(matrix[1]),
                        $bitstoshortreal(matrix[2]),
                        $bitstoshortreal(matrix[3]));
        end
        else if (NUM_ELEMENTS == 9) begin
            $display("\t3x3 MATRIX REGISTER\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                        $bitstoshortreal(matrix[0]),
                        $bitstoshortreal(matrix[1]),
                        $bitstoshortreal(matrix[2]),
                        $bitstoshortreal(matrix[3]),
                        $bitstoshortreal(matrix[4]),
                        $bitstoshortreal(matrix[5]),
                        $bitstoshortreal(matrix[6]),
                        $bitstoshortreal(matrix[7]),
                        $bitstoshortreal(matrix[8]));
        end
    endtask : show_matrix

    function void display_message(input string message);
        static int number_of_dashes, i;
        number_of_dashes = message.len() + 2;
        $write("\n");
        $write("\t ");
        for (i = 0; i < number_of_dashes; ++i) 
            $write("-");
        $write("\n\t| %s |\n", message);
        $write("\t ");
        for (i = 0; i < number_of_dashes; ++i) 
            $write("-");
        $write("\n");
    endfunction : display_message

    // Internal Register Dump   SIMULATION ONLY
    task simulation_register_dump(bit [FPBITS:0] matrix_register_array [MATRIX_REGISTERS][M][N]);
        display_message("REGISTER DUMP");
        $display("\t3x3 MATRIX REGISTER[0]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[0][0][0]),
                    $bitstoshortreal(matrix_register_array[0][0][1]),
                    $bitstoshortreal(matrix_register_array[0][0][2]),
                    $bitstoshortreal(matrix_register_array[0][1][0]),
                    $bitstoshortreal(matrix_register_array[0][1][1]),
                    $bitstoshortreal(matrix_register_array[0][1][2]),
                    $bitstoshortreal(matrix_register_array[0][2][0]),
                    $bitstoshortreal(matrix_register_array[0][2][1]),
                    $bitstoshortreal(matrix_register_array[0][2][2]));
        $display("\t3x3 MATRIX REGISTER[1]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[1][0][0]),
                    $bitstoshortreal(matrix_register_array[1][0][1]),
                    $bitstoshortreal(matrix_register_array[1][0][2]),
                    $bitstoshortreal(matrix_register_array[1][1][0]),
                    $bitstoshortreal(matrix_register_array[1][1][1]),
                    $bitstoshortreal(matrix_register_array[1][1][2]),
                    $bitstoshortreal(matrix_register_array[1][2][0]),
                    $bitstoshortreal(matrix_register_array[1][2][1]),
                    $bitstoshortreal(matrix_register_array[1][2][2]));
        $display("\t3x3 MATRIX REGISTER[2]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[2][0][0]),
                    $bitstoshortreal(matrix_register_array[2][0][1]),
                    $bitstoshortreal(matrix_register_array[2][0][2]),
                    $bitstoshortreal(matrix_register_array[2][1][0]),
                    $bitstoshortreal(matrix_register_array[2][1][1]),
                    $bitstoshortreal(matrix_register_array[2][1][2]),
                    $bitstoshortreal(matrix_register_array[2][2][0]),
                    $bitstoshortreal(matrix_register_array[2][2][1]),
                    $bitstoshortreal(matrix_register_array[2][2][2]));
        $display("\t3x3 MATRIX REGISTER[3]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[3][0][0]),
                    $bitstoshortreal(matrix_register_array[3][0][1]),
                    $bitstoshortreal(matrix_register_array[3][0][2]),
                    $bitstoshortreal(matrix_register_array[3][1][0]),
                    $bitstoshortreal(matrix_register_array[3][1][1]),
                    $bitstoshortreal(matrix_register_array[3][1][2]),
                    $bitstoshortreal(matrix_register_array[3][2][0]),
                    $bitstoshortreal(matrix_register_array[3][2][1]),
                    $bitstoshortreal(matrix_register_array[3][2][2]));
        $display("\t3x3 MATRIX REGISTER[4]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[4][0][0]),
                    $bitstoshortreal(matrix_register_array[4][0][1]),
                    $bitstoshortreal(matrix_register_array[4][0][2]),
                    $bitstoshortreal(matrix_register_array[4][1][0]),
                    $bitstoshortreal(matrix_register_array[4][1][1]),
                    $bitstoshortreal(matrix_register_array[4][1][2]),
                    $bitstoshortreal(matrix_register_array[4][2][0]),
                    $bitstoshortreal(matrix_register_array[4][2][1]),
                    $bitstoshortreal(matrix_register_array[4][2][2]));
        $display("\t3x3 MATRIX REGISTER[5]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[5][0][0]),
                    $bitstoshortreal(matrix_register_array[5][0][1]),
                    $bitstoshortreal(matrix_register_array[5][0][2]),
                    $bitstoshortreal(matrix_register_array[5][1][0]),
                    $bitstoshortreal(matrix_register_array[5][1][1]),
                    $bitstoshortreal(matrix_register_array[5][1][2]),
                    $bitstoshortreal(matrix_register_array[5][2][0]),
                    $bitstoshortreal(matrix_register_array[5][2][1]),
                    $bitstoshortreal(matrix_register_array[5][2][2]));
        $display("\t3x3 MATRIX REGISTER[6]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[6][0][0]),
                    $bitstoshortreal(matrix_register_array[6][0][1]),
                    $bitstoshortreal(matrix_register_array[6][0][2]),
                    $bitstoshortreal(matrix_register_array[6][1][0]),
                    $bitstoshortreal(matrix_register_array[6][1][1]),
                    $bitstoshortreal(matrix_register_array[6][1][2]),
                    $bitstoshortreal(matrix_register_array[6][2][0]),
                    $bitstoshortreal(matrix_register_array[6][2][1]),
                    $bitstoshortreal(matrix_register_array[6][2][2]));
        $display("\t3x3 MATRIX REGISTER[7]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[7][0][0]),
                    $bitstoshortreal(matrix_register_array[7][0][1]),
                    $bitstoshortreal(matrix_register_array[7][0][2]),
                    $bitstoshortreal(matrix_register_array[7][1][0]),
                    $bitstoshortreal(matrix_register_array[7][1][1]),
                    $bitstoshortreal(matrix_register_array[7][1][2]),
                    $bitstoshortreal(matrix_register_array[7][2][0]),
                    $bitstoshortreal(matrix_register_array[7][2][1]),
                    $bitstoshortreal(matrix_register_array[7][2][2]));
    endtask : simulation_register_dump

endpackage : testbench_utilities