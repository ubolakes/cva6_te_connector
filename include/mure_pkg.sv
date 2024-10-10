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
    logic [ITYPE_LEN-1:0]   itype; // determined in itype detector
    logic                   compressed;
    logic [PRIV_LEN-1:0]    priv;
} uop_entry_s;

// states definition for FSM
typedef enum logic { 
    IDLE = 0,
    COUNT = 1
} state_e;

typedef enum logic [2:0] {
    NoCF   = 0,    // No control flow prediction
    Branch = 1,  // Branch
    Jump   = 2,    // Jump to address from immediate
    JumpR  = 3,   // Jump to address from registers
    Return = 4   // Return Address Prediction
} cf_t;

endpackage