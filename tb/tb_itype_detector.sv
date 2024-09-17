// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import mure_pkg::*;

module tb_itype_detector();

    logic clk;
    logic reset;

    // inputs
    logic               pc_valid_i;
    logic               cc_valid_i;
    logic               nc_valid_i;
    logic [XLEN-1:0]    pc_iaddr_i;
    logic [XLEN-1:0]    cc_iaddr_i;
    logic [XLEN-1:0]    nc_iaddr_i;
    logic [XLEN-1:0]    cc_inst_data_i;
    logic               cc_compressed_i;
    logic               cc_exception_i;
    logic               cc_interrupt_i;
    logic               cc_eret_i;

    // outputs
    itype_e             itype_o;

    // testing only outputs
    itype_e             expected_itype;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    itype_detector DUT(
        .clk_i          (clk),
        .rst_ni         (reset),
        .pc_valid_i     (pc_valid_i),
        .cc_valid_i     (cc_valid_i),
        .nc_valid_i     (nc_valid_i),
        .pc_iaddr_i     (pc_iaddr_i),
        .cc_iaddr_i     (cc_iaddr_i),
        .nc_iaddr_i     (nc_iaddr_i),
        .cc_inst_data_i (cc_inst_data_i),
        .cc_compressed_i(cc_compressed_i),
        .cc_exception_i (cc_exception_i),
        .cc_interrupt_i (cc_interrupt_i),
        .cc_eret_i      (cc_eret_i),
        .itype_o        (itype_o)
    );

    logic [137:0] test_vector[1000:0];
    //    length of line   # of lines

    initial begin // reading test vector
        $readmemb("tv_itype_detector", test_vector);
        i = 0;
        //reset = 0; #10;
        reset = 1;            
    end

    always @(posedge clk) begin // on posedge we get expected output
        {
            pc_valid_i,
            cc_valid_i,
            nc_valid_i,
            pc_iaddr_i,
            cc_iaddr_i,
            nc_iaddr_i,
            cc_inst_data_i,
            cc_compressed_i,
            cc_exception_i,
            cc_interrupt_i,
            cc_eret_i,
            expected_itype
        } = test_vector[i]; #10; 
    end

    always @(negedge clk) begin// on negedge we compare the expected result with the actual one
        // itype_o
        if(expected_itype !== itype_o) begin
            $display("Wrong itype: %b!=%b", expected_itype, itype_o); // printed if it's wrong
        end        

        // index increase
        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end

endmodule