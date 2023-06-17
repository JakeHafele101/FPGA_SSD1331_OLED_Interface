
module OLED_interface_synth (input CLK100MHZ, //100MHz clock, stepped down to 5MHz
                       input [15:0] sw, //determines MODE
                       input btnC, //reset
                       input btnU, //i_START
                       output [15:0] LED, //indicators for outputs to PMOD
                       output [7:0] JC //OLED PMOD Port
                       );
    
    parameter WIDTH        = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N            = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter SCLK_DIVIDER = 20; //divide clock by 1
    
    parameter WAIT_3_US = 20; 
    parameter WAIT_100_MS = 600000;

    //Wires to inputs
    wire [1:0] s_MODE;

    //Wires to outputs
    wire s_READY, s_CS, s_MOSI, s_SCK, s_DC, s_RES, s_VCCEN, s_PMODEN;

    wire [7:0] s_background_color;

    OLED_interface #(.WIDTH(WIDTH), .N(N), .SCLK_DIVIDER(SCLK_DIVIDER), .WAIT_3_US(WAIT_3_US), .WAIT_100_MS(WAIT_100_MS)) g_OLED_interface
    (.i_CLK(CLK100MHZ),
    .i_RST(btnC),
    .i_MODE(s_MODE), //00 for start, 01 for color spam
    .i_START(btnU),
    .i_TEXT_COLOR(8'hFF),
    .i_BACKGROUND_COLOR(s_background_color),
    .i_PIXEL(), //open
    .o_READY(s_READY),
    .o_CS(s_CS),
    .o_MOSI(s_MOSI),
    .o_SCK(s_SCK),
    .o_DC(s_DC),
    .o_RES(s_RES),
    .o_VCCEN(s_VCCEN),
    .o_PMODEN(s_PMODEN)
    );

    //Sets Mode
    /*
    2'b00: turnon
    */
    assign s_MODE = {sw[1], sw[0]};
    assign LED[1:0] = {sw[1], sw[0]};

    assign LED[9:2] = {s_PMODEN, s_VCCEN, s_RES, s_DC, s_SCK, s_MOSI, s_CS, s_READY};

    assign JC[0] = s_CS; //P18
    assign JC[1] = s_MOSI; //M18
    assign JC[2] = 1'b0; //N17, NO CONNECT
    assign JC[3] = s_SCK; //P18
    assign JC[4] = s_DC; //L17
    assign JC[5] = s_RES; //M19
    assign JC[6] = s_VCCEN; //P17
    assign JC[7] = s_PMODEN; //R18

    assign s_background_color = sw[15:8];


endmodule
