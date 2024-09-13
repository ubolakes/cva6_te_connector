// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

package mure_pkg;
    localparam CAUSE_LEN = 5;
    localparam PRIV_LEN = 2; // depends on CPU implementation
    localparam INST_LEN = 32;
`ifdef TRDB_ARCH64 // 64bit arch specific parameters
    localparam XLEN = 64;
`else // 32bit arch
    localparam XLEN = 32;
`endif

endpackage