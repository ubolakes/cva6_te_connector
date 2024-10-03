// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import mure_pkg::*;

module tb_fsm ();

    logic clk;
    logic reset;

    // inputs
    uop_entry_s uop_entry_i;

    // outputs
    logic                   valid_o;
    logic [IRETIRE_LEN-1:0] iretire_o;
    logic                   ilastsize_o;
    logic [ITYPE_LEN-1:0]   itype_o;
    logic [CAUSE_LEN-1:0]   cause_o;
    logic [XLEN-1:0]        tval_o;
    logic [PRIV_LEN-1:0]    priv_o;
    logic [XLEN-1:0]        iaddr_o;

    // testing only outputs
    logic                   expected_valid;
    logic [IRETIRE_LEN-1:0] expected_iretire;
    logic                   expected_ilastsize;
    logic [ITYPE_LEN-1:0]   expected_itype;
    logic [CAUSE_LEN-1:0]   expected_cause;
    logic [XLEN-1:0]        expected_tval;
    logic [PRIV_LEN-1:0]    expected_priv;
    logic [XLEN-1:0]        expected_iaddr;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    fsm DUT (
        .clk_i       (clk),
        .rst_ni      (reset),
        .uop_entry_i(uop_entry_i),
        .valid_o     (valid_o),
        .iretire_o   (iretire_o),
        .ilastsize_o (ilastsize_o),
        .itype_o     (itype_o),
        .cause_o     (cause_o),
        .tval_o      (tval_o),
        .priv_o      (priv_o),
        .iaddr_o     (iaddr_o)
    );

    logic [218:0] test_vector[1000:0];

    initial begin
        $readmemb("tv_fsm", test_vector);
        i = 0;
        reset = 0; #10;
        reset = 1;   
    end

    always @(posedge clk) begin // on posedge we get expected output
        {
            uop_entry_i,
            expected_valid,
            expected_iretire,
            expected_ilastsize,
            expected_itype,
            expected_cause,
            expected_tval,
            expected_priv,
            expected_iaddr
        } = test_vector[i]; #10; 
    end

    always @(negedge clk) begin// on negedge we compare the expected result with the actual one
        // valid_o
        if(expected_valid !== valid_o) begin
            $display("Wrong valid: %b!=%b", expected_valid, valid_o);
        end
        // iretire_o
        if(expected_iretire !== iretire_o) begin
            $display("Wrong iretire: %b!=%b", expected_iretire, iretire_o);
        end  
        // ilastsize_o
        if(expected_ilastsize !== ilastsize_o) begin
            $display("Wrong ilastsize: %b!=%b", expected_ilastsize, ilastsize_o);
        end
        // itype_o
        if(expected_itype !== itype_o) begin
            $display("Wrong itype: %b!=%b", expected_itype, itype_o);
        end  
        // cause
        if(expected_cause !== cause_o) begin
            $display("Wrong cause: %b!=%b", expected_cause, cause_o);
        end
        // tval_o
        if(expected_tval !== tval_o) begin
            $display("Wrong tval: %b!=%b", expected_tval, tval_o);
        end 
        // priv_o
        if(expected_priv !== priv_o) begin
            $display("Wrong priv: %b!=%b", expected_priv, priv_o);
        end  
        // iaddr_o
        if(expected_iaddr !== iaddr_o) begin
            $display("Wrong iaddr: %b!=%b", expected_iaddr, iaddr_o);
        end   

        // index increase
        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end





endmodule