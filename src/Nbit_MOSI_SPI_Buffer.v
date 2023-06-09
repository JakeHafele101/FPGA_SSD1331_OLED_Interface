
module Nbit_MOSI_SPI_Buffer (input i_SCK,
                             input i_RST,
                             input [(WIDTH*N)-1:0]i_DATA, //N sets of WIDTH bits to transfer
                             input [N-1:0] i_DC,               //DATA/COMMAND bit
                             input i_START,                    //initiate transmit on MOSI
                             input i_N_transmit,               //# of N bytes to transmit
                             output reg [WIDTH-1:0] o_DATA,    //byte to send to SPI over MOSI
                             output reg o_START,               //When 1, send another byte over MOSI
                             output reg o_CS, 
                             output reg o_DC,                  //DATA/COMMAND bit for byte
                             output reg o_MOSI_FINAL_BYTE);      //asserted after last bit transmitted
    
    parameter WIDTH = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N     = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    
    localparam idle = 1'b0,
    transmit = 1'b1;
    
    reg s_state_reg;  //state register
    reg [(WIDTH*N)-1:0] s_data_reg;   //reg to store N bits to transfer over MOSI
    reg [4:0] s_byte_reg; //count of how many bytes transmitted (up to 32, can increase if needed)
    reg [N-1:0] s_DC_reg; //
    reg [4:0] s_bit_reg; //count for what bit is being transmitted, needed to know when to update byte written
    
    reg s_MOSI_LSB; //holds LSB bit for crossover
    
    
    always @(posedge i_SCK, posedge i_RST)
        if (i_RST)
        begin
            s_state_reg     <= idle;
            s_data_reg      <= 0;
            s_byte_reg      <= 0; //may explode? how to reset properly?
            s_bit_reg       <= 0;
            o_DATA          <= 0;
            o_START         <= 1'b0;
            o_CS            <= 1'b1;
            o_DC            <= 1'b0;
            o_MOSI_FINAL_BYTE <= 1'b0;
        end
    
    else
    begin
    case(s_state_reg)
        idle:
        begin
            o_MOSI_FINAL_BYTE <= 1'b0;
            if (i_START)
            begin
                s_state_reg <= transmit;
                
                s_data_reg <= i_DATA; //load all bytes to internal reg
                s_DC_reg   <= i_DC; //load all D/C commands to internal reg
                
                o_START <= 1'b1; //start transmitting bytes
                o_CS   <= 1'b0; //active low, will now take bits on posedge of SCK on slave side
                o_DC    <= i_DC[0]; //first D/C control
                o_DATA  <= i_DATA[WIDTH-1:0]; //first byte
                
                s_byte_reg <= 1; //start at second MSB since loading up first byte
                s_bit_reg  <= 0;  //start at transmitting bit 0, FIXME?
            end
            else
                o_CS   <= 1'b1; //active low, will now take bits on posedge of SCK on slave side
        end
        transmit:
        begin
            if (s_byte_reg == 0) //if first bit, update o_DC
                o_DC <= i_DC; //assign new D/C bit
            
            if (s_bit_reg >= WIDTH - 1) //if on last bit of byte in MOSI
            begin
                if (s_byte_reg >= N) //If transmitted last byte FIXME
                begin
                    o_MOSI_FINAL_BYTE <= 1'b1;
                    if (i_START == 1'b1) //if transmitting another set of bytes, stay in state, reassign, reset counts
                    begin
                        s_state_reg <= idle;
                        
                        s_data_reg <= i_DATA; //load all bytes to internal reg
                        s_DC_reg   <= i_DC; //load all D/C commands to internal reg
                        
                        o_DC    <= i_DC[0]; //first D/C control
                        o_DATA  <= i_DATA[WIDTH-1:0]; //first byte
                        s_byte_reg <= 1; //start at second MSB since loading up first byte
                        s_bit_reg  <= 0;  //start at transmitting bit 0, FIXME?

                        o_MOSI_FINAL_BYTE <= 1'b1;
                    end
                    else //idle if not immediately transmitting another byte
                        s_state_reg <= idle;
                end
                else //if not last byte, load next one
                begin
                    o_DATA          <= s_data_reg[WIDTH-1:0]; //load next byte
                    o_DC            <= s_DC_reg[s_byte_reg];
                    o_MOSI_FINAL_BYTE <= 1'b0; //ensure final byte flag not raised
                    s_byte_reg      <= s_byte_reg + 1; //increment byte address
                end
                s_data_reg <= s_data_reg >> 8; //Shift right 8 bits, so next byte can be loaded
                s_bit_reg <= 0;
            end
            else
            begin
                s_bit_reg <= s_bit_reg + 1;
                o_MOSI_FINAL_BYTE <= 1'b0; //ensure final byte flag not raised
            end

            
        end
    endcase
    
    end
    
endmodule
