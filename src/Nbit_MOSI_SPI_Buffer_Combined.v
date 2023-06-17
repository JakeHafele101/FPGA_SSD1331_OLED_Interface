
module Nbit_MOSI_SPI_Buffer_Combined (input i_SCK,
                                    input i_RST,
                                    input [(WIDTH*N)-1:0]i_DATA, //N sets of WIDTH bits to transfer
                                    input [N-1:0] i_DC,               //DATA/COMMAND bit
                                    input i_START,                    //initiate transmit on MOSI
                                    input [4:0] i_N_transmit,               //# of N bytes to transmit
                                    output o_MOSI_FINAL_BYTE,
                                    output o_MOSI, 
                                    output o_CS, 
                                    output o_DC,
                                    output o_MOSI_FINAL_BIT
                                    );      //asserted after last bit transmitted
    
    parameter WIDTH = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N     = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA

    //Internal signals
    wire [WIDTH-1:0] s_BYTE;
    wire s_START_mosi;
    wire s_DC_mosi;

    //Modules
    Nbit_MOSI_SPI_Buffer #(.WIDTH(WIDTH), .N(N)) g_Nbit_MOSI_SPI_Buffer
    (.i_SCK(i_SCK),
    .i_RST(i_RST),
    .i_DATA(i_DATA),
    .i_DC(i_DC),
    .i_START(i_START),
    .i_N_transmit(i_N_transmit),
    .i_MOSI_FINAL_BIT(o_MOSI_FINAL_BIT),
    .o_DATA(s_BYTE), //byte to transmit
    .o_START(s_start_mosi), //when to start loading byte
    .o_DC(s_DC_mosi),
    .o_MOSI_FINAL_BYTE(o_MOSI_FINAL_BYTE)
    );

    Nbit_MOSI_SPI #(.WIDTH(WIDTH)) g_Nbit_MOSI_SPI
    (.i_SCK(i_SCK),
    .i_RST(i_RST),
    .i_DATA(s_BYTE),
    .i_START(s_start_mosi),
    .i_DC(s_DC_mosi), 
    .o_MOSI(o_MOSI),
    .o_CS(o_CS),
    .o_DC(o_DC),
    .o_MOSI_FINAL_TX(o_MOSI_FINAL_BIT)
    );
    
endmodule
