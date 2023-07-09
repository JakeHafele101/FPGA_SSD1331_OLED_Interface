module reaction_timer_ASCII(
    input [3:0] i_hex3, i_hex2, i_hex1, i_hex0, //Seven seg BCD values from reaction timer
    input [1:0] i_timer_state,
    input [1:0] i_timer_fail_state,
    output reg [NUM_ASCII_COL * NUM_ASCII_ROW * 8 - 1:0] o_ASCII, //output ASCII
    output reg [N_COLOR_BITS - 1 : 0] o_BACKGROUND_COLOR, o_TEXT_COLOR
    );
    
    parameter NUM_COL = 96; //# of columns in OLED array
    parameter NUM_ROW = 64; //# of rows in OLED array
    
    parameter NUM_ASCII_COL = NUM_COL / ASCII_COL_SIZE; //# of cols of ASCII chars (12 Default)
    parameter NUM_ASCII_ROW = NUM_ROW / ASCII_ROW_SIZE; //# of rows of ASCII chars (8 Default)
    
    parameter ASCII_COL_SIZE = 8; //Number of x bits of ASCII char
    parameter ASCII_ROW_SIZE = 8; //Number of y bits of ASCII char

    parameter N_COLOR_BITS = 8;

    wire [7:0] s_ASCII3, s_ASCII2, s_ASCII1, s_ASCII0;

    hex_to_ASCII g_bcd0_to_ASCII(
        .i_hex(i_hex3),
        .o_ASCII(s_ASCII3)
    );

    hex_to_ASCII g_bcd1_to_ASCII(
        .i_hex(i_hex2),
        .o_ASCII(s_ASCII2)
    );

    hex_to_ASCII g_bcd2_to_ASCII(
        .i_hex(i_hex1),
        .o_ASCII(s_ASCII1)
    );

    hex_to_ASCII g_bcd3_to_ASCII(
        .i_hex(i_hex0),
        .o_ASCII(s_ASCII0)
    );

    always @*
    case(i_timer_state)
        2'b00: //Stimulus off, display start message until button pressed
            begin
                o_BACKGROUND_COLOR = 8'b00000000; //black
                o_TEXT_COLOR = 8'b11111111; //white
                o_ASCII = {"            ",
                           "            ",
                           "    PRESS   ", 
                           "    BUTTON  ", 
                           "      TO    ", 
                           "    BEGIN   ", 
                           "            ", 
                           "  GOOD LUCK "};
            end

        2'b01: //Random count, set background to red, dont press yet
            begin
                o_BACKGROUND_COLOR = 8'b00000000; //black
                o_TEXT_COLOR = 8'b11111111; //white
                o_ASCII = {"            ",
                           "            ",
                           "    PRESS   ", 
                           "    BUTTON  ", 
                           "    WHEN    ", 
                           "    BLUE    ", 
                           "            ", 
                           "            "};

            end

        2'b10: //react to button, set background to green, say HIT IT
            begin
                o_BACKGROUND_COLOR = 8'b00000011; //blue
                o_TEXT_COLOR = 8'b11111111; //white
                o_ASCII = {"TIME: ", s_ASCII3, ".", s_ASCII2, s_ASCII1, s_ASCII0, " ",
                           "            ",
                           "            ",
                           "            ",
                           "            ",
                           "            ",
                           "            ", 
                           "            "};

            end

        2'b11: //Done, could either hit early, miss reaction, or hit on time
            begin

                case(i_timer_fail_state)

                2'b00: //No fail
                begin
                    o_BACKGROUND_COLOR = 8'b00011100; //Green
                    o_TEXT_COLOR = 8'b11111111; //white
                    o_ASCII = {"TIME: ", s_ASCII3, ".", s_ASCII2, s_ASCII1, s_ASCII0, " ",
                               "            ",
                               "            ", 
                               "    GOOD    ", 
                               "    JOB!    ", 
                               "            ", 
                               "            ", 
                               "            "};
                end

                2'b01: //Fail, pressed too early
                begin
                    o_BACKGROUND_COLOR = 8'b11100000; //Green
                    o_TEXT_COLOR = 8'b11111111; //white
                    o_ASCII = {"            ",
                               "            ",
                               "   FAILED   ", 
                               "            ", 
                               "    TOO     ", 
                               "    EARLY   ", 
                               "            ", 
                               "            "};
                end

                2'b10: //Fail, didnt press fast enough
                begin
                    o_BACKGROUND_COLOR = 8'b11100000; //Green
                    o_TEXT_COLOR = 8'b11111111; //white
                    o_ASCII = {"TIME: ", s_ASCII3, ".", s_ASCII2, s_ASCII1, s_ASCII0, " ",
                               "            ",
                               "   FAILED   ", 
                               "            ", 
                               "    TOO     ", 
                               "    SLOW    ", 
                               "            ", 
                               "            "};
                end


                endcase

            end

    endcase

    
    
endmodule
