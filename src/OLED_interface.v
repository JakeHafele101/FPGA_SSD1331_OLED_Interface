
module OLED_interface (input i_CLK,
                       input i_RST,
                       input [1:0] i_MODE,
                       input i_START,
                       output o_CS,
                       output o_MOSI,
                       output o_SCK,
                       output o_DC,
                       output reg o_RES, //OLED power reset, active low reset
                       output reg o_VCCEN, //VCC enable, active high drives VCC 
                       output reg o_PMODEN //VDD logic voltage control. active high, drives PGND on schem
                       ); 
    
    parameter WIDTH = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N     = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    
    
    //Internal states
    localparam idle = 1'b0,
    transmit = 1'b1;
    
    //Internal signals
    reg s_state_reg;  //state register
    wire s_SCK;

    //Buffer signals
    wire [(WIDTH*N)-1:0] s_DATA_buffer; //FIXME, wire to col/row
    wire [N-1:0] s_DC_buffer;
    wire s_start_buffer;
    wire [4:0] s_N_transmit_buffer;
    wire [WIDTH-1:0] s_BYTE;

    //MOSI signals
    wire s_DC_mosi, s_start_mosi;

    //Modules
    Nbit_MOSI_SPI_Buffer #() g_Nbit_MOSI_SPI_Buffer
    (.i_SCK(s_SCK),
    .i_RST(i_RST),
    .i_DATA(s_DATA_buffer),
    .i_DC(s_DC_buffer),
    .i_START(s_start_buffer),
    .i_N_transmit(s_N_transmit_buffer),
    .o_DATA(s_BYTE), //byte to transmit
    .o_START(s_start_mosi), //when to start loading byte
    .o_DC(s_DC_mosi),
    .o_MOSI_FINAL_BYTE(s_MOSI_FINAL_BYTE)
    );

    Nbit_MOSI_SPI #(.WIDTH(WIDTH)) g_Nbit_MOSI_SPI
    (.i_SCK(s_SCK),
    .i_RST(i_RST),
    .i_DATA(s_BYTE),
    .i_START(s_start_mosi),
    .i_DC(s_DC_mosi), 
    .o_MOSI(o_MOSI),
    .o_CS(o_CS),
    .o_DC(o_DC),
    .o_MOSI_FINAL_TX(o_MOSI_FINAL_TX)
    );

    always @(posedge i_SCK, posedge i_RST)
        if (i_RST)
        begin
            s_state_reg <= idle;
            o_RES <= 1'b1;
            o_VCCEN <= 1'b0;
            o_PMODEN <= 1'b0;
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
