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


module button_tick_latch_tb();
    
    parameter T = 2;
    
    parameter WIDTH = 8;  //bits of data in word
    
    //UUT inputs
    reg i_CLK, i_RST, i_BTN;
    
    //UUT outputs
    wire o_TICK;

    button_tick_latch UUT
    (.i_CLK(i_CLK),
    .i_RST(i_RST),
    .i_BTN(i_BTN),
    .i_TICK(o_TICK)
    );
    
    
    always begin
        i_CLK = 1'b1;
        #(T/2);
        i_CLK = 1'b0;
        #(T/2);
    end
    
    initial begin
        i_RST = 1'b1;
        @(negedge i_CLK);
        i_RST = 1'b0;
    end
    
    initial begin
        i_BTN = 1'b0;
        @(negedge i_CLK);

        i_BTN = 1'b1;
        repeat(10) @(negedge i_CLK);
        i_BTN = 1'b0;
        repeat(5) @(negedge i_CLK);

        i_BTN = 1'b1;
        repeat(20) @(negedge i_CLK);
        i_BTN = 1'b0;
        repeat(5) @(negedge i_CLK);

        i_BTN = 1'b1;
        repeat(5) @(negedge i_CLK);
        i_BTN = 1'b0;
        repeat(5) @(negedge i_CLK);

        $stop;
    end
    
endmodule
