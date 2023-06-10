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


module clock_divider_tb();

    parameter T = 2;
        
    parameter DVSR = 4;  //divide ratio
    
    //UUT inputs
    reg i_CLK, i_RST, i_EN;

    //UUT outputs
    wire o_CLK_DIV;

    clock_divider #(.DVSR(DVSR)) UUT 
    (
        .i_CLK(i_CLK),
        .i_RST(i_RST),
        .i_EN(i_EN),
        .o_CLK_DIV(o_CLK_DIV)
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
        i_EN = 1'b0;
        repeat(2) @(negedge i_CLK);

        i_EN = 1'b1;
        repeat(20) @(negedge i_CLK);

        $stop;
    end
    
endmodule
