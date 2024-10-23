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

// struct to store exc and int infos
typedef struct packed {
    logic [CAUSE_LEN-1:0]   cause;
    logic [XLEN-1:0]        tval;
} exc_info_s;

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

// structs taken from cva6
// for testing purpose, only necessary fields are kept
  typedef enum logic [7:0] {  // basic ALU op
    ADD,
    SUB,
    ADDW,
    SUBW,
    // logic operations
    XORL,
    ORL,
    ANDL,
    // shifts
    SRA,
    SRL,
    SLL,
    SRLW,
    SLLW,
    SRAW,
    // comparisons
    LTS,
    LTU,
    GES,
    GEU,
    EQ,
    NE,
    // jumps
    JALR,
    BRANCH,
    // set lower than operations
    SLTS,
    SLTU,
    // CSR functions
    MRET,
    SRET,
    DRET,
    ECALL,
    WFI,
    FENCE,
    FENCE_I,
    SFENCE_VMA,
    HFENCE_VVMA,
    HFENCE_GVMA,
    CSR_WRITE,
    CSR_READ,
    CSR_SET,
    CSR_CLEAR,
    // LSU functions
    LD,
    SD,
    LW,
    LWU,
    SW,
    LH,
    LHU,
    SH,
    LB,
    SB,
    LBU,
    // Hypervisor Virtual-Machine Load and Store Instructions
    HLV_B,
    HLV_BU,
    HLV_H,
    HLV_HU,
    HLVX_HU,
    HLV_W,
    HLVX_WU,
    HSV_B,
    HSV_H,
    HSV_W,
    HLV_WU,
    HLV_D,
    HSV_D,
    // Atomic Memory Operations
    AMO_LRW,
    AMO_LRD,
    AMO_SCW,
    AMO_SCD,
    AMO_SWAPW,
    AMO_ADDW,
    AMO_ANDW,
    AMO_ORW,
    AMO_XORW,
    AMO_MAXW,
    AMO_MAXWU,
    AMO_MINW,
    AMO_MINWU,
    AMO_SWAPD,
    AMO_ADDD,
    AMO_ANDD,
    AMO_ORD,
    AMO_XORD,
    AMO_MAXD,
    AMO_MAXDU,
    AMO_MIND,
    AMO_MINDU,
    // Multiplications
    MUL,
    MULH,
    MULHU,
    MULHSU,
    MULW,
    // Divisions
    DIV,
    DIVU,
    DIVW,
    DIVUW,
    REM,
    REMU,
    REMW,
    REMUW,
    // Floating-Point Load and Store Instructions
    FLD,
    FLW,
    FLH,
    FLB,
    FSD,
    FSW,
    FSH,
    FSB,
    // Floating-Point Computational Instructions
    FADD,
    FSUB,
    FMUL,
    FDIV,
    FMIN_MAX,
    FSQRT,
    FMADD,
    FMSUB,
    FNMSUB,
    FNMADD,
    // Floating-Point Conversion and Move Instructions
    FCVT_F2I,
    FCVT_I2F,
    FCVT_F2F,
    FSGNJ,
    FMV_F2X,
    FMV_X2F,
    // Floating-Point Compare Instructions
    FCMP,
    // Floating-Point Classify Instruction
    FCLASS,
    // Vectorial Floating-Point Instructions that don't directly map onto the scalar ones
    VFMIN,
    VFMAX,
    VFSGNJ,
    VFSGNJN,
    VFSGNJX,
    VFEQ,
    VFNE,
    VFLT,
    VFGE,
    VFLE,
    VFGT,
    VFCPKAB_S,
    VFCPKCD_S,
    VFCPKAB_D,
    VFCPKCD_D,
    // Offload Instructions to be directed into cv_x_if
    OFFLOAD,
    // Or-Combine and REV8
    ORCB,
    REV8,
    // Bitwise Rotation
    ROL,
    ROLW,
    ROR,
    RORI,
    RORIW,
    RORW,
    // Sign and Zero Extend
    SEXTB,
    SEXTH,
    ZEXTH,
    // Count population
    CPOP,
    CPOPW,
    // Count Leading/Training Zeros
    CLZ,
    CLZW,
    CTZ,
    CTZW,
    // Carry less multiplication Op's
    CLMUL,
    CLMULH,
    CLMULR,
    // Single bit instructions Op's
    BCLR,
    BCLRI,
    BEXT,
    BEXTI,
    BINV,
    BINVI,
    BSET,
    BSETI,
    // Integer minimum/maximum
    MAX,
    MAXU,
    MIN,
    MINU,
    // Shift with Add Unsigned Word and Unsigned Word Op's (Bitmanip)
    SH1ADDUW,
    SH2ADDUW,
    SH3ADDUW,
    ADDUW,
    SLLIUW,
    // Shift with Add (Bitmanip)
    SH1ADD,
    SH2ADD,
    SH3ADD,
    // Bitmanip Logical with negate op (Bitmanip)
    ANDN,
    ORN,
    XNOR,
    // Accelerator operations
    ACCEL_OP,
    ACCEL_OP_FS1,
    ACCEL_OP_FD,
    ACCEL_OP_LOAD,
    ACCEL_OP_STORE,
    // Zicond instruction
    CZERO_EQZ,
    CZERO_NEZ
  } fu_op;

typedef struct packed {
    logic [XLEN-1:0]    pc; // PC of instruction
    fu_op               op; // operation to perform in each functional unit
    logic               valid; // is the result valid
    logic               is_compressed; // signals a compressed instructions
} scoreboard_entry_t;

typedef struct packed {
    logic [CAUSE_LEN-1:0]   cause; // cause of exception
    logic [XLEN-1:0]        tval; // additional information of causing exception (e.g.: instruction causing it),
    logic                   valid;
} exception_t;

typedef struct packed {
    logic   valid; // prediction with all its values is valid
    logic   is_taken; // branch is taken
} bp_resolve_t;

endpackage