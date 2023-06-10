
module OLED_interface (input i_CLK,
                       input i_RST,
                       input [1:0] i_MODE,
                       input i_START,
                       output o_CS,
                       output o_MOSI,
                       output o_SCK,
                       output o_DC,
                       output reg o_RES,     //OLED power reset, active low reset
                       output reg o_VCCEN,   //VCC enable, active high drives VCC
                       output reg o_PMODEN); //VDD logic voltage control. active high, drives PGND on schem
    
    parameter WIDTH        = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N            = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter SCLK_DIVIDER = 20; //Minimum 150ns Period (or 6.66 MHz), divided 100 MHz down to 5MHz
    
    
    //Internal states
    localparam idle = 1'b0,
    transmit = 1'b1;
    
    //Internal signals
    reg s_state_reg;  //state register
    
    //Buffer module
    wire s_SCK;
    wire [(WIDTH*N)-1:0] s_DATA; //FIXME, wire to col/row
    wire [N-1:0] s_DC;
    wire s_START;
    wire [4:0] s_N_transmit;
    
    wire s_MOSI_FINAL_BYTE;
    wire s_MOSI_FINAL_BIT;
    
    //Buffer signals
    wire [4:0] s_N_transmit_buffer;
    wire [WIDTH-1:0] s_BYTE;
    
    //Modules
    Nbit_MOSI_SPI_Buffer_Combined #(.WIDTH(WIDTH), .N(N)) g_Nbit_MOSI_SPI_Buffer_Combined
    (.i_SCK(s_SCK),
    .i_RST(i_RST),
    .i_DATA(s_DATA),
    .i_DC(s_DC),
    .i_START(s_START),
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
    .o_TICK(s_SCK),
    );
    
    
    always @(posedge i_SCK, posedge i_RST)
        if (i_RST)
        begin
            s_state_reg <= idle;
            o_RES       <= 1'b1;
            o_VCCEN     <= 1'b0;
            o_PMODEN    <= 1'b0;
        end
    
    else
    begin
    case(s_state_reg)
        idle:
        begin
            
        end
        
        transmit:
        begin
            
        end
    endcase
    
    end
    
    
endmodule
