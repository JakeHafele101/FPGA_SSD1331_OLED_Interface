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


module OLED_interface_tb();
    
    parameter T = 2;
    
    parameter WIDTH        = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N            = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter SCLK_DIVIDER = 1; //divide clock by 1
    
    parameter WAIT_3_US = 2; 
    parameter WAIT_100_MS = 10; 
    
    //UUT inputs
    reg i_CLK, i_RST, i_START;
    reg [1:0] i_MODE;
            
    //Outputs from MOSI SPI
    wire o_READY, o_CS, o_MOSI, o_SCK, o_DC, o_RES, o_VCCEN, o_PMODEN;
    
    OLED_interface #(.WIDTH(WIDTH), .N(N), .SCLK_DIVIDER(SCLK_DIVIDER), .WAIT_3_US(WAIT_3_US), .WAIT_100_MS(WAIT_100_MS)) UUT
    (.i_CLK(i_CLK),
    .i_RST(i_RST),
    .i_MODE(i_MODE),
    .i_START(i_START),
    .o_READY(o_READY),
    .o_CS(o_CS),
    .o_MOSI(o_MOSI),
    .o_SCK(o_SCK),
    .o_DC(o_DC),
    .o_RES(o_RES),
    .o_VCCEN(o_VCCEN),
    .o_PMODEN(o_PMODEN)
    );
    
    always begin //clock
        i_CLK = 1'b1;
        #(T/2);
        i_CLK = 1'b0;
        #(T/2);
    end
    
    initial begin //reset
        i_RST = 1'b1;
        @(negedge i_CLK);
        i_RST = 1'b0;
    end
    
    initial begin
        //initial setup
        reset();

        //Turn on
        turnon();
        turnon();
        reset();
        turnon();
        repeat(10) @(negedge i_CLK);

        $stop;
    end

    task reset();
        begin
            i_MODE = 2'b00;
            i_START = 1'b0;
            i_RST = 1'b1;
            @(negedge i_CLK);
            i_RST = 1'b0;
            @(negedge i_CLK);
        end
    endtask

    task turnon();
        begin
            i_MODE = 2'b00;
            i_START = 1'b1;
            @(negedge o_READY);
            i_START = 1'b0;
            @(posedge o_READY);
        end
    endtask
    
endmodule