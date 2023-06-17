
`include "SSD1331_defines.v"

module OLED_interface (input i_CLK,
                       input i_RST,
                       input [1:0] i_MODE,
                       input i_START,
                       input [N_COLOR_BITS-1:0] i_TEXT_COLOR,
                       input [N_COLOR_BITS-1:0] i_BACKGROUND_COLOR,
                       input [NUM_COL*NUM_ROW - 1:0] i_PIXEL,       //1 if text color, 0 if background color
                       output reg o_READY,                          //ready to take in i_MODE and i_START for command
                       output o_CS,
                       output o_MOSI,
                       output o_SCK,
                       output o_DC,
                       output reg o_RES,                            //OLED power reset, active low reset
                       output reg o_VCCEN,                          //VCC enable, active high drives VCC
                       output reg o_PMODEN);                        //VDD logic voltage control. active high, drives PGND on schem
    
    parameter WIDTH        = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N            = 8; //# of bytes that can be loaded at once for MOSI
    parameter SCLK_DIVIDER = 20; //Minimum 150ns Period (or 6.66 MHz), divided 100 MHz down to 5MHz
    
    //Wait times. 100MHz clock, 10ns period. # ticks = wait time / clock period
    //If using SCLK, 5MHz clock, 200ns period
    parameter WAIT_3_US   = 20; //Count up to X ticks to wait on 100MHz clock, only needs 15
    parameter WAIT_100_MS = 600000; //Needs 500000
    
    parameter NUM_COL = 96; //# of columns in OLED array
    parameter NUM_ROW = 64; //# of rows in OLED array
    
    parameter N_COLOR_BITS = 8;
    
    //Internal states
    localparam idle = 4'b0000,
    turnon_1 = 4'b0001,
    turnon_2 = 4'b0010,
    turnon_3 = 4'b0011,
    turnon_4 = 4'b0100,
    fill_screen_1 = 4'b0101,
    pixel_display_1 = 4'b0110,
    pixel_display_2 = 4'b0111;
    
    //Mode selection
    localparam turnon = 2'b00,
    fill_screen = 2'b01,
    pixel_display = 2'b10;
    
    //Internal signals
    reg [3:0] s_state_reg;  //state register
    reg [31:0] s_count_reg; //counter for delays between turn on/off
    reg s_buffer_start_reg;
    reg s_init_reg; //0 if turnon not complete, 1 if so
    
    //Pixel internal
    reg [NUM_COL*NUM_ROW - 1:0] s_PIXEL_reg; //load before full pixel sweep
    reg [31:0] s_PIXEL_COUNT_reg; //counter for what pixel displayed
    
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
    
    
    always @(posedge s_SCK, posedge i_RST)
        if (i_RST)
        begin
            s_state_reg        <= idle;
            s_buffer_start_reg <= 1'b0;
            s_count_reg        <= 0;
            s_DATA             <= 0;
            s_DC               <= 0;
            s_N_transmit       <= 0;
            s_init_reg         <= 1'b0;
            s_PIXEL_reg        <= 0;
            s_PIXEL_COUNT_reg  <= 0;
            o_RES              <= 1'b1;
            o_VCCEN            <= 1'b0;
            o_PMODEN           <= 1'b0;
            o_READY            <= 1'b0;
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
                        s_state_reg <= fill_screen_1;
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
            s_DATA[(WIDTH-1)+WIDTH*2:0] <= {8'h40, 8'hA0, 8'hAF}; //Display ON, set to 256 color display
            s_DC[2:0]                   <= 3'b100; //Write command
            s_N_transmit                <= 3; //transmit 1 byte
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
            s_DATA[WIDTH-1:0]  <= i_BACKGROUND_COLOR; //Send text color to fill background
            s_DC[0]            <= 1'b1; //Data command
            s_N_transmit       <= 1; //transmit 1 byte
            s_buffer_start_reg <= 1'b1;
            
            s_state_reg <= idle;
        end
        
        pixel_display_1: //Set starting and ending addressses for row/column
        begin
            //Command, 0xAF, send one byte to buffer/MOSI
            s_DATA[(WIDTH-1)+WIDTH*5:0] <= {8'h5D, 8'h00, 8'h15, 8'h3F, 8'h00, 8'h75}; //Send white pixel
            s_DC[5:0]                   <= 6'b110110; //Data 1, command 0
            s_N_transmit                <= 6; //transmit 6 bytes
            s_buffer_start_reg          <= 1'b1;
            
            s_PIXEL_reg <= i_PIXEL; //Load 96x64 pixel array
            s_PIXEL_COUNT_reg  <= 0;
            
            s_state_reg <= pixel_display_2;
        end
        
        pixel_display_2: //Send 1 pixel at a time
        begin
            if(s_MOSI_FINAL_BIT == 1'b1 || s_PIXEL_COUNT_reg == 0) //If transmitting last bit or starting, check next byte
                if(s_PIXEL_COUNT_reg >= NUM_ROW*NUM_COL) //if sent all bytes, leave 
                begin
                    s_state_reg <= idle;
                    s_buffer_start_reg <= 1'b0;
                end
                else //transmit next byte
                begin
                    s_PIXEL_COUNT_reg <= s_PIXEL_COUNT_reg + 1;
                    s_PIXEL_reg <= s_PIXEL_reg << 1;

                    //Choose color to send
                    if(s_PIXEL_reg[NUM_ROW*NUM_COL - 1] == 1'b0)  //send background color
                    begin
                        s_DATA[WIDTH-1:0]  <= i_BACKGROUND_COLOR; //Send white pixel
                    end
                    else  //send text color
                    begin
                        s_DATA[WIDTH-1:0]  <= i_BACKGROUND_COLOR; //Send white pixel
                    end
                    s_DC[0]          <= 1'b0; //Data 1, command 0
                    s_N_transmit     <= 1; //transmit 4 bytes
                    s_buffer_start_reg <= 1'b1;
                end
            end
        endcase
    end
    
    //assign outputs
    assign o_SCK = s_SCK;
    
    
endmodule
