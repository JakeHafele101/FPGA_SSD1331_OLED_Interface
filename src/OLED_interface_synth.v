
module OLED_interface (input i_CLK,
                       input i_RST,
                       input [1:0] i_MODE,
                       input i_START,
                       output reg o_READY, //ready to take in i_MODE and i_START for command
                       output o_CS,
                       output o_MOSI,
                       output o_SCK,
                       output o_DC,
                       output reg o_RES,     //OLED power reset, active low reset
                       output reg o_VCCEN,   //VCC enable, active high drives VCC
                       output reg o_PMODEN); //VDD logic voltage control. active high, drives PGND on schem
    



endmodule
