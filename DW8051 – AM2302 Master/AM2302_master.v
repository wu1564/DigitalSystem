module AM2302_master (
	input clk,
	input rst_n,
	input sfr_rd,
	input sfr_wr,
	input [8-1:0] sfr_addr,
	input [8-1:0] sfr_data_out,
	output reg [8-1:0] sfr_data_in,
	inout sda
);     

////////////////////////////Parameters///////////////////////////
localparam IDLE = 3'd0;
localparam START = 3'd1;
localparam RECEIVE = 3'd2;
localparam ACK = 3'd3;
localparam GIVE_DATA = 3'd4;
localparam START_SIGNAL = 32'd36927; //1ms
localparam BIT_0 = 32'd2954;   		 //80us
localparam BIT_1 = 32'd4357;   		 //118us
/////////////////////////////////////////////////////////////////

///////////////////////////port declarations/////////////////////
wire start_read;
wire read_0x11;
wire sda_neg_edge;
reg temp[0:1];
reg [2:0] state, next_state;
reg enable;
reg [5:0] bitCounter;
reg [31:0] cnt;
reg [7:0] data[0:4];
/////////////////////////////////////////////////////////////////

///////////////////////////////wires/////////////////////////////
assign start_read 	= (sfr_wr && sfr_addr == 8'he1 && sfr_data_out == 8'd01) ? 1'b1 : 1'b0;
assign read_0x11 	= (sfr_rd && sfr_addr == 8'he1) ? 1'b1 : 1'b0;
assign sda_neg_edge = ~temp[0] & temp[1];
assign sda 			= (enable) ? 1'b0 : 1'bz;
/////////////////////////////////////////////////////////////////

////////////////////////////////temp/////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        temp[0] <= 1'b0;
        temp[1] <= 1'b0;
    end else begin
        case (state)
        	RECEIVE:	begin
        					temp[0] <= (sda == 1'b1 || sda == 1'b0) ? sda : temp[0];
        					temp[1] <= temp[0];
        				end 	
            default:	begin
            				temp[0] <= temp[0];
            				temp[1] <= temp[1];
            			end 
        endcase
    end
end
/////////////////////////////////////////////////////////////////

//////////////////////////////next_state/////////////////////////
always @(*) begin
    case (state)
    	IDLE:		next_state = (start_read) ? START : IDLE;
    	START:		next_state = (cnt == START_SIGNAL) ? RECEIVE : START;
    	RECEIVE:	next_state = (bitCounter == 6'd40 && sda_neg_edge) ? ACK : RECEIVE;
    	ACK:		next_state = (read_0x11) ? GIVE_DATA: ACK;
    	GIVE_DATA:	next_state = GIVE_DATA;
    	default: 	next_state = IDLE;
    endcase
end
/////////////////////////////////////////////////////////////////

//////////////////////////////state//////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end
/////////////////////////////////////////////////////////////////

////////////////////////////////enable///////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        enable <= 1'b0;
    end else begin
        case (state)
	        START:		begin
	        				case(cnt)
	        					32'd0:			enable <= 1'b1;
	        					START_SIGNAL:	enable <= 1'b0;
	        					default: 		enable <= enable;
	        				endcase
	   			    	end 
            default:	enable <= 1'b0;
        endcase
    end
end
/////////////////////////////////////////////////////////////////

//////////////////////////////////cnt////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cnt <= 32'd0;
    end else begin
        case (state)
            START:   	cnt <= (cnt == START_SIGNAL) ? 32'd0 : cnt + 32'd1;
            RECEIVE:	cnt <= (sda_neg_edge) ? 32'd0 : cnt + 32'd1;
            default: 	cnt <= 32'd0;
        endcase
    end
end
/////////////////////////////////////////////////////////////////

///////////////////////////bitCounter////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        bitCounter <= 6'h3f;
    end else begin
        case (state)
            RECEIVE: bitCounter <= (sda_neg_edge) ? bitCounter + 6'd1 : bitCounter;
            default: bitCounter <= bitCounter;
        endcase
    end
end
/////////////////////////////////////////////////////////////////

/////////////////////////////data////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data[0] <= 8'd0;
        data[1] <= 8'd0;
        data[2] <= 8'd0;
        data[3] <= 8'd0;
        data[4] <= 8'd0;
    end else begin
        case (state)
        	RECEIVE:	begin
        					if(sda_neg_edge) begin
	        					if(bitCounter >= 6'd33) begin
	        						if(cnt < BIT_0) begin
	        							data[4] <= {data[4],1'b0};
	        						end else if(cnt > BIT_1) begin
	        						    data[4] <= {data[4],1'b1};
	        						end 
	        					end else if(bitCounter >= 6'd25) begin
	        					    if(cnt < BIT_0) begin
	        							data[3] <= {data[3],1'b0};
	        						end else if(cnt > BIT_1) begin
	        						    data[3] <= {data[3],1'b1};
	        						end 
	        					end else if(bitCounter >= 6'd17) begin
	        					    if(cnt < BIT_0) begin
	        							data[2] <= {data[2],1'b0};
	        						end else if(cnt > BIT_1) begin
	        						    data[2] <= {data[2],1'b1};
	        						end 
	        					end else if(bitCounter >= 6'd9) begin
	        					    if(cnt < BIT_0) begin
	        							data[1] <= {data[1],1'b0};
	        						end else if(cnt > BIT_1) begin
	        						    data[1] <= {data[1],1'b1};
	        						end 
	        					end else if(bitCounter >= 6'd1) begin
	        					    if(cnt < BIT_0) begin
	        							data[0] <= {data[0],1'b0};
	        						end else if(cnt > BIT_1) begin
	        						    data[0] <= {data[0],1'b1};
	        						end 
	        					end 	
        					end 
        				end 
        	default:	begin
					        data[0] <= data[0];
					        data[1] <= data[1];
					        data[2] <= data[2];
					        data[3] <= data[3];
					        data[4] <= data[4];
        				end 
        endcase
    end
end
/////////////////////////////////////////////////////////////////

//////////////////////////////sfr_data_in////////////////////////
always @(*) begin
    case (state)
    	IDLE:		sfr_data_in <= 8'd0;
        ACK:		sfr_data_in <= 8'b0000_1001;
        GIVE_DATA:	begin
        				if(sfr_rd) begin
        					case (sfr_addr)
        						8'he2:		sfr_data_in <= data[0];
        						8'he3:		sfr_data_in <= data[1];
        						8'he4:		sfr_data_in <= data[2];
        						8'he5:		sfr_data_in <= data[3];
        						8'he6:		sfr_data_in <= data[4];
        						default: 	sfr_data_in <= 8'hzz;
        					endcase
        				end else begin
        				    sfr_data_in <= 8'hzz;
        				end
        			end
        default: 	sfr_data_in <= 8'h01;
    endcase
end
/////////////////////////////////////////////////////////////////

endmodule
