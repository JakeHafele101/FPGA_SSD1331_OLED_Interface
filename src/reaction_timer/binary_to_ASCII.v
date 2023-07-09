`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/16/2022 07:21:48 PM
// Design Name: 
// Module Name: binary_to_ASCII
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


module binary_to_ASCII(
    input clk, reset,
    input start,
    input [13:0] bin,
    output reg ready, done_tick,
    output [7:0] ASCII_3, ASCII_2, ASCII_1, ASCII_0
    );

    hex_to_ASCII g_bcd0_to_ASCII(
        .i_hex(bcd0),
        .o_ASCII(ASCII_0)
    );

    hex_to_ASCII g_bcd1_to_ASCII(
        .i_hex(bcd1),
        .o_ASCII(ASCII_1)
    );

    hex_to_ASCII g_bcd2_to_ASCII(
        .i_hex(bcd2),
        .o_ASCII(ASCII_2)
    );

    hex_to_ASCII g_bcd3_to_ASCII(
        .i_hex(bcd3),
        .o_ASCII(ASCII_3)
    );
    
    //state declarations
    localparam [1:0] idle = 2'b00,
                     op = 2'b01,
                     done = 2'b10;
    
    //signal declaration
    reg [1:0] state_reg, state_next;
    reg [13:0] bin_reg, bin_next;
    reg [3:0] n_reg, n_next;
    reg [3:0] bcd3_reg, bcd2_reg, bcd1_reg, bcd0_reg;
    reg [3:0] bcd3_next, bcd2_next, bcd1_next, bcd0_next;
    wire [3:0] bcd3_temp, bcd2_temp, bcd1_temp, bcd0_temp;
    
    //FSMD state and data registers
    always @(posedge clk, posedge reset)
        if(reset)
            begin
                state_reg <= idle;
                bin_reg <= 0;
                n_reg <= 0;
                bcd3_reg <= 0;
                bcd2_reg <= 0;
                bcd1_reg <= 0;
                bcd0_reg <= 0;
            end
        else
            begin
                state_reg <= state_next;
                bin_reg <= bin_next;
                n_reg <= n_next;
                bcd3_reg <= bcd3_next;
                bcd2_reg <= bcd2_next;
                bcd1_reg <= bcd1_next;
                bcd0_reg <= bcd0_next;
            end
    
    //FSMD next state logic
    always @*
    begin
        //default values
        state_next = state_reg;
        ready = 1'b0;
        done_tick = 1'b0;
        bin_next = bin_reg;
        bcd3_next = bcd3_reg;
        bcd2_next = bcd2_reg;
        bcd1_next = bcd1_reg;
        bcd0_next = bcd0_reg;
        n_next = n_reg;
        
        case(state_reg)
            idle: 
                begin
                    ready = 1'b1;
                    if(start)
                        begin
                            state_next = op;
                            bcd0_next = 0; 
                            bcd1_next = 0;
                            bcd2_next = 0; 
                            bcd3_next = 0; 
                            n_next = 4'b1110;  //index to decrement in op state
                            bin_next = bin;     //binary reg to shift into
                        end
                end
            op: 
                begin
                bin_next = bin_reg << 1;
                
                bcd0_next = {bcd0_temp[2:0], bin_reg[13]};
                bcd1_next = {bcd1_temp[2:0], bcd0_temp[3]};
                bcd2_next = {bcd2_temp[2:0], bcd1_temp[3]};
                bcd3_next = {bcd3_temp[2:0], bcd2_temp[3]};
                
                n_next = n_next - 1;
                if(n_next == 0)
                    state_next = done;
                end
            done: 
                begin
                    done_tick = 1'b1;
                    state_next = idle;
                end
            default: state_next = idle;
        endcase
    end
    
    
    //data path function units
    assign bcd0_temp = (bcd0_reg > 4) ? bcd0_reg + 3 : bcd0_reg;
    assign bcd1_temp = (bcd1_reg > 4) ? bcd1_reg + 3 : bcd1_reg;
    assign bcd2_temp = (bcd2_reg > 4) ? bcd2_reg + 3 : bcd2_reg;
    assign bcd3_temp = (bcd3_reg > 4) ? bcd3_reg + 3 : bcd3_reg;
    
    //output
    assign bcd0 = bcd0_reg;
    assign bcd1 = bcd1_reg;
    assign bcd2 = bcd2_reg;
    assign bcd3 = bcd3_reg;
    
endmodule
