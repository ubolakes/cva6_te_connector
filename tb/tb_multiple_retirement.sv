// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import mure_pkg::*;

module tb_multiple_retirement();

    logic clk;
    logic reset;

    // inputs
    logic [NrRetiredInstr-1:0]                  iretire_i;
    logic [NrRetiredInstr-1:0]                  ilastsize_i;
    logic [NrRetiredInstr-1:0][ITYPE_LEN-1:0]   itype_i;
    logic [CAUSE_LEN-1:0]                       cause_i;
    logic [TVAL_LEN-1:0]                        tval_i;
    logic [PRIV_LEN-1:0]                        priv_i;
    logic [NrRetiredInstr-1:0][XLEN-1:0]        iaddr_i;

    // outputs
    logic                                       iretire_o;
    logic                                       ilastsize_o;
    logic [ITYPE_LEN-1:0]                       itype_o;
    logic [CAUSE_LEN-1:0]                       cause_o;
    logic [TVAL_LEN-1:0]                        tval_o;
    logic [PRIV_LEN-1:0]                        priv_o;
    logic [XLEN-1:0]                            iaddr_o;

    // testing only outputs
    logic                                       expected_iretire;
    logic                                       expected_ilastsize;
    logic [ITYPE_LEN-1:0]                       expected_itype;
    logic [CAUSE_LEN-1:0]                       expected_cause;
    logic [TVAL_LEN-1:0]                        expected_tval;
    logic [PRIV_LEN-1:0]                        expected_priv;
    logic [XLEN-1:0]                            expected_iaddr;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    multiple_retire DUT(
        .clk_i      (clk),
        .rst_ni     (reset),
        .iretire_i  (iretire_i),
        .ilastsize_i(ilastsize_i),
        .itype_i    (itype_i),
        .cause_i    (cause_i),
        .tval_i     (tval_i),
        .priv_i     (priv_i),
        .iaddr_i    (iaddr_i),
        .iretire_o  (iretire_o),
        .ilastsize_o(ilastsize_o),
        .itype_o    (itype_o),
        .cause_o    (cause_o),
        .tval_o     (tval_o),
        .priv_o     (priv_o),
        .iaddr_o    (iaddr_o)
    );

    logic [XX:0] test_vector[1000:0];
    //    length of line   # of lines

    initial begin // reading test vector
        $readmemb("tv_multiple_retire", test_vector);
        i = 0;
        //reset = 0; #10;
        reset = 1;            
    end

    always @(posedge clk) begin // on posedge we get expected output
        {
            iretire_i,
            ilastsize_i,
            itype_i,
            cause_i,
            tval_i,
            priv_i,
            iaddr_i,
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