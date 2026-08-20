//successfully simulated this in icesoc_fabulous repo on the fabric
module top(
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

    assign wres0 = 32'hdeadbeef; //slot 0 returns deadbeef
    assign wres1 = wopa; //slot 1 returns op a
    assign wres2 = wopb; //slot 2 returns op b
    assign eres0 = 32'hcafebabe;
    assign eres1 = eopa;
    assign eres2 = eopb;

    assign W_RES0 = {4'b0000, wres0}; //setting the bits that are not part of the result to 0 to avoid undefined states x (watch out if any of those are needed, need to set them accordingly here)
    assign W_RES1 = {4'b0000, wres1};
    assign W_RES2 = {4'b0000, wres2};

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
