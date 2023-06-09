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
    reg [(WIDTH*N)-1:0] i_DATA;
    reg [N-1:0] i_DC;
    reg [4:0] i_N_transmit; //# of bytes to transmit over MOSI on load

    //Internal Signals from UUT
    wire [WIDTH-1:0] s_BYTE;
    wire s_START, s_DC, s_MOSI_FINAL_BYTE;
    reg [WIDTH-1:0] s_BYTE7, s_BYTE6, s_BYTE5, s_BYTE4, s_BYTE3, s_BYTE2, s_BYTE1, s_BYTE0; //Break up bytes for inputs

    always @* //Update i_DATA whenever individual bytes written
    begin
        i_DATA <= {s_BYTE7, s_BYTE6, s_BYTE5, s_BYTE4, s_BYTE3, s_BYTE2, s_BYTE1, s_BYTE0};
    end

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
    .o_CS(o_CS),
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
        @(negedge i_SCK);
        
        //No wait between
        i_START = 1'b1;

        s_BYTE0 = 8'b00000001;
        s_BYTE1 = 8'b00000010;
        s_BYTE2 = 8'b00000100;
        s_BYTE3 = 8'b00001000;
        s_BYTE4 = 8'b00010000;
        s_BYTE5 = 8'b00100000;
        s_BYTE6 = 8'b01000000;
        s_BYTE7 = 8'b10000000;

        i_DC = 8'b10101010;
        i_N_transmit = 8;
        @(negedge i_SCK);
        i_START = 1'b0;

        repeat(WIDTH*i_N_transmit + 10) @(negedge i_SCK);

        $stop;
    end
    
endmodule
