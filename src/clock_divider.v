`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// i_ENgineer: 
// 
// Create Date: 12/12/2022 01:42:18 PM
// Design Name: 
// Module Name: clock_divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Depi_ENdi_ENcies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Commi_ENts:
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_divider(
    input i_CLK, 
    input i_RST,
    input i_EN,
    output reg o_CLK_DIV
    );
    
    parameter DVSR = 100; //Divide clock by DVSR times, must be larger than 0
    
    //counter for clock frequi_ENcy
    reg [31:0] s_ms_reg;         
    wire [31:0] s_ms_next;
    
                
    always @(posedge i_CLK, posedge i_RST)
        if(i_RST)
        begin
            s_ms_reg <= 0;
            o_CLK_DIV <= 1'b0;
        end
        else if (i_EN && DVSR != 0)
        begin
            s_ms_reg <= s_ms_next;
            if(s_ms_reg == (DVSR-1)/2)
                o_CLK_DIV <= ~o_CLK_DIV;
        end
    
    //next-state logic
    assign s_ms_next = (i_RST || ((s_ms_reg == (DVSR-1)/2) && i_EN)) ? 0 :
                       (i_EN) ?   s_ms_reg + 1 :
                                  s_ms_reg;
                                  
endmodule
