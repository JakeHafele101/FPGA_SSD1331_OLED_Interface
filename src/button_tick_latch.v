`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/13/2022 07:13:40 PM
// Design Name:
// Module Name: rising_edge_detector_mealy
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


module button_tick_latch(input i_CLK,
                         input i_RST,
                         input i_BTN,
                         output reg o_TICK);
    
    //assigns state names to bit values for case statement
    localparam [1:0] zero = 2'b00,
    hold = 2'b01,
    one = 2'b10;
    
    reg [1:0] state_reg, state_next;
    
    //D FF
    always @(negedge i_CLK, posedge i_RST)
        if (i_RST)
            state_reg = zero;
        else
            state_reg = state_next;
    
    //Next state logic and output logic
    always @*
    begin
    o_TICK     = 1'b0;  //default off since rising/falling edge will happen less often
    state_next = state_reg;
    case(state_reg)
        zero:
        if (i_BTN)
        begin
            o_TICK     = 1'b1;
            state_next = hold;
        end
        hold:
        begin
            o_TICK     = 1'b0;
            state_next = one;
        end
        one:
        if (~i_BTN)
            state_next = zero;
            endcase
    end
        
endmodule
