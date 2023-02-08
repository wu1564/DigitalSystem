module hw3(
	clk,
	rst_in_n,

	//sfr bus
	sfr_rd,
	sfr_wr,       
	sfr_addr,     
	sfr_data_out,
	sfr_data_in,

	// i2c
	i2c_sda,
	i2c_scl
);

localparam IDLE = 3'd0;
localparam STARTBIT = 3'd1;
localparam TRANSMIT = 3'd2;
localparam STOPBIT = 3'd3;
localparam I2C_CLOCK = 12'd115;          //1500ns + 800ns
localparam I2C_WIDTH = 12'd75;           //1500ns
localparam DATA_CHANGE_ALLOWED = 12'd37; //750ns
localparam STOPBIT_TIMING = 12'd100;     //1500ns + 500ns

input clk;
input rst_in_n;

// sfr bus
input sfr_rd;  
input sfr_wr;
input [8-1:0] sfr_addr;
input [8-1:0] sfr_data_out;
output reg [8-1:0] sfr_data_in;

// i2c
inout i2c_sda;     
output reg i2c_scl;

wire i2c_control_bus;
wire start;
wire stop;
wire read;
wire data_bus;
wire byte_done;
reg ena;
reg i2c_sda_reg;
reg [3-1:0] state, next_state, byte_cnt;
reg [4-1:0] bit_cnt;
reg [8-1:0] value;
reg [12-1:0] i2c_cnt;

