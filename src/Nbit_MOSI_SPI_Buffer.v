
module Nbit_MOSI_SPI_Buffer (input i_SCK,
                             input i_RST,
                             input [(WIDTH*N)-1:0]i_DATA, //N sets of WIDTH bits to transfer
                             input [N-1:0] i_DC,               //DATA/COMMAND bit
                             input i_START,                    //initiate transmit on MOSI
                             input [4:0] i_N_transmit,         //# of N bytes to transmit
                             input i_MOSI_FINAL_BIT, //final bit going to be tx on bit MOSI
                             output reg [WIDTH-1:0] o_DATA,    //byte to send to SPI over MOSI
                             output reg o_START,               //When 1, send another byte over MOSI
                             output reg o_DC,                  //DATA/COMMAND bit for byte
                             output reg o_MOSI_FINAL_BYTE);      //asserted after last bit transmitted
    
    parameter WIDTH = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    parameter N     = 8; //# of serial bits to transmit over MOSI, loaded from i_DATA
    
    localparam idle = 1'b0,
    transmit = 1'b1;
    
    reg s_state_reg;  //state register
    reg [(WIDTH*N)-1:0] s_data_reg;   //reg to store N bits to transfer over MOSI
    reg [4:0] s_N_transmit_reg; //count of how many bytes transmitted (up to 32, can increase if needed)
    reg [4:0] s_byte_reg; //count of how many bytes transmitted (up to 32, can increase if needed)
    reg [N-1:0] s_DC_reg; //
    
    reg s_MOSI_LSB; //holds LSB bit for crossover
    
    
    always @(posedge i_SCK, posedge i_RST)
        if (i_RST)
        begin
            s_state_reg     <= idle;
            s_data_reg      <= 0;
            s_byte_reg      <= 0; //may explode? how to reset properly?
            o_DATA          <= 0;
            o_START         <= 1'b0;
            o_DC            <= 1'b0;
            o_MOSI_FINAL_BYTE <= 1'b0;
        end
    
    else
    begin
    case(s_state_reg)
        idle:
        begin
            if(i_START == 1'b1)
            begin
                if (i_N_transmit == 1)
                    o_MOSI_FINAL_BYTE <= 1'b1;
                else
                    o_MOSI_FINAL_BYTE <= 1'b0;
                
                if (i_N_transmit > 0)
                begin
                    s_state_reg <= transmit;
                    
                    s_data_reg <= i_DATA >> 8; //load all bytes to internal reg
                    s_DC_reg   <= i_DC; //load all D/C commands to internal reg
                    
                    o_START <= 1'b1; //start transmitting bytes
                    o_DC    <= i_DC[0]; //first D/C control
                    o_DATA  <= i_DATA[WIDTH-1:0]; //first byte
                    
                    s_N_transmit_reg <= i_N_transmit;
                    s_byte_reg <= 1; //start at second MSB since loading up first byte

                end
            end
            else
                o_MOSI_FINAL_BYTE <= 1'b0;

        end
        transmit:
        begin            
            if (i_MOSI_FINAL_BIT == 1'b1) //if on second to last bit of byte in MOSI, update Nbit_MOSI_SP
            begin

                if (s_byte_reg == 0) //If transmitting first byte
                begin
                    o_MOSI_FINAL_BYTE <= 1'b0;
                end
                else if (s_byte_reg == s_N_transmit_reg - 1) //If transmitting last byte
                begin
                    o_MOSI_FINAL_BYTE <= 1'b1;
                end

                if(s_byte_reg >= s_N_transmit_reg) //If on last byte
                begin
                    if (i_START == 1'b1 && (i_N_transmit > 0)) //if transmitting another set of bytes, stay in state, reassign, reset counts
                    begin
                        s_state_reg <= idle;
                        
                        s_data_reg <= i_DATA; //load all bytes to internal reg
                        s_DC_reg   <= i_DC; //load all D/C commands to internal reg
                        
                        o_START <= 1'b1; //start transmitting bytes
                        o_DC    <= i_DC[0]; //first D/C control
                        o_DATA  <= i_DATA[WIDTH-1:0]; //first byte
                        s_byte_reg <= 1; //start at second MSB since loading up first byte
                        s_N_transmit_reg <= i_N_transmit;
                    end
                    else //idle if not immediately transmitting another byte
                    begin
                        s_state_reg <= idle;
                        o_START <= 1'b0; //stop transmitting byte
                    end
                end
                else //if not last byte, load next one
                begin
                    o_DATA          <= s_data_reg[WIDTH-1:0]; //load next byte
                    o_DC            <= s_DC_reg[s_byte_reg];
                    s_byte_reg      <= s_byte_reg + 1; //increment byte address
                end
                
                s_data_reg <= s_data_reg >> 8; //Shift right 8 bits, so next byte can be loaded
            end

        end
    endcase
    
    end
    
endmodule
