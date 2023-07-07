
`include "SSD1331_defines.v"

module OLED_interface (input i_CLK,
                       input i_RST,
                       input [1:0] i_MODE,
                       input i_START,
                       input [N_COLOR_BITS-1:0] i_TEXT_COLOR,
                       input [N_COLOR_BITS-1:0] i_BACKGROUND_COLOR,
                       input [NUM_ASCII_COL * NUM_ASCII_ROW * 8 - 1:0] i_ASCII, //ASCII bytes with top left MSB, bottom right LSB
                       output reg o_READY,                                      //ready to take in i_MODE and i_START for command
                       output o_CS,
                       output o_MOSI,
                       output o_SCK,
                       output o_DC,
                       output reg o_RES,                                        //OLED power reset, active low reset
                       output reg o_VCCEN,                                      //VCC enable, active high drives VCC
                       output reg o_PMODEN,
                       output o_MOSI_FINAL_BIT,
                       output o_MOSI_FINAL_BYTE);
    
    parameter WIDTH        = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N            = 8; //# of bytes that can be loaded at once for MOSI. NO LOWER THAN 6
    parameter SCLK_DIVIDER = 20; //Minimum 150ns Period (or 6.66 MHz), divided 100 MHz down to 5MHz
    
    //Wait times. 100MHz clock, 10ns period. # ticks = wait time / clock period
    //If using SCLK, 5MHz clock, 200ns period
    parameter WAIT_3_US   = 20; //Count up to X ticks to wait on 100MHz clock, only needs 15
    parameter WAIT_100_MS = 600000; //Needs 500000
    
    parameter [31:0] NUM_COL = 96; //# of columns in OLED array
    parameter [31:0] NUM_ROW = 64; //# of rows in OLED array
    
    parameter [7:0] ASCII_COL_SIZE = 8; //Number of x bits of ASCII char
    parameter [7:0] ASCII_ROW_SIZE = 8; //number of y bits of ASCII char
    parameter [7:0] NUM_ASCII_COL  = NUM_COL / ASCII_COL_SIZE; //# of cols of ASCII chars (12 Default)
    parameter [7:0] NUM_ASCII_ROW  = NUM_ROW / ASCII_ROW_SIZE; //# of rows of ASCII chars (8 Default)
    
    parameter N_COLOR_BITS = WIDTH;
    
    //Internal states
    localparam idle = 4'b0000,
    turnon_1 = 4'b0001,
    turnon_2 = 4'b0010,
    turnon_3 = 4'b0011,
    turnon_4 = 4'b0100,
    fill_screen_1 = 4'b0101,
    pixel_display_1 = 4'b0110, //6
    pixel_display_2 = 4'b0111; //7
    
    //Mode selection
    localparam turnon = 2'b00,
    fill_screen = 2'b01,
    pixel_display = 2'b10;
    
    //Internal signals
    reg [3:0] s_state_reg;  //state register
    reg [31:0] s_count_reg; //counter for delays between turn on/off
    reg s_buffer_start_reg;
    reg s_init_reg; //0 if turnon not complete, 1 if so
    reg [N_COLOR_BITS - 1:0] s_TEXT_COLOR_reg;
    reg [N_COLOR_BITS - 1:0] s_BACKGROUND_COLOR_reg;
    
    
    //Pixel internal
    reg [7:0] s_PIXEL_COUNT_reg; //counter for what pixel displayed
    reg [7:0] s_ASCII_col_reg;
    reg [7:0] s_ASCII_row_reg;
    
    wire [7:0] s_ASCII_first_col, s_ASCII_last_col;
    wire [7:0] s_ASCII_first_row, s_ASCII_last_row;
    
    reg [NUM_ASCII_COL * NUM_ASCII_ROW * 8 - 1:0] s_ASCII; //saves ASCII chars to display
    
    wire [7:0] s_ASCII_current; //current ASCII to be converted and displayed
    wire [ASCII_COL_SIZE*ASCII_ROW_SIZE - 1:0] s_ASCII_PIXEL; //ASCII char converted to pixels to display
    
    //Buffer module internal signals
    wire s_SCK;
    reg [(WIDTH*N)-1:0] s_DATA; //FIXME, wire to col/row
    reg [N-1:0] s_DC;
    reg [4:0] s_N_transmit;
    
    wire s_MOSI_FINAL_BYTE;
    wire s_MOSI_FINAL_BIT;
    
    //Modules
    Nbit_MOSI_SPI_Buffer_Combined #(.WIDTH(WIDTH), .N(N)) g_Nbit_MOSI_SPI_Buffer_Combined
    (.i_SCK(s_SCK),
    .i_RST(i_RST),
    .i_DATA(s_DATA),
    .i_DC(s_DC),
    .i_START(s_buffer_start_reg),
    .i_N_transmit(s_N_transmit),
    .o_MOSI_FINAL_BYTE(s_MOSI_FINAL_BYTE),
    .o_MOSI(o_MOSI),
    .o_CS(o_CS),
    .o_DC(o_DC),
    .o_MOSI_FINAL_BIT(s_MOSI_FINAL_BIT)
    );
    
    clock_divider #(.DVSR(SCLK_DIVIDER)) SCLK_clock_divider
    (
    .i_CLK(i_CLK),
    .i_RST(i_RST),
    .i_EN(1'b1), //always enabled
    .o_CLK_DIV(s_SCK)
    );
    
    ascii_font_8x8 font(
    .i_ASCII(s_ASCII_current), //8 bit ASCII input
    .o_PIXEL(s_ASCII_PIXEL) //8x8 bit pixel array, MSB top left pixel, LSB bottom right pixel, row by row
    );
    
    //Datapath for start/end row/col headers based on ASCII value
    assign s_ASCII_first_col = s_ASCII_col_reg * 8;
    assign s_ASCII_last_col  = s_ASCII_col_reg*8 + 7;
    assign s_ASCII_first_row = s_ASCII_row_reg*8;
    assign s_ASCII_last_row  = s_ASCII_row_reg*8 + 7;
    
    assign s_ASCII_current = s_ASCII[NUM_ASCII_COL * NUM_ASCII_ROW * 8 - 1 : NUM_ASCII_COL * NUM_ASCII_ROW * 8 - 8];
    
    always @(posedge s_SCK, posedge i_RST)
        if (i_RST)
        begin
            s_state_reg            <= idle;
            s_buffer_start_reg     <= 1'b0;
            s_count_reg            <= 0;
            s_DATA                 <= 0;
            s_DC                   <= 0;
            s_N_transmit           <= 0;
            s_init_reg             <= 1'b0;
            s_PIXEL_COUNT_reg      <= 0;
            s_ASCII_col_reg        <= 0;
            s_ASCII_row_reg        <= 0;
            s_ASCII                <= 0;
            s_TEXT_COLOR_reg       <= 0;
            s_BACKGROUND_COLOR_reg <= 0;
            o_RES                  <= 1'b1;
            o_VCCEN                <= 1'b0;
            o_PMODEN               <= 1'b0;
            o_READY                <= 1'b0;
        end
    
    else
    begin
    case(s_state_reg)
        idle:
        begin
            
            //Default idle
            s_buffer_start_reg <= 1'b0;
            s_count_reg        <= 0;
            s_DATA             <= 0;
            s_DC               <= 0;
            s_N_transmit       <= 0;
            o_RES              <= 1'b1;
            
            if (s_init_reg == 1'b0)
            begin
                s_state_reg <= turnon_1;
                o_READY     <= 1'b0;
            end
            else if (i_START == 1'b1) //If beginning mode
            begin
                o_READY <= 1'b0; //Starting mode, not ready to receive
                
                case(i_MODE)
                    turnon:
                    begin
                        s_state_reg <= turnon_1;
                    end
                    fill_screen:
                    begin
                        s_state_reg            <= fill_screen_1;
                        s_BACKGROUND_COLOR_reg <= i_BACKGROUND_COLOR;
                    end
                    pixel_display:
                    begin
                        s_state_reg            <= pixel_display_1;
                        s_TEXT_COLOR_reg       <= i_TEXT_COLOR;
                        s_BACKGROUND_COLOR_reg <= i_BACKGROUND_COLOR;
                        s_PIXEL_COUNT_reg      <= 0;
                        s_ASCII_col_reg        <= 0;
                        s_ASCII_row_reg        <= 0;
                        s_ASCII                <= i_ASCII;
                    end
                endcase
            end
            else
                o_READY <= 1'b1;
            
        end
        
        turnon_1: //Set RES pin low, wait atleast 3us
        begin
            o_RES <= 1'b0;
            
            if (s_count_reg >= WAIT_3_US - 1) //If waited for more than 3 microseconds, next state
            begin
                s_state_reg <= turnon_2;
                s_count_reg <= 0; //reset count
            end
            else //Otherwise, increment tick count
                s_count_reg <= s_count_reg + 1;
        end
        
        turnon_2: //Set RES pin high, VCCEN to high, PMODEN to high, wait atleast 3us
        begin
            
            o_RES    <= 1'b1;
            o_VCCEN  <= 1'b1;
            o_PMODEN <= 1'b1;
            
            if (s_count_reg >= WAIT_3_US - 1) //If waited for more than 3 microseconds, next state
            begin
                s_state_reg <= turnon_3;
                s_count_reg <= 0; //reset count
            end
            else //Otherwise, increment tick count
                s_count_reg <= s_count_reg + 1;
        end
        
        turnon_3: //Load Display ON command (0xAF)
        begin
            
            //Command, 0xAF, send one byte to buffer/MOSI
            s_DATA[(WIDTH-1)+WIDTH*2:0] <= {8'h20, 8'hA0, 8'hAF}; //Display ON, set to 256 color display, odd even COM split, Scan from COM63 to COM0
            s_DC[2:0]                   <= 3'b000; //Write command
            s_N_transmit                <= 3; //transmit 3 bytes
            s_buffer_start_reg          <= 1'b1;
            
            s_state_reg <= turnon_4;
        end
        
        turnon_4: //wait 100ms for display turnon
        begin
            s_buffer_start_reg <= 1'b0; //turn off load to byte buffer
            
            if (s_count_reg >= WAIT_100_MS - 1) //If waited for more than 100 milliseconds, go back to idle
            begin
                s_state_reg <= idle;
                s_count_reg <= 0; //reset count
                s_init_reg  <= 1'b1; //First init done now
            end
            else //Otherwise, increment tick count
                s_count_reg <= s_count_reg + 1;
        end
        
        fill_screen_1:
        begin
            //Command, 0xAF, send one byte to buffer/MOSI
            s_DATA[WIDTH-1:0]  <= s_BACKGROUND_COLOR_reg; //Send text color to fill background
            s_DC[0]            <= 1'b1; //Data command
            s_N_transmit       <= 1; //transmit 1 byte
            s_buffer_start_reg <= 1'b1;
            
            s_state_reg <= idle;
        end
        
        pixel_display_1: //Set starting and ending addressses for row/column
        begin
            s_DATA[(WIDTH-1)+WIDTH*5:0] <= {s_ASCII_last_row, s_ASCII_first_row, 8'h75, s_ASCII_last_col, s_ASCII_first_col, 8'h15}; //Set starting row and col address
            s_DC[5:0]                   <= 6'b000000; //Data 1, command 0
            s_N_transmit                <= 6; //transmit 6 bytes
            s_buffer_start_reg          <= 1'b1;
            
            s_state_reg       <= pixel_display_2;
            s_PIXEL_COUNT_reg <= 0; //reset ASCII pixel count to 0
            
        end
        
        pixel_display_2: //Send 1 pixel at a time
        begin
            if (s_MOSI_FINAL_BYTE == 1'b1 && s_MOSI_FINAL_BIT == 1'b1) //If transmitting second to last bit and last byte, check to transmit again
            begin
                
                if (s_PIXEL_COUNT_reg >= ASCII_COL_SIZE * ASCII_ROW_SIZE) //If transmitted all bytes in ASCII char
                begin
                    if ((s_ASCII_row_reg >= NUM_ASCII_ROW - 1) && (s_ASCII_col_reg >= NUM_ASCII_COL - 1)) //if sent all bytes in ASCII, leave
                    begin
                        s_state_reg <= idle;
                    end
                    else if (s_ASCII_col_reg >= NUM_ASCII_COL - 1) //If on last col ASCII, set to col 0 and increment row
                    begin
                        s_ASCII_col_reg <= 0;
                        s_ASCII_row_reg <= s_ASCII_row_reg + 1;
                        s_state_reg     <= pixel_display_1; //reset start/end row/column addresses~
                    end
                    else //Otherwise, stay in same row and increment col
                    begin
                        s_ASCII_col_reg <= s_ASCII_col_reg + 1;
                        s_state_reg     <= pixel_display_1; //reset start/end row/column addresses
                    end
                    
                    s_ASCII <= s_ASCII << 8; //shift left 8 so next ASCII byte can be read
                    s_buffer_start_reg <= 1'b0;
                end
                else
                begin
                    //Choose color to send
                    if (s_ASCII_PIXEL[ASCII_COL_SIZE * ASCII_ROW_SIZE - 1 - s_PIXEL_COUNT_reg] == 1'b0)  //send background color
                        s_DATA[WIDTH-1:0] <= s_BACKGROUND_COLOR_reg; //Send white pixel
                    else  //send text color
                        s_DATA[WIDTH-1:0] <= s_TEXT_COLOR_reg; //Send white pixel
                    
                    s_DC[0]      <= 1'b1; //Data 1, command 0
                    s_N_transmit <= 1; //transmit 1 bytes
                    
                    s_PIXEL_COUNT_reg <= s_PIXEL_COUNT_reg + 1;
                    
                    s_buffer_start_reg <= 1'b1;
                end
            end
            else
                s_buffer_start_reg <= 1'b0;
        end
    endcase
    end
    
    //assign outputs
    assign o_SCK             = s_SCK;
    assign o_MOSI_FINAL_BIT  = s_MOSI_FINAL_BIT;
    assign o_MOSI_FINAL_BYTE = s_MOSI_FINAL_BYTE;
    
endmodule