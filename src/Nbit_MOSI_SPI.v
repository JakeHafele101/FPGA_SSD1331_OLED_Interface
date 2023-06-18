
module Nbit_MOSI_SPI (input i_SCK,
                      input i_RST,
                      input [WIDTH-1: 0] i_DATA,
                      input i_START,               //initiate transmit on MOSI
                      input i_DC,                  //DATA/COMMAND bits
                      output reg o_MOSI,           //update bit on falling edge
                      output reg o_CS,
                      output reg o_DC,             //DATA/COMMAND bit
                      output reg o_MOSI_FINAL_TX); //asserted after last bit transmitted
    
    parameter WIDTH = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    
    localparam idle = 1'b0,
    transmit = 1'b1;
    
    reg      s_state_reg;  //state register
    reg [WIDTH-1:0] s_data_reg;   //reg to store N bits to transfer over MOSI
    reg [4:0] s_bit_reg; //count of how many bits transmitted (up to 32, can increase if needed)
    
    reg s_MOSI_LSB; //holds LSB bit for crossover
    
    always @(negedge i_SCK, posedge i_RST)
        if (i_RST)
        begin
            s_state_reg     <= idle;
            s_data_reg      <= 0;
            o_MOSI          <= 1'b0;
            o_CS            <= 1'b1;
            o_DC            <= 1'b0;
            o_MOSI_FINAL_TX <= 1'b0;
            s_bit_reg       <= 0;
        end
    
    else
    begin
    case(s_state_reg)
        idle:
        begin
            o_MOSI_FINAL_TX <= 1'b0;
            if (i_START)
            begin
                s_state_reg <= transmit;
                
                o_MOSI <= i_DATA[WIDTH-1];
                o_CS   <= 1'b0;
                o_DC   <= i_DC;
                
                s_bit_reg  <= 1; //start at second MSB
                s_MOSI_LSB <= i_DATA[0]; //Save LSB for last transmit
                s_data_reg <= i_DATA << 1;
                
            end
            else
                o_CS <= 1'b1;
        end
        transmit:
        begin
            if (s_bit_reg == 0) //if first bit, update o_DC
            begin
                o_DC <= i_DC; //assign new D/C bit
                o_MOSI_FINAL_TX <= 1'b0;
            end
            else if (s_bit_reg == WIDTH - 2) //If transmitting second to last bit of byte
            begin
                o_MOSI_FINAL_TX <= 1'b1; //flag indicating next bit is last tx
            end

            if (s_bit_reg >= WIDTH - 1) //If transmitting last bit of byte
            begin
                o_MOSI          <= s_MOSI_LSB;
                o_MOSI_FINAL_TX <= 1'b0;
                if (i_START == 1'b1) //if transmitting another byte, stay in state but reset bit count
                begin
                    s_bit_reg  <= 0;
                    s_data_reg <= i_DATA;
                    s_MOSI_LSB <= i_DATA[0];
                end
                else //idle if not immediately transmitting another byte
                    s_state_reg <= idle;
            end
            else //if not last bit
            begin
                o_MOSI          <= s_data_reg[WIDTH-1];
                s_data_reg      <= s_data_reg << 1; //shift transmit bits left 1 since MSB received first
                s_bit_reg       <= s_bit_reg + 1;
            end
            
        end
    endcase
    
    end
    
endmodule
