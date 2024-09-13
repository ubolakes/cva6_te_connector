// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

package mure_pkg;
    localparam CAUSE_LEN = 5;
    localparam PRIV_LEN = 2; // depends on CPU implementation
    localparam INST_LEN = 32;
    localparam ILASTSIZE_LEN = 2;
    localparam ITYPE_LEN = 4;
`ifdef TRDB_ARCH64 // 64bit arch specific parameters
    localparam XLEN = 64;
`else // 32bit arch
    localparam XLEN = 32;
`endif

// struct to store data inside the common FIFO
typedef struct packed {
    logic [mure_pkg::CAUSE_LEN-1:0] cause;
    logic [mure_pkg::XLEN-1:0]      tval;
    logic [mure_pkg::PRIV_LEN-1:0]  priv;
    //logic [] context; // non mandatory
    //logic [] ctype;   // non mandatory
} common_entry_s;

// struct to store data inside the uop FIFO
typedef struct packed {
    itype_e                             itype;
    logic [mure_pkg::INST_LEN-1:0]      iaddr;
    logic                               iretire;
    logic [mure_pkg::ILASTSIZE_LEN-1:0] ilastsize;
} uop_entry_s;

// struct to save all itypes
// refer to page 21 of the spec
typedef enum logic[ITYPE_LEN-1:0] {
    STD = 0, // none of the other named itype codes
    EXC = 1, // exception
    INT = 2, // interrupt
    ERET = 3, // exception or interrupt return
    NTB = 4, // nontaken branch
    TB = 5, // taken branch
    UJ = 6, // uninferable jump if ITYPE_LEN == 3, otherwise reserved
    RES = 7, // reserved
    UC = 8, // uninferable call
    IC = 9, // inferrable call
    UJ = 10, // uninferable jump
    IJ = 11, // inferable jump
    CRS = 12, // co-routine swap
    RET = 13, // return
    OUJ = 14, // other uninferable jump
    OIJ = 15 // other inferable jump
} itype_e;

endpackage