module top(
    input wire clk,
    input wire [35:0] W_OPA, W_OPB, E_OPA, E_OPB,
    input wire [9:0] io_in,
    output wire [35:0] W_RES0, W_RES1, W_RES2, E_RES0, E_RES1, E_RES2,
    output wire [9:0] io_out, io_oeb
);
    wire [31:0] opa, opb, res0, res1, res2;
    assign opa = W_OPA[34:3];
    assign opb = W_OPB[31:0];
    assign res0 = 32'hdeadbeef; //slot 0 returns deadbeef
    assign res1 = opa; //slot 1 returns op a
    assign res2 = opb; //slot 2 returns op b

    assign W_RES0[31:0] = res0;
    assign W_RES1[31:0] = res1;
    assign W_RES2[31:0] = res2;

    //assign E_RES0[31:0] = ;
    //assign E_RES1[31:0] = ;
    //assign E_RES2[31:0] = ;


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
