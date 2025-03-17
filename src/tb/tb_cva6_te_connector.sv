// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at

// https://solderpad.org/licenses/SHL-2.1/

// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions and 
// limitations under the License.

// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import connector_pkg::*;

localparam NRET = 2;
localparam N = 2;

module tb_cva6_te_connector();

    logic clk;
    logic reset;

    // inputs
    logic [NRET-1:0]                valid_i;
    scoreboard_entry_t [NRET-1:0]   commit_instr_i;
    bp_resolve_t                    resolved_branch_i;
    exception_t                     exception_i;
    logic                           interrupt_i;
    logic [PRIV_LEN-1:0]            priv_lvl_i;

    // outputs
    logic [N-1:0]                   valid_o;
    logic [N-1:0][IRETIRE_LEN-1:0]  iretire_o;
    logic [N-1:0]                   ilastsize_o;
    logic [N-1:0][ITYPE_LEN-1:0]    itype_o;
    logic [XLEN-1:0]                cause_o;
    logic [XLEN-1:0]                tval_o;
    logic [PRIV_LEN-1:0]            priv_o;
    logic [N-1:0][XLEN-1:0]         iaddr_o;

    // testing only outputs
    logic [N-1:0]                   expected_valid;
    logic [N-1:0][IRETIRE_LEN-1:0]  expected_iretire;
    logic [N-1:0]                   expected_ilastsize;
    logic [N-1:0][ITYPE_LEN-1:0]    expected_itype;
    logic [XLEN-1:0]                expected_cause;
    logic [XLEN-1:0]                expected_tval;
    logic [PRIV_LEN-1:0]            expected_priv;
    logic [N-1:0][XLEN-1:0]         expected_iaddr;

    // iteration variable
    logic [31:0] i;

    // DUT instantiation
    cva6_te_connector #(
        .NRET(NRET),
        .N(N)
    ) DUT(
        .clk_i            (clk),
        .rst_ni           (reset),
        .valid_i          (valid_i),
        .commit_instr_i   (commit_instr_i),
        .resolved_branch_i(resolved_branch_i),
        .exception_i      (exception_i),
        .interrupt_i      (interrupt_i),
        .priv_lvl_i       (priv_lvl_i),
        .valid_o          (valid_o),
        .iretire_o        (iretire_o),
        .ilastsize_o      (ilastsize_o),
        .itype_o          (itype_o),
        .cause_o          (cause_o),
        .tval_o           (tval_o),
        .priv_o           (priv_o),
        .iaddr_o          (iaddr_o)
    );

    logic [305:0] test_vector[1000:0];
    //    length of line   # of lines

    initial begin // reading test vector
        $readmemb("tv_cva6_te_connector", test_vector);
        i = 0;
        reset = 0; #10;
        reset = 1;            
    end

    always @(posedge clk) begin // on posedge we get expected output
        {
            valid_i,
            commit_instr_i,
            resolved_branch_i,
            exception_i,
            interrupt_i,
            priv_lvl_i,
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