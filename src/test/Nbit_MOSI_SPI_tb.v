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


module Nbit_MOSI_SPI_tb();
    
    parameter T = 2;
    
    parameter WIDTH = 8;  //bits of data in word
    
    //UUT inputs
    reg i_SCK, i_RST, i_DC, i_START;
    reg [WIDTH-1:0] i_DATA;
    
    //UUT outputs
    wire o_MOSI, o_CS, o_DC, o_MOSI_FINAL_TX;

    Nbit_MOSI_SPI #(.WIDTH(WIDTH)) UUT
    (.i_SCK(i_SCK),
    .i_RST(i_RST),
    .i_DATA(i_DATA),
    .i_START(i_START),
    .i_DC(i_DC), 
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
        i_DC = 1'b0;
        @(posedge i_SCK);
        
        //No wait between
        i_START = 1'b1;

        i_DATA = 'b10101010;
        i_DC = 1'b0;
        repeat(7) @(posedge i_SCK);

        i_DATA = 'b11111111;
        i_DC = 1'b1;
        repeat(7) @(posedge i_SCK);

        i_DATA = 'b00000000;
        i_DC = 1'b1;
        repeat(7) @(posedge i_SCK);

        i_DATA = 'b11000010;
        i_DC = 1'b0;
        repeat(7) @(posedge i_SCK);
        i_START = 1'b0;
        repeat(10) @(posedge i_SCK);

        //Wait in between, back to idle
        i_START = 1'b1;
        i_DATA = 'b11110001;
        i_DC = 1'b1;
        repeat(1) @(posedge i_SCK);
        i_START = 1'b0;
        repeat(10) @(posedge i_SCK);

        i_START = 1'b1;
        i_DATA = 'b11001101;
        i_DC = 1'b0;
        repeat(1) @(posedge i_SCK);
        i_START = 1'b0;
        repeat(10) @(posedge i_SCK);

        i_START = 1'b1;
        i_DATA = 'b10000010;
        i_DC = 1'b1;
        repeat(1) @(posedge i_SCK);
        i_START = 1'b0;
        repeat(10) @(posedge i_SCK);

        $stop;
    end
    
endmodule
