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


module Nbit_MOSI_SPI_Buffer_Combined_tb();
    
    parameter T = 2;
    
    parameter WIDTH = 8, //bits of data in word
    N = 8;  //max Number of bytes to load in buffer
    
    //UUT inputs
    reg i_SCK, i_RST, i_START;
    reg [(WIDTH*N)-1:0] i_DATA;
    reg [N-1:0] i_DC;
    reg [4:0] i_N_transmit; //# of bytes to transmit over MOSI on load
    
    //Internal Signals from UUT
    wire o_MOSI_FINAL_BYTE;
    reg [WIDTH-1:0] s_BYTE7, s_BYTE6, s_BYTE5, s_BYTE4, s_BYTE3, s_BYTE2, s_BYTE1, s_BYTE0; //Break up bytes for inputs
    
    always @* //Update i_DATA whenever individual bytes written
    begin
    i_DATA <= {s_BYTE7, s_BYTE6, s_BYTE5, s_BYTE4, s_BYTE3, s_BYTE2, s_BYTE1, s_BYTE0};
    end
    
    //Outputs from MOSI SPI
    wire o_MOSI, o_CS, o_DC, o_MOSI_FINAL_BIT;
    
    Nbit_MOSI_SPI_Buffer_Combined #() UUT
    (.i_SCK(i_SCK),
    .i_RST(i_RST),
    .i_DATA(i_DATA),
    .i_DC(i_DC),
    .i_START(i_START),
    .i_N_transmit(i_N_transmit),
    .o_MOSI_FINAL_BYTE(o_MOSI_FINAL_BYTE),
    .o_MOSI(o_MOSI),
    .o_CS(o_CS),
    .o_DC(o_DC),
    .o_MOSI_FINAL_BIT(o_MOSI_FINAL_BIT)
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
        i_START      = 1'b0;
        i_DATA       = 0;
        i_DC         = 0;
        i_N_transmit = 0;
        @(negedge i_SCK);
        
        //No wait between
        i_START = 1'b1;
        
        s_BYTE0      = 8'b11111110;
        s_BYTE1      = 8'b11111101;
        s_BYTE2      = 8'b11111011;
        s_BYTE3      = 8'b11110111;
        s_BYTE4      = 8'b11101111;
        s_BYTE5      = 8'b11011111;
        s_BYTE6      = 8'b10111111;
        s_BYTE7      = 8'b01111111;
        i_DC         = 8'b10101010;
        i_N_transmit = 8;
        @(negedge i_SCK);
        i_START = 1'b0;
        repeat(i_N_transmit) @(posedge o_MOSI_FINAL_BIT);
        
        i_START      = 1'b1;
        s_BYTE0      = 8'b00000011;
        s_BYTE1      = 8'b00001100;
        s_BYTE2      = 8'b00110000;
        s_BYTE3      = 8'b11000000;
        i_DC         = 8'b00001100;
        i_N_transmit = 4;
        @(negedge i_SCK);
        i_START = 1'b0;
        repeat(i_N_transmit) @(posedge o_MOSI_FINAL_BIT);
        
        repeat(10) @(negedge i_SCK); //wait a bit...
        
        i_START      = 1'b1;
        s_BYTE0      = 8'b00000011;
        s_BYTE1      = 8'b00001100;
        i_DC         = 8'b00000010;
        i_N_transmit = 2;
        @(negedge i_SCK);
        i_START = 1'b0;
        repeat(i_N_transmit) @(posedge o_MOSI_FINAL_BIT);
        
        i_START      = 1'b1;
        i_N_transmit = 0;
        @(negedge i_SCK);
        i_START = 1'b0;
        repeat(10) @(negedge i_SCK);
        $stop;
    end
    
endmodule
