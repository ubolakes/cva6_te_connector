// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* ITYPE DETECTOR */
/*
it produces the type of the instruction and gives other infos about it
*/

module trdb_itype_detector
(
    input logic                         clk_i,
    input logic                         rst_ni,

    input logic                         pc_valid_i,
    input logic                         cc_valid_i,
    input logic                         nc_valid_i,
    input logic [mure_pkg::XLEN-1:0]    pc_iaddr_i,
    input logic [mure_pkg::XLEN-1:0]    cc_iaddr_i,
    input logic [mure_pkg::XLEN-1:0]    nc_iaddr_i,
    input logic [mure_pkg::XLEN-1:0]    cc_inst_data_i,
    input logic                         cc_compressed_i,
    input logic                         cc_exception_i,
    input logic                         cc_interrupt_i,
    input logic                         cc_eret_i,
    //input logic                         implicit_return_i, // non mandatory
    
    output mure_pkg::itype_e            itype_o
);
    /*  EXPLANATION:
        This module considers the lc, tc, nc signals and determines
        how many cycles an address remains.
        In case an address remains more cycles, the signal that 
        communicates wether is a branch or not is delayed to be 
        synchronous with the branch_taken signal.
    */

    logic cc_branch;
    logic cc_branch_taken;
    logic cc_updiscon;
    //logic is_c_jalr;
    //logic is_c_jr;
    logic cc_is_jump;
    logic cc_nc_valid;
    logic one_cycle;
    logic more_cycles;
    logic cc_branch_d, cc_branch_q;
    logic cc_updiscon_d, cc_updiscon_q;

    assign cc_nc_valid = cc_valid_i && nc_valid_i;
    assign one_cycle = cc_iaddr_i != nc_iaddr_i && cc_iaddr_i != pc_iaddr_i;
    assign more_cycles = cc_iaddr_i != nc_iaddr_i && cc_iaddr_i == pc_iaddr_i;
    assign cc_branch_d =    (((cc_inst_data_i & mure_pkg::MASK_BEQ)      == mure_pkg::MATCH_BEQ) ||
                             ((cc_inst_data_i & mure_pkg::MASK_BNE)      == mure_pkg::MATCH_BNE) ||
                             ((cc_inst_data_i & mure_pkg::MASK_BLT)      == mure_pkg::MATCH_BLT) ||
                             ((cc_inst_data_i & mure_pkg::MASK_BGE)      == mure_pkg::MATCH_BGE) ||
                             ((cc_inst_data_i & mure_pkg::MASK_BLTU)     == mure_pkg::MATCH_BLTU) ||
                             ((cc_inst_data_i & mure_pkg::MASK_BGEU)     == mure_pkg::MATCH_BGEU) ||
                             ((cc_inst_data_i & mure_pkg::MASK_P_BNEIMM) == mure_pkg::MATCH_P_BNEIMM) ||
                             ((cc_inst_data_i & mure_pkg::MASK_P_BEQIMM) == mure_pkg::MATCH_P_BEQIMM) ||
                             ((cc_inst_data_i & mure_pkg::MASK_C_BEQZ)   == mure_pkg::MATCH_C_BEQZ) ||
                             ((cc_inst_data_i & mure_pkg::MASK_C_BNEZ)   == mure_pkg::MATCH_C_BNEZ)) && 
                            cc_valid_i;
    assign cc_branch_taken =    (cc_compressed_i ?
                                !(cc_iaddr_i + 2 == nc_iaddr_i) :
                                !(cc_iaddr_i + 4 == nc_iaddr_i)) &&
                                cc_nc_valid && (more_cycles || one_cycle);
    // compressed inst - not supported by snitch
    /* c.jalr and c.jr are both decompressed in order to use an uncompressed jalr */
    /*assign is_c_jalr = ((nc_inst_data_i & MASK_C_JALR) == MATCH_C_JALR)
                         && ((nc_inst_data_i & MASK_RD) != 0);
    assign is_c_jr = ((nc_inst_data_i & MASK_C_JR) == MATCH_C_JR)
                       && ((nc_inst_data_i & MASK_RD) != 0);*/
    // non compressed inst
    assign cc_is_jump = ((cc_inst_data_i & mure_pkg::MASK_JALR) == mure_pkg::MATCH_JALR) &&
                        cc_valid_i; /* || is_c_jalr || is_c_jr*/;
    assign cc_updiscon_d = (cc_is_jump || cc_exception_i) &&
                            cc_valid_i; // || nc_interrupt - not necessary in snitch since it's coupled w/exception
    assign cc_updiscon = (one_cycle || more_cycles) ? cc_updiscon_d : 0;
    assign cc_branch = (one_cycle || more_cycles) ? cc_branch_d : 0;

    // assigning the itype
    always_comb begin
        // initialization
        itype_o = STD;

        // exception
        if (cc_exception_i) begin
            itype_o = EXC;
        end
        // interrupt
        if (cc_interrupt_i) begin
            itype_o = INT;
        end
        // exception or interrupt return
        if (cc_eret_i) begin
            itype_o = ERET;
        end
        // nontaken branch
        if (cc_branch && ~cc_branch_taken) begin
            itype_o = NTB;
        end
        // taken branch
        if (cc_branch && cc_branch_taken) begin
            itype_o = TB;
        end
        // uninferable jump
        if (mure_pkg::ITYPE_LEN == 3 && cc_updiscon) begin
            itype_o = UJ;
        end else if (mure_pkg::ITYPE_LEN > 3) begin // reserved
            itype_o = RES;
        end
        // other case for ITYPE_LEN == 4
        /*
        // uninferable call
        if () begin
            itype = UC;
        end
        // inferable call
        if () begin
            itype = IC;
        end
        // uninferable jump
        if () begin
            itype = UJ;
        end
        // inferable jump
        if () begin
            itype_o = IJ;
        end
        // co-routine swap
        if () begin
            itype_o = CRS;
        end
        // return
        if () begin
            itype_o = RET;
        end
        // other uninferable jump
        if () begin
            itype_o = OUJ;
        end
        // other inferable jump
        if () begin
            itype_o = OIJ;
        end
        */
    end

    always_ff @( posedge clk_i, negedge rst_ni ) begin
        if(~rst_ni) begin
            cc_branch_q <= '0;
            cc_updiscon_q <= '0;
        end else if (more_cycles) begin
            cc_branch_q <= cc_branch_d;
            cc_updiscon_q <= cc_updiscon_d;
        end
    end

endmodule