//////////////////////////////wires/////////////////////////////////////
assign i2c_control_bus = (sfr_wr && sfr_addr == 8'h9a) ? 1'b1 : 1'b0;
assign start = i2c_control_bus & sfr_data_out[4];
assign stop = i2c_control_bus & sfr_data_out[5];
assign read = (sfr_rd && sfr_addr == 8'h9b) ? 1'b1 : 1'b0;
assign data_bus = (sfr_wr && sfr_addr == 8'h9c) ? 1'b1 : 1'b0;
assign byte_done = (bit_cnt == 4'd8 && i2c_cnt == I2C_CLOCK) ? 1'b1 : 1'b0;
assign i2c_sda = (ena) ? i2c_sda_reg : 1'bz;
///////////////////////////////////////////////////////////////////////

/////////////////////next_state//////////////////
always @(*) begin
    case (state)
    	IDLE: next_state = (start) ? STARTBIT : IDLE;
    	STARTBIT: next_state = (i2c_cnt == I2C_CLOCK) ? TRANSMIT : STARTBIT;
    	TRANSMIT: next_state = (byte_cnt == 3'd3 && byte_done) ? STOPBIT : TRANSMIT;
    	STOPBIT:  next_state = (i2c_cnt == I2C_CLOCK) ? IDLE : STOPBIT;
    	default:  next_state = IDLE;
   	endcase
end

/////////////////////state///////////////////////
always @(posedge clk or negedge rst_in_n) begin
    if(~rst_in_n) begin
    	state <= 3'd0;
    end else begin
    	state <= next_state;
    end
end

/////////////////////value////////////////////////
always @(posedge clk or negedge rst_in_n) begin
    if(~rst_in_n) begin
        value <= 8'd0;
    end else if(data_bus) begin
    	value <= sfr_data_out;
    end
end

////////////////////i2c_cnt///////////////////
always @(posedge clk or negedge rst_in_n) begin
    if(~rst_in_n) begin
        i2c_cnt <= 12'd0;
    end else begin
    	case (state)
    		STARTBIT, STOPBIT: i2c_cnt <= (i2c_cnt == I2C_CLOCK) ? 12'd0 : i2c_cnt + 12'd1;
    		TRANSMIT: i2c_cnt <= (i2c_cnt == I2C_CLOCK) ? 12'd1 : i2c_cnt + 12'd1;
    		default:  i2c_cnt <= 12'd0;
    	endcase
    end
end

////////////////////i2c_scl//////////////////////////
always @(posedge clk or negedge rst_in_n) begin
    if(~rst_in_n) begin
        i2c_scl <= 1'b1;
    end else begin
    	case (state)
    		TRANSMIT:	begin
    						case (i2c_cnt)
    							12'd0: i2c_scl <= 1'b0;
    							I2C_WIDTH: i2c_scl <= 1'b1;
    							I2C_CLOCK: i2c_scl <= (byte_cnt == 3'd3 && byte_done) ? 1'b1 : 1'b0;
    							default: i2c_scl <= i2c_scl;
    						endcase
						end 
            STOPBIT:    begin
                            case (i2c_cnt)
                                12'd1: i2c_scl <= 1'b0;
                                I2C_WIDTH: i2c_scl <= 1'b1;
                                default: i2c_scl <= i2c_scl;
                            endcase
                        end
    		default:    i2c_scl <= 1'b1;
    	endcase
    end
end

//////////////////////bit_cnt////////////////////
always @(posedge clk or negedge rst_in_n) begin
    if(~rst_in_n) begin
        bit_cnt <= 4'd0;
    end else begin
    	case (state)
    		TRANSMIT:   begin
                            if(byte_done) begin
                                bit_cnt <= 4'd0;
                            end else if(i2c_cnt == I2C_CLOCK) begin
                                bit_cnt <= bit_cnt + 4'd1;
                            end
                        end
    		default:    bit_cnt <= 4'd0;
    	endcase
    end
end

/////////////////////byte_cnt///////////////////
always @(posedge clk or negedge rst_in_n) begin
    if(~rst_in_n) begin
        byte_cnt <= 3'd0;
    end else begin
    	case (state)
            IDLE:     byte_cnt <= 3'd0;
    		TRANSMIT: byte_cnt <= (byte_done) ? byte_cnt + 3'd1 : byte_cnt;
    		default:  byte_cnt <= byte_cnt;
    	endcase
    end
end

/////////////////////i2c_sda_reg/////////////////////
always @(posedge clk or negedge rst_in_n) begin
	if(~rst_in_n) begin
	    i2c_sda_reg <= 1'b0;
	end else begin
		case (state)
            STARTBIT:   i2c_sda_reg <= (i2c_cnt == I2C_WIDTH) ? 1'b0 : i2c_sda_reg;
			TRANSMIT:	begin
							if(i2c_cnt == DATA_CHANGE_ALLOWED) begin
								case (bit_cnt)
                                    4'd8: i2c_sda_reg <= 1'b0;
                                    default: i2c_sda_reg <= (value[7-bit_cnt]) ? 1'bz : 1'b0;
                                endcase
							end
						end
			default:    i2c_sda_reg <= 1'b0;
		endcase
	end
end

//////////////////////ena///////////////////////
always @(posedge clk or negedge rst_in_n) begin
    if(~rst_in_n) begin
        ena <= 1'b0;
    end else begin
    	case (state)
    		STARTBIT:   ena <= (i2c_cnt == I2C_WIDTH) ? 1'b1 : ena;
    		TRANSMIT:   ena <= 1'b1;
            STOPBIT:    begin
                            case (i2c_cnt)
                                STOPBIT_TIMING: ena <= 1'b0;
                                default: ena <= ena;
                            endcase
                        end
    		default:    ena <= 1'b0;
    	endcase
    end
end

////////////////////sfr_data_in////////////////////
always @(posedge clk or negedge rst_in_n) begin
	if(~rst_in_n) begin
	    sfr_data_in <= 8'd0;
	end else begin
		case (state)
			TRANSMIT:   begin
                            if(read && sfr_data_in == 8'd1) begin
                                sfr_data_in <= 8'd0;
                            end else if(bit_cnt == 4'd7 && i2c_cnt == 12'd1) begin
                                sfr_data_in <= 8'd1;
                            end
                        end
            default:    sfr_data_in <= 8'd0;
		endcase
	end
end

endmodule
