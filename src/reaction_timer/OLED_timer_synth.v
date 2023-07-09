
module OLED_timer_synth (input CLK100MHZ, //100MHz clock, stepped down to 5MHz
                       input [15:0] sw, 
                       input btnC, //reset
                       input btnL, //i_btn for start timer
                       input btnR, //button for stop timer
                       output [15:0] LED, //indicators for outputs to PMOD
                       output [7:0] JA //OLED PMOD Port
                       );
    
    parameter WIDTH        = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N            = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter SCLK_DIVIDER = 20; //divide clock by 1
    
    parameter WAIT_3_US = 20; 
    parameter WAIT_100_MS = 600000;

    parameter NUM_COL = 96; //# of columns in OLED array
    parameter NUM_ROW = 64; //# of rows in OLED array

    parameter NUM_ASCII_COL  = NUM_COL / ASCII_COL_SIZE; //# of cols of ASCII chars (12 Default)
    parameter NUM_ASCII_ROW  = NUM_ROW / ASCII_ROW_SIZE; //# of rows of ASCII chars (8 Default)

    parameter ASCII_COL_SIZE = 8; //Number of x bits of ASCII char
    parameter ASCII_ROW_SIZE = 8; //Number of y bits of ASCII char

    parameter N_COLOR_BITS = 8;

    //Internal wires
    wire s_rising_btnL, s_rising_btnR;

    wire [1:0] s_timer_state;
    wire [1:0] s_timer_fail_state;
    wire s_timer_stimulus; //stimulus indicator for ASCII display

    wire [3:0] s_hex3, s_hex2, s_hex1, s_hex0;

    wire [NUM_ASCII_COL * NUM_ASCII_ROW * 8 - 1:0] s_ASCII;
    wire [N_COLOR_BITS-1:0] s_background_color;
    wire [N_COLOR_BITS-1:0] s_text_color;

    //Wires to inputs
    wire [1:0] s_MODE;
    wire s_TICK, s_START;

    //Wires to outputs
    wire s_READY, s_CS, s_MOSI, s_SCK, s_DC, s_RES, s_VCCEN, s_PMODEN;


    debounce_FSMD debounce_btnL(
        .i_CLK(CLK100MHZ),
        .i_RST(btnC),
        .i_BTN(btnL),
        .o_DB_LVL(s_rising_btnL),
        .o_DB_TICK()
    );

    debounce_FSMD debounce_btnR(
        .i_CLK(CLK100MHZ),
        .i_RST(btnC),
        .i_BTN(btnR),
        .o_DB_LVL(s_rising_btnR),
        .o_DB_TICK()
    );

    reaction_timer react(.i_clk(CLK100MHZ), .i_reset(btnC), .i_start(s_rising_btnL), .i_stop(s_rising_btnR), .o_stimulus(LED[8]), 
                    .o_seg3(s_hex3), .o_seg2(s_hex2), .o_seg1(s_hex1), .o_seg0(s_hex0), .o_state(s_timer_state), .o_fail_state(s_timer_fail_state));

    reaction_timer_ASCII react_timer_ASCII(
        .i_hex3(s_hex3),
        .i_hex2(s_hex2),
        .i_hex1(s_hex1),
        .i_hex0(s_hex0),
        .i_timer_state(s_timer_state),
        .i_timer_fail_state(s_timer_fail_state),
        .o_ASCII(s_ASCII),
        .o_BACKGROUND_COLOR(s_background_color),
        .o_TEXT_COLOR(s_text_color)
    );

    OLED_interface 
    #(.WIDTH(WIDTH), 
    .N(N), 
    .SCLK_DIVIDER(SCLK_DIVIDER), 
    .WAIT_3_US(WAIT_3_US), 
    .WAIT_100_MS(WAIT_100_MS),
    .NUM_COL(NUM_COL),
    .NUM_ROW(NUM_ROW),
    .ASCII_COL_SIZE(ASCII_COL_SIZE),
    .ASCII_ROW_SIZE(ASCII_ROW_SIZE),
    .N_COLOR_BITS(N_COLOR_BITS)
    ) 
    g_OLED_interface
    (.i_CLK(CLK100MHZ),
    .i_RST(btnC),
    .i_MODE(2'b10), //always in text display mode
    .i_START(1'b1), //auto update
    .i_TEXT_COLOR(s_text_color),
    .i_BACKGROUND_COLOR(s_background_color),
    .i_ASCII(s_ASCII), 
    .o_READY(s_READY),
    .o_CS(s_CS),
    .o_MOSI(s_MOSI),
    .o_SCK(s_SCK),
    .o_DC(s_DC),
    .o_RES(s_RES),
    .o_VCCEN(s_VCCEN),
    .o_PMODEN(s_PMODEN)
    );

    assign LED[7:0] = {s_PMODEN, s_VCCEN, s_RES, s_DC, s_SCK, s_MOSI, s_CS, s_READY};

    assign JA[0] = s_CS; //P18
    assign JA[1] = s_MOSI; //M18
    assign JA[2] = 1'b0; //N17, NO CONNECT
    assign JA[3] = s_SCK; //P18
    assign JA[4] = s_DC; //L17
    assign JA[5] = s_RES; //M19
    assign JA[6] = s_VCCEN; //P17
    assign JA[7] = s_PMODEN; //R18

endmodule