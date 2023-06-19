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

    parameter NUM_COL = 2; //# of columns in OLED array
    parameter NUM_ROW = 2; //# of rows in OLED array
    
    parameter N_COLOR_BITS = 8;
    
    //UUT inputs
    reg i_CLK, i_RST, i_START;
    reg [1:0] i_MODE;
    reg [N_COLOR_BITS-1:0] i_TEXT_COLOR;
    reg [N_COLOR_BITS-1:0] i_BACKGROUND_COLOR;
    reg [NUM_COL*NUM_ROW - 1:0] i_PIXEL;       //1 if text color, 0 if background color
            
    //Outputs from MOSI SPI
    wire o_READY, o_CS, o_MOSI, o_SCK, o_DC, o_RES, o_VCCEN, o_PMODEN, o_MOSI_FINAL_BIT, o_MOSI_FINAL_BYTE;
    
    OLED_interface 
    #(.WIDTH(WIDTH), 
    .N(N), 
    .SCLK_DIVIDER(SCLK_DIVIDER), 
    .WAIT_3_US(WAIT_3_US), 
    .WAIT_100_MS(WAIT_100_MS),
    .NUM_COL(NUM_COL),
    .NUM_ROW(NUM_ROW),
    .N_COLOR_BITS(N_COLOR_BITS)
    )

    UUT (.i_CLK(i_CLK),
    .i_RST(i_RST),
    .i_MODE(i_MODE),
    .i_START(i_START),
    .i_TEXT_COLOR(i_TEXT_COLOR),
    .i_BACKGROUND_COLOR(i_BACKGROUND_COLOR),
    .i_PIXEL(i_PIXEL),
    .o_READY(o_READY),
    .o_CS(o_CS),
    .o_MOSI(o_MOSI),
    .o_SCK(o_SCK),
    .o_DC(o_DC),
    .o_RES(o_RES),
    .o_VCCEN(o_VCCEN),
    .o_PMODEN(o_PMODEN),
    .o_MOSI_FINAL_BIT(o_MOSI_FINAL_BIT),
    .o_MOSI_FINAL_BYTE(o_MOSI_FINAL_BYTE)
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

        repeat(100) @(negedge i_CLK);

        pixel_display(4'b1010); //text, bg, text, bg
        pixel_display(4'b1010); //text, bg, text, bg

        repeat(100) @(negedge i_CLK);

        $stop;
    end

    task reset();
        begin
            i_MODE = 2'b00;
            i_START = 1'b0;
            i_RST = 1'b1;
            i_PIXEL = 0;
            i_TEXT_COLOR = 8'h00;
            i_BACKGROUND_COLOR = 8'hFF;
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

    task pixel_display(input [NUM_COL*NUM_ROW - 1:0] i_PIXEL_task);
        begin
            i_MODE = 2'b10;
            i_PIXEL = i_PIXEL_task;
            @(negedge i_CLK);
            i_START = 1'b1;
            @(negedge o_READY);
            i_START = 1'b0;
            @(posedge o_READY);
        end
    endtask

    task update_colors(input [7:0] i_TEXT, input [7:0] i_BACKGROUND);
        begin
            i_TEXT_COLOR = i_TEXT;
            i_BACKGROUND_COLOR = i_BACKGROUND;
        end
    endtask
    
endmodule