`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/22/2022 12:28:10 PM
// Design Name:
// Module Name: uart_tx_test
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module Nbit_MOSI_SPI_Buffer_tb();
    
    parameter T = 2;
    
    parameter WIDTH = 8, //bits of data in word
    N = 8;  //max Number of bytes to load in buffer
    
    //UUT inputs
    reg i_SCK, i_RST, i_START;
    wire [(WIDTH*N)-1:0] i_DATA;
    reg [N-1:0] i_DC;
    reg [4:0] i_N_transmit; //# of bytes to transmit over MOSI on load

    //Internal Signals from UUT
    wire s_BYTE, s_START, s_DC, s_MOSI_FINAL_BYTE;

    reg [WIDTH-1:0] s_BYTE7, s_BYTE6, s_BYTE5, s_BYTE4, s_BYTE3, s_BYTE2, s_BYTE1, s_BYTE0; //Break up bytes for inputs
    assign i_DATA = {s_BYTE7, s_BYTE6, s_BYTE5, s_BYTE4, s_BYTE3, s_BYTE2, s_BYTE1, s_BYTE0};

    // assign i_DATA[63:56] = s_BYTE7;
    // assign i_DATA[55:48] = s_BYTE6;
    // assign i_DATA[47:40] = s_BYTE5;
    // assign i_DATA[39:32] = s_BYTE4;
    // assign i_DATA[31:24] = s_BYTE3;
    // assign i_DATA[23:16] = s_BYTE2;
    // assign i_DATA[15:8] = s_BYTE1; 
    // assign i_DATA[7:0] = s_BYTE0;

    //Outputs from MOSI SPI 
    wire o_MOSI, o_CS, o_DC, o_MOSI_FINAL_TX;

    Nbit_MOSI_SPI_Buffer #() UUT
    (.i_SCK(i_SCK),
    .i_RST(i_RST),
    .i_DATA(i_DATA),
    .i_DC(i_DC),
    .i_START(i_START),
    .i_N_transmit(i_N_transmit),
    .o_DATA(s_BYTE), //byte to transmit
    .o_START(s_START), //when to start loading byte
    .o_DC(s_DC),
    .o_MOSI_FINAL_BYTE(s_MOSI_FINAL_BYTE)
    );

    Nbit_MOSI_SPI #(.WIDTH(WIDTH)) g_Nbit_MOSI_SPI
    (.i_SCK(i_SCK),
    .i_RST(i_RST),
    .i_DATA(s_BYTE),
    .i_START(s_START),
    .i_DC(s_DC), 
    .o_MOSI(o_MOSI),
    .o_CS(o_CS),
    .o_DC(o_DC),
    .o_MOSI_FINAL_TX(o_MOSI_FINAL_TX)
    );
    
    always begin
        i_SCK = 1'b1;
        #(T/2);
        i_SCK = 1'b0;
        #(T/2);
    end
    
    initial begin
        i_RST = 1'b1;
        @(negedge i_SCK);
        i_RST = 1'b0;
    end
    
    initial begin
        i_START = 1'b0;
        i_DATA = 0;
        i_DC = 0;
        i_N_transmit = 0;
        @(posedge i_SCK);
        
        //No wait between
        i_START = 1'b1;

        i_DATA[0] = 8'b00000001;
        i_DATA[1] = 8'b00000010;
        i_DATA[2] = 8'b00000100;
        i_DATA[3] = 8'b00001000;
        i_DC = 8'b00000101;
        i_N_transmit = 4;
        repeat(7) @(posedge i_SCK);

        $stop;
    end
    
endmodule
