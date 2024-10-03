// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

package mure_pkg;
    localparam CAUSE_LEN = 5;
    localparam PRIV_LEN = 2; // depends on CPU implementation
    localparam INST_LEN = 32;
    localparam ITYPE_LEN = 3;
    localparam IRETIRE_LEN = 32;
`ifdef TRDB_ARCH64 // 64bit arch specific parameters
    localparam XLEN = 64;
`else // 32bit arch
    localparam XLEN = 32;
`endif

// struct to save all itypes
// refer to page 21 of the spec
typedef enum logic[ITYPE_LEN-1:0] {
    STD = 0, // none of the other named itype codes
    EXC = 1, // exception
    INT = 2, // interrupt
    ERET = 3, // exception or interrupt return
    NTB = 4, // nontaken branch
    TB = 5, // taken branch
    UIJ = 6, // uninferable jump if ITYPE_LEN == 3, otherwise reserved
    RES = 7 /*, // reserved
    UC = 8, // uninferable call
    IC = 9, // inferable call
    UIJ = 10, // uninferable jump
    IJ = 11, // inferable jump
    CRS = 12, // co-routine swap
    RET = 13, // return
    OUIJ = 14, // other uninferable jump
    OIJ = 15*/ // other inferable jump
} itype_e;

// struct to store data inside the uop FIFO
typedef struct packed {
    logic                   valid;
    logic [XLEN-1:0]        pc;
    logic [INST_LEN-1:0]    inst_data;
    logic [ITYPE_LEN-1:0]   itype; // determined in itype detector
    logic                   compressed;
    logic                   exception;
    logic                   interrupt;
    logic                   eret;
    logic [CAUSE_LEN-1:0]   cause;
    logic [XLEN-1:0]        tval;
    logic [PRIV_LEN-1:0]    priv;
    // TODO: add eret
    //logic []                context; // non mandatory
    //logic []                ctype;   // non mandatory
    //logic []                time; // non mandatory
    //logic []                sijump; // non mandatory
} uop_entry_s;

// states definition for FSM
typedef enum logic { 
    IDLE = 0,
    COUNT = 1
} state_e;

/* mask and match parameter for itype determination */
parameter MASK_BEQ = 32'h707f;
parameter MATCH_BEQ = 32'h63;
parameter MASK_BNE = 32'h707f;
parameter MATCH_BNE = 32'h1063;
parameter MASK_BLT = 32'h707f;
parameter MATCH_BLT = 32'h4063;
parameter MASK_BGE = 32'h707f;
parameter MATCH_BGE = 32'h5063;
parameter MASK_BLTU = 32'h707f;
parameter MATCH_BLTU = 32'h6063;
parameter MASK_BGEU = 32'h707f;
parameter MATCH_BGEU = 32'h7063;
parameter MASK_P_BNEIMM = 32'h707f;
parameter MATCH_P_BNEIMM = 32'h3063;
parameter MASK_P_BEQIMM = 32'h707f;
parameter MATCH_P_BEQIMM = 32'h2063;
parameter MASK_C_BEQZ = 32'he003;
parameter MATCH_C_BEQZ = 32'hc001;
parameter MASK_C_BNEZ = 32'he003;
parameter MATCH_C_BNEZ = 32'he001;
parameter MASK_C_JALR = 32'hf07f;
parameter MATCH_C_JALR = 32'h9002;
parameter MASK_RD = 32'hf80;
parameter MASK_C_JR = 32'hf07f;
parameter MATCH_C_JR = 32'h8002;
parameter MASK_JALR = 32'h707f;
parameter MATCH_JALR = 32'h67;
parameter MASK_MRET = 32'hffffffff;
parameter MATCH_MRET = 32'h30200073;
parameter MASK_SRET = 32'hffffffff;
parameter MATCH_SRET = 32'h10200073;
parameter MASK_URET = 32'hffffffff;
parameter MATCH_URET = 32'h200073;
parameter MASK_RS1 = 32'hf8000;
parameter MASK_IMM = 32'hfff00000;
parameter X_RA = 32'h1;
parameter OP_SH_RS1 = 32'd15;
parameter OP_SH_RD = 32'd7;

endpackage