// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* ITYPE DETECTOR */
/*
it produces the type of the instruction
*/

module itype_detector
(
    input logic                     clk_i,
    input logic                     rst_ni,

    input mure_pkg::fifo_entry_s    lc_fifo_entry_i,
    input mure_pkg::fifo_entry_s    tc_fifo_entry_i,
    input mure_pkg::fifo_entry_s    nc_fifo_entry_i,
        
    output mure_pkg::fifo_entry_s   tc_fifo_entry_o    
);
    /*  EXPLANATION:
        This module considers the lc, tc, nc signals and determines
        how many cycles an address remains.
        In case an address remains more cycles, the signal that 
        communicates wether is a branch or not is delayed to be 
        synchronous with the branch_taken signal.
    */

    // signals declaration
    logic                       lc_valid;
    logic                       tc_valid;
    logic                       nc_valid;
    logic [mure_pkg::XLEN-1:0]  lc_pc;
    logic [mure_pkg::XLEN-1:0]  tc_pc;
    logic [mure_pkg::XLEN-1:0]  nc_pc;
    logic [mure_pkg::XLEN-1:0]  tc_inst_data;
    logic                       tc_compressed;
    logic                       tc_exception;
    logic                       tc_interrupt;
    logic                       tc_eret;
    logic                       tc_branch;
    logic                       tc_branch_taken;
    logic                       tc_updiscon;
    logic                       is_c_jalr;
    logic                       is_c_jr;
    logic                       tc_is_jump;
    logic                       tc_nc_valid;
    logic                       one_cycle;
    logic                       more_cycles;
    logic                       tc_branch_d, tc_branch_q;
    logic                       tc_updiscon_d, tc_updiscon_q;

    // assignments
    assign lc_valid = lc_fifo_entry_i.valid;
    assign tc_valid = tc_fifo_entry_i.valid;
    assign nc_valid = nc_fifo_entry_i.valid;
    assign lc_pc = lc_fifo_entry_i.pc;
    assign tc_pc = tc_fifo_entry_i.pc;
    assign nc_pc = nc_fifo_entry_i.pc;
    assign tc_inst_data = tc_fifo_entry_i.inst_data;
    assign tc_compressed = tc_fifo_entry_i.compressed;
    assign tc_exception = tc_fifo_entry_i.exception;
    assign tc_interrupt = tc_fifo_entry_i.interrupt;
    assign tc_eret = tc_fifo_entry_i.eret;
    assign tc_nc_valid = tc_valid && nc_valid;
    assign one_cycle = tc_pc != nc_pc && tc_pc != lc_pc;
    assign more_cycles = tc_pc != nc_pc && tc_pc == lc_pc;
    assign tc_branch_d =    (((tc_inst_data & mure_pkg::MASK_BEQ)      == mure_pkg::MATCH_BEQ) ||
                             ((tc_inst_data & mure_pkg::MASK_BNE)      == mure_pkg::MATCH_BNE) ||
                             ((tc_inst_data & mure_pkg::MASK_BLT)      == mure_pkg::MATCH_BLT) ||
                             ((tc_inst_data & mure_pkg::MASK_BGE)      == mure_pkg::MATCH_BGE) ||
                             ((tc_inst_data & mure_pkg::MASK_BLTU)     == mure_pkg::MATCH_BLTU) ||
                             ((tc_inst_data & mure_pkg::MASK_BGEU)     == mure_pkg::MATCH_BGEU) ||
                             ((tc_inst_data & mure_pkg::MASK_P_BNEIMM) == mure_pkg::MATCH_P_BNEIMM) ||
                             ((tc_inst_data & mure_pkg::MASK_P_BEQIMM) == mure_pkg::MATCH_P_BEQIMM) ||
                             ((tc_inst_data & mure_pkg::MASK_C_BEQZ)   == mure_pkg::MATCH_C_BEQZ) ||
                             ((tc_inst_data & mure_pkg::MASK_C_BNEZ)   == mure_pkg::MATCH_C_BNEZ)) && 
                            tc_valid;
    assign tc_branch_taken =    (tc_compressed ?
                                !(tc_pc + 2 == nc_pc) :
                                !(tc_pc + 4 == nc_pc)) &&
                                tc_nc_valid && (more_cycles || one_cycle);
    // compressed inst
    /* c.jalr and c.jr are both decompressed in order to use an uncompressed jalr */
    assign is_c_jalr = ((nc_inst_data & MASK_C_JALR) == MATCH_C_JALR)
                         && ((nc_inst_data & MASK_RD) != 0);
    assign is_c_jr = ((nc_inst_data & MASK_C_JR) == MATCH_C_JR)
                       && ((nc_inst_data & MASK_RD) != 0);
    // non compressed inst
    assign tc_is_jump = ((tc_inst_data & mure_pkg::MASK_JALR) == mure_pkg::MATCH_JALR) &&
                        tc_valid || is_c_jalr || is_c_jr;
    assign tc_updiscon_d = (tc_is_jump || tc_exception) &&
                            tc_valid; // || nc_interrupt - not necessary in snitch since it's coupled w/exception
    assign tc_updiscon = (one_cycle || more_cycles) ? tc_updiscon_d : 0;
    assign tc_branch = (one_cycle || more_cycles) ? tc_branch_d : 0;
    assign tc_fifo_entry_o = tc_fifo_entry_i;

    // assigning the itype
    always_comb begin
        // initialization
        itype = mure_pkg::STD;

        if (tc_exception) begin // exception
            itype = mure_pkg::EXC;
        end else if (tc_interrupt) begin // interrupt
            itype = mure_pkg::INT;
        end else if (tc_eret) begin // exception or interrupt return
            itype = mure_pkg::ERET;
        end else if (tc_branch && ~tc_branch_taken) begin // nontaken branch
            itype = mure_pkg::NTB;
        end else if (tc_branch && tc_branch_taken) begin // taken branch
            itype = mure_pkg::TB;
        end else if (mure_pkg::ITYPE_LEN == 3 && tc_updiscon) begin // uninferable jump
            itype = mure_pkg::UIJ;
        end else if (mure_pkg::ITYPE_LEN > 3) begin // reserved
            itype = mure_pkg::RES;
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
            itype = UIJ;
        end
        // inferable jump
        if () begin
            itype = IJ;
        end
        // co-routine swap
        if () begin
            itype = CRS;
        end
        // return
        if () begin
            itype = RET;
        end
        // other uninferable jump
        if () begin
            itype = OUIJ;
        end
        // other inferable jump
        if () begin
            itype = OIJ;
        end
        */

        tc_fifo_entry_i.itype = itype;
    end

    always_ff @( posedge clk_i, negedge rst_ni ) begin
        if(~rst_ni) begin
            tc_branch_q <= '0;
            tc_updiscon_q <= '0;
        end else if (more_cycles) begin
            tc_branch_q <= tc_branch_d;
            tc_updiscon_q <= tc_updiscon_d;
        end
    end

endmodule