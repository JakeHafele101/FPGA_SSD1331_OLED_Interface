`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/18/2022 08:19:56 PM
// Design Name: 
// Module Name: reaction_timer
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


module reaction_timer(
    input i_clk, i_reset, 
    input i_start, i_stop,
    output reg o_stimulus,
    output [3:0] o_seg3, o_seg2, o_seg1, o_seg0,
    output [1:0] o_state,
    output [1:0] o_fail_state //0 if success, 1 if early, 2 if slow
    );
    
    //definition for tick rate. defualt is for milliseconds
    parameter DVSR = 100000; //Mod-M counter for 0.001 second tick with 100MHZ clock

    //state definitions
    localparam [1:0] idle = 2'b00, //shows "HI" on seven seg, stimulus 0. press i_btn to initiate test, seven seg goes off at this point
                     random_count = 2'b01,  
                     react = 2'b10,  
                     done = 2'b11;
    
    //register values
    reg  [1:0]  s_state_reg, s_state_next;
    reg  [3:0]  s_seg3_reg, s_seg2_reg, s_seg1_reg, s_seg0_reg;
    reg  [3:0]  s_seg3_next, s_seg2_next, s_seg1_next, s_seg0_next;
    reg  [1:0]  s_fail_state_reg, s_fail_state_next;
    
    reg  [31:0] s_ms_reg, s_ms_next;
    reg  [3:0]  s_rand_reg, s_rand_next;
    
    wire        s_seg3_en, s_seg2_en, s_seg1_en, s_seg0_en;              //Enable status of if 10, 1, and 0.1 second should count
    wire        s_ms_tick, s_seg2_tick, s_seg1_tick, s_seg0_tick;        //tick status 
    wire [3:0]  s_seg3_count, s_seg2_count, s_seg1_count, s_seg0_count;
    wire [31:0] s_ms_count;
    
    wire [3:0]  s_rand_count, s_rand_decrement;    
    
    always @(posedge i_clk, posedge i_reset)
        if (i_reset)
            begin
                s_state_reg    <= idle;
                s_fail_state_reg <= 0;
                s_seg3_reg     <= 0;
                s_seg2_reg     <= 0;
                s_seg1_reg     <= 0;
                s_seg0_reg     <= 0;
                s_ms_reg       <= 0;
                s_rand_reg     <= 2;
            end
        else
            begin
                s_state_reg    <= s_state_next;
                s_fail_state_reg <= s_fail_state_next;
                s_seg3_reg     <= s_seg3_next;
                s_seg2_reg     <= s_seg2_next;
                s_seg1_reg     <= s_seg1_next;
                s_seg0_reg     <= s_seg0_next;
                s_ms_reg       <= s_ms_next;
                s_rand_reg     <= s_rand_next;
            end
    
    always @*
        begin
            //assign default values
            s_state_next = s_state_reg;
            s_seg3_next  = s_seg3_reg;
            s_seg2_next  = s_seg2_reg;
            s_seg1_next  = s_seg1_reg;
            s_seg0_next  = s_seg0_reg;
            s_ms_next    = s_ms_reg;
            s_rand_next  = s_rand_reg;
            s_fail_state_next = s_fail_state_reg;
            
            o_stimulus   = 1'b0;

            case(s_state_reg)
                idle: 
                    begin
                        
                        if(i_start) //displays start message until i_start goes active
                            s_state_next = random_count;
                         else
                            s_rand_next = s_rand_count;
                        
                    end
                random_count: //random count between 2 to 15 seconds (use seg3 counter). seg display off
                    begin
                                                 
                        if(i_stop) //if button pushed before stimulus reg set, display "9.999"
                            begin
                                s_seg3_next = 4'h9;
                                s_seg2_next = 4'h9;
                                s_seg1_next = 4'h9;
                                s_seg0_next = 4'h9;
                                s_state_next = done;
                                s_fail_state_next = 1; //fail early
                            end
                        else if (s_rand_reg == 0) //Random count between 2 to 15 seconds
                            begin
                                s_state_next = react;
                                s_seg3_next = 4'h0;
                                s_seg2_next = 4'h0;
                                s_seg1_next = 4'h0;
                                s_seg0_next = 4'h0;
                                s_ms_next   = 0;
                            end
                        else //otherwise, increment count
                            begin
                                s_seg3_next = s_seg3_count;
                                s_seg2_next = s_seg2_count;
                                s_seg1_next = s_seg1_count;
                                s_seg0_next = s_seg0_count;
                                s_ms_next   = s_ms_count;
                                s_rand_next = s_rand_decrement;
                            end
                    
                    end
                react:
                    begin
                        o_stimulus = 1'b1;
                        s_seg3_next = s_seg3_count;
                        s_seg2_next = s_seg2_count;
                        s_seg1_next = s_seg1_count;
                        s_seg0_next = s_seg0_count;
                        s_ms_next   = s_ms_count;

                        if(i_stop) //stop when stop button pushed
                        begin
                            s_state_next = done;
                            s_fail_state_next = 0; //success, pressed on time
                        end
                        
                        if(s_seg3_next == 4'h1) //stop when timer reaches 1 second, failed
                        begin
                            s_state_next = done;
                            s_fail_state_next = 2; //fail, stop late
                        end

                    end
                done: 
                    begin
                        o_stimulus = 1'b0;
                    end
            endcase
        end
    
    //data path logic
    //counter ticks when reaching 9 for 0.001, 0.01, 0.1, and 1 second
    assign s_ms_tick   = (s_ms_reg == DVSR) ? 1'b1 : 1'b0;
    assign s_seg0_tick = (s_seg0_reg == 9)  ? 1'b1 : 1'b0;
    assign s_seg1_tick = (s_seg1_reg == 9)  ? 1'b1 : 1'b0;
    assign s_seg2_tick = (s_seg2_reg == 9)  ? 1'b1 : 1'b0;
    
    //enable status for segment to increment if smaller value at 9
    assign s_seg0_en   = s_ms_tick; 
    assign s_seg1_en   = s_ms_tick && s_seg0_tick; 
    assign s_seg2_en   = s_ms_tick && s_seg0_tick && s_seg1_tick; 
    assign s_seg3_en   = s_ms_tick && s_seg0_tick && s_seg1_tick && s_seg2_tick; 

    //temporary count wires to increment registers
    assign s_rand_count = (s_rand_reg == 15) ? 4'h2 : s_rand_reg + 1;
    assign s_rand_decrement = (s_seg3_en && s_rand_reg > 0) ? s_rand_reg - 1 : s_rand_reg;
    
    assign s_ms_count   = (s_ms_reg == DVSR) ? 0 : s_ms_reg + 1;
    
    assign s_seg0_count = (s_seg0_en && (s_seg0_reg == 9)) ? 4'b0000 :
                                               (s_seg0_en) ? s_seg0_reg + 1 : 
                                                             s_seg0_reg;

    assign s_seg1_count = (s_seg1_en && (s_seg1_reg == 9)) ? 4'b0000:
                                               (s_seg1_en) ? s_seg1_reg + 1 : 
                                                             s_seg1_reg;
                                                     
    assign s_seg2_count = (s_seg2_en && (s_seg2_reg == 9)) ? 4'b0000:
                                               (s_seg2_en) ? s_seg2_reg + 1 : 
                                                             s_seg2_reg;
                                                     
    assign s_seg3_count = (s_seg3_en && (s_seg3_reg == 9)) ? 4'b0000:
                                               (s_seg3_en) ? s_seg3_reg + 1 : 
                                                             s_seg3_reg;
    
    //output logic
    assign o_seg0 = s_seg0_reg;
    assign o_seg1 = s_seg1_reg;
    assign o_seg2 = s_seg2_reg;
    assign o_seg3 = s_seg3_reg;
    assign o_state = s_state_reg;
    assign o_fail_state = s_fail_state_reg;
        
endmodule
