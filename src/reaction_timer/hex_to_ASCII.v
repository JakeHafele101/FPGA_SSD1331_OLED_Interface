module hex_to_ASCII (
    input [3:0] i_hex,
    output reg [7:0] o_ASCII
);

always @*
    case(i_hex)
        4'h0: o_ASCII = 8'h30; //0 in ASCII
        4'h1: o_ASCII = 8'h31; //1 in ASCII
        4'h2: o_ASCII = 8'h32; //2 in ASCII
        4'h3: o_ASCII = 8'h33; //3 in ASCII
        4'h4: o_ASCII = 8'h34; //4 in ASCII
        4'h5: o_ASCII = 8'h35; //5 in ASCII
        4'h6: o_ASCII = 8'h36; //6 in ASCII
        4'h7: o_ASCII = 8'h37; //7 in ASCII
        4'h8: o_ASCII = 8'h38; //8 in ASCII
        4'h9: o_ASCII = 8'h39; //9 in ASCII
        4'hA: o_ASCII = 8'h41; //A in ASCII
        4'hB: o_ASCII = 8'h42; //B in ASCII
        4'hC: o_ASCII = 8'h43; //C in ASCII
        4'hD: o_ASCII = 8'h44; //D in ASCII
        4'hE: o_ASCII = 8'h45; //E in ASCII
        4'hF: o_ASCII = 8'h46; //F in ASCII
    endcase

endmodule