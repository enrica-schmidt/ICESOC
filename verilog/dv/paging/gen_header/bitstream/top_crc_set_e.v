// crc32_byte_update.v
//
// Combinational CRC-32 (reflected, polynomial 0xEDB88320 — the
// Ethernet/zlib/gzip variant) byte-update engine. This is the
// circuit that gets synthesized onto the eFPGA fabric.
//
// It implements exactly the same 8-round "shift, test the bit
// that fell out, conditionally XOR the polynomial" process as the
// software bit-serial loop — just unrolled into a fixed, flat
// network of registers-worth of XOR/mux logic at elaboration time.
// There is no clock and no loop at runtime: for any given
// (crc_in, data_in) pair, crc_out is available after one
// combinational propagation delay.
//
// This is the hardware equivalent of one entry of a 256-entry
// software CRC table — except instead of storing 256 precomputed
// answers in memory, the eFPGA computes the answer for whichever
// byte shows up, on the fly, every cycle.

module top (
    input wire clk,
    input wire [35:0] W_OPA, W_OPB, E_OPA, E_OPB,
    input wire [9:0] io_in,
    output wire [35:0] W_RES0, W_RES1, W_RES2, E_RES0, E_RES1, E_RES2,
    output wire [9:0] io_out, io_oeb
);
    wire [31:0] wopa, wopb, wres0, wres1, wres2;
    wire [31:0] eopa, eopb, eres0, eres1, eres2;
    assign wopa = W_OPA[34:3];
    assign wopb = W_OPB[31:0];
    assign eopa = E_OPA[34:3];
    assign eopb = E_OPB[31:0];

    // CRC-32 word update.
    //   wopa = current running CRC (crc_in)
    //   wopb = next 4 message bytes, byte 0 (first in message order)
    //          in wopb[7:0] -- matches a plain `lw` on a little-endian
    //          RISC-V core, so no byte-swap is needed before this input.
    // wres0 carries the updated CRC back out; wres1/wres2 are unused.
    crc32_word_update u_crc (
        .crc_in  (wopa),
        .data_in (wopb),
        .crc_out (wres0)
    );

    assign wres1 = 32'h00000000;
    assign wres2 = 32'h00000000;

    assign W_RES0 = {4'b0000, wres0};
    assign W_RES1 = {4'b0000, wres1};
    assign W_RES2 = {4'b0000, wres2};

    assign eres0 = 32'h00000000;
    assign eres1 = 32'h00000000;
    assign eres2 = 32'h00000000;

    assign E_RES0 = {4'b0000, eres0};
    assign E_RES1 = {4'b0000, eres1};
    assign E_RES2 = {4'b0000, eres2};


    wire rst = io_in[0];
    wire en = io_in[1];
    reg [31:0] ctr;

    always @(posedge clk)
        if (en)
            if (rst)
                ctr <= 0;
            else
                ctr <= ctr + 1'b1;
        else
            ctr <= ctr;

    // NOTE: choose this depending if you're running a simulation or on an
    // actual chip
  
    // assign io_out[9:2] =  ctr[25:18];
    assign io_out[9:2] =  ctr[7:0];

    assign io_oeb = 10'b11_1111_1100;

    // Avoid mismatches in the simulation
    assign io_out[1:0] = 2'h0;

endmodule

// crc32_word_update.v
//
// Combinational CRC-32 (reflected, polynomial 0xEDB88320) update
// that consumes a full 32-bit word (4 message bytes) per call
// instead of one byte at a time.
//
// It's built by chaining the same byte-round logic four times:
// byte 0 folds in first, then byte 1, byte 2, byte 3 -- exactly
// what four back-to-back software byte-updates would do, just
// flattened into one combinational block with no shared state
// between calls.
//
// Byte order: data_in[7:0] is byte 0 (first in message order),
// data_in[15:8] is byte 1, data_in[23:16] is byte 2, data_in[31:24]
// is byte 3. This matches a plain `lw` on a little-endian RISC-V
// core reading 4 consecutive message bytes -- the lowest address
// byte lands in data_in[7:0], so no byte-swapping is needed between
// memory and this engine.
 
/*
module crc32_word_update (
    input  wire [31:0] crc_in,
    input  wire [31:0] data_in,
    output wire [31:0] crc_out
);
 
    localparam [31:0] POLY = 32'hEDB88320;
 
    // byte_stage[0] = crc_in, byte_stage[4] = crc_out
    wire [31:0] byte_stage [0:4];
    assign byte_stage[0] = crc_in;
 
    genvar b, i;
    generate
        for (b = 0; b < 4; b = b + 1) begin : byte_loop
 
            wire [7:0]  this_byte = data_in[b*8 +: 8];
            wire [31:0] folded    = byte_stage[b] ^ {24'b0, this_byte};
 
            // 8 rounds of shift + conditional XOR for this byte
            wire [31:0] bit_stage [0:8];
            assign bit_stage[0] = folded;
 
            for (i = 0; i < 8; i = i + 1) begin : bit_loop
                assign bit_stage[i+1] = bit_stage[i][0] ? ((bit_stage[i] >> 1) ^ POLY)
                                                          : (bit_stage[i] >> 1);
            end
 
            assign byte_stage[b+1] = bit_stage[8];
 
        end
    endgenerate
 
    assign crc_out = byte_stage[4];
 
endmodule
*/

module crc32_word_update (
    input  wire [31:0] crc_in,
    input  wire [31:0] data_in,
    output wire [31:0] crc_out
);
 
    localparam [31:0] POLY = 32'hEDB88320;
 
    // Whole-word fold, done once.
    wire [31:0] folded = crc_in ^ data_in;
 
    // stage[0] = folded, stage[32] = crc_out
    wire [31:0] stage [0:32];
    assign stage[0] = folded;
 
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : round
            assign stage[i+1] = stage[i][0] ? ((stage[i] >> 1) ^ POLY)
                                             : (stage[i] >> 1);
        end
    endgenerate
 
    assign crc_out = stage[32];
 
endmodule

