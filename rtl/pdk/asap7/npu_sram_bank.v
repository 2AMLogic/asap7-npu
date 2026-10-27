// npu_sram_bank -- ASAP7 black-box seam for the abstract memory macro.
//
// AUTHORED IN THIS REPO. This is NOT a stamped file: the origin's
// rtl/pdk/sky130/npu_sram_bank.v is the sky130 seam and is not stamped here
// ("A port replaces this directory"). This module keeps the origin's port list
// and timing contract and declares the bank as a black box for synthesis,
// consistent with decision 0002 (proposed): on-chip memory is an abstract macro
// view, black-boxed in synthesis, DRC and LVS. There is no SRAM bitcell here.
//
// Timing contract (same as the origin's seam):
//   * both ports are synchronous; read data is valid in the cycle AFTER the
//     address, and holds until the next enabled read on that port.
//   * RW port: rw_en with rw_we == 0 is a read; rw_we != 0 writes the masked
//     bytes (rw_we[i] enables byte i, byte 0 is bits [7:0]).
//   * R port: read only.
//   * a read and a write to the same word in the same cycle, on different
//     ports, is not used by the NPU and its result is undefined.
//
// This body has no behaviour. It is for synthesis only; simulation uses the
// origin's behavioral model.
(* blackbox *)
module npu_sram_bank #(
    parameter DEPTH_WORDS = 1024,
    parameter WORD_BITS   = 32
) (
    input  wire                         clk,

    // RW port
    input  wire                         rw_en,
    input  wire [WORD_BITS/8-1:0]       rw_we,
    input  wire [$clog2(DEPTH_WORDS)-1:0] rw_addr,
    input  wire [WORD_BITS-1:0]         rw_wdata,
    output wire [WORD_BITS-1:0]         rw_rdata,

    // R port
    input  wire                         r_en,
    input  wire [$clog2(DEPTH_WORDS)-1:0] r_addr,
    output wire [WORD_BITS-1:0]         r_rdata
);
endmodule
