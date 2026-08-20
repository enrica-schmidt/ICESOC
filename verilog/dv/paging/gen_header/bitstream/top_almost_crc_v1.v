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

    localparam [31:0] POLY = 32'hEDB88320;
    wire [31:0] stage [0:32];
    assign stage[0] = wopa ^ wopb;
    
    /*
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : round
            assign stage[i+1] = stage[i][0] ? ((stage[i] >> 1) ^ POLY)
                                             : (stage[i] >> 1);
        end
    endgenerate
    */
    assign stage[32] = 32'hdeadbeef;

    assign wres0 = stage[32];
    assign wres1 = 32'hffffffff;
    assign wres2 = 32'hffffffff;

    assign W_RES0 = {4'b0000, wres0};
    assign W_RES1 = {4'b0000, wres1};
    assign W_RES2 = {4'b0000, wres2};

    assign eres0 = wres0;
    assign eres1 = wres1;
    assign eres2 = wres2;

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

    assign io_oeb = 10'b11_1111_1100;
    assign io_out[1:0] = 2'h0;
    assign io_out[9:2] =  ctr[7:0];

endmodule
