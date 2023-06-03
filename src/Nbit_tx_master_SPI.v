
module Nbit_tx_master_SPI (
    input i_SCK, 
    input [SIZE-1: 0] i_DATA,
    input i_START,
    output o_MOSI //update bit on falling edge
);

parameter SIZE = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    
endmodule