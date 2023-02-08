module hw2(
    clk_50M,
    reset_n,    
    write,
    write_value,
    write_complete,    
    read,
    read_value,
    read_complete,   
    // spi bus
    spi_csn,
    spi_sck,
    spi_do,
    spi_di
);

localparam WREN = 8'd6;
localparam READVALUE = 8'd3;
localparam SPICLOCK = 7'd100;

localparam IDLE = 3'd0;
localparam TRANSMIT = 3'd1;
localparam GETDATA = 3'd2;

input clk_50M;
input reset_n;
input write;
input read;
input spi_di;
input [7:0] write_value;

output reg read_complete;
output reg write_complete;
output reg [7:0] read_value;
output reg spi_csn;
output reg spi_sck;
output reg spi_do;

reg [1:0] transmit;
reg [2:0] state, next_state;
reg [3:0] bit_cnt;
reg [6:0] sck_cnt, cnt;

////////////////////////////next_state//////////////////////////
always @(*) begin
    case (state) 
    	IDLE:   begin
                    if(read) begin
                        next_state = GETDATA;
                    end else if(write) begin
                        next_state = TRANSMIT;
                    end else begin
                        next_state = IDLE;
                    end
                end
    	TRANSMIT: next_state = (bit_cnt == 4'd8) ? IDLE : TRANSMIT; 
        GETDATA: next_state = (bit_cnt == 4'd8) ? IDLE : GETDATA;
    	default: next_state = IDLE;
    endcase
end

///////////////////////////state//////////////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
    	state <= 3'd0;
    end else begin
    	state <= next_state;
    end
end

//////////////////////cnt////////////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
        cnt <= 7'd0;
    end else begin
        case (state)
            IDLE : cnt <= (cnt == SPICLOCK) ? 7'd0 : cnt + 7'd1;
            default : cnt <= 7'd0;
        endcase
    end
end

//////////////////////sck_cnt////////////////////////
always @(posedge clk_50M or negedge reset_n) begin 
	if(~reset_n) begin
	    sck_cnt <= 7'd0;
	end else begin
		case (state)
			TRANSMIT,GETDATA: sck_cnt <= (sck_cnt == SPICLOCK) ? 7'd1 : sck_cnt + 7'd1;
			default: sck_cnt <= 7'd0;
		endcase
	end    
end

/////////////////////spi_sck/////////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
       spi_sck <= 1'b0; 
    end else begin
    	case (state)
    	    TRANSMIT,GETDATA:   begin
                                    if(sck_cnt == SPICLOCK) begin
                                    	spi_sck <= 1'b0;
                                    end else if(sck_cnt == SPICLOCK/2) begin
                                    	spi_sck <= 1'b1;
                                    end
    	     				    end
			default: spi_sck <= 1'b0;
    	endcase
    end
end

///////////////////spi_csn///////////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
    	spi_csn <= 1'b1;
    end else begin
    	case (state)
    		IDLE: spi_csn <= (cnt == SPICLOCK) ? 1'b1 : spi_csn;
    		TRANSMIT,GETDATA: spi_csn <= 1'b0;
			default: spi_csn <= 1'b1;
    	endcase
    end
end

///////////////////bit_cnt////////////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
    	bit_cnt <= 4'd0;
   	end else begin
   		case (state)
   			TRANSMIT,GETDATA: bit_cnt <= (sck_cnt == SPICLOCK) ? bit_cnt + 4'd1 : bit_cnt;
   			default: bit_cnt <= 4'd0;
   		endcase
   	end
end

////////////////////transmit/////////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
        transmit <= 2'd0;
    end else begin
    	case (state) 
    		TRANSMIT,GETDATA: transmit <= (write_value != WREN && bit_cnt == 4'd8) ? transmit + 2'd1 : transmit;
    		default: transmit <= (transmit == 2'd3) ? 2'd0 : transmit;
    	endcase
   	end    
end

//////////////////write_complete////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
    	write_complete <= 1'b1;
    end else begin
    	case (state) 
    		TRANSMIT,GETDATA: write_complete <= 1'b0;
    		default: write_complete <= 1'b1;
    	endcase
    end
end

/////////////////spi_do/////////////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
        spi_do <= 1'b0;
    end else begin
    	case (state) 
    		TRANSMIT,GETDATA:   begin
                                    case (bit_cnt)
                                    	4'd0 : spi_do <= write_value[7];
                                    	4'd1 : spi_do <= write_value[6];
                                    	4'd2 : spi_do <= write_value[5];
                                    	4'd3 : spi_do <= write_value[4];
                                    	4'd4 : spi_do <= write_value[3];
                                    	4'd5 : spi_do <= write_value[2];
                                    	4'd6 : spi_do <= write_value[1];
                                    	4'd7 : spi_do <= write_value[0];
                                    	default : spi_do <= 1'b0; 
                                    endcase
    				            end
    		default: spi_do <= 1'b0;
    	endcase
    end 
end

/////////////////////////read_value/////////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
        read_value <= 8'bzzzzzzzz;
    end else begin
        case (state)
            TRANSMIT:   begin
                            if(sck_cnt == SPICLOCK/2) begin
                                read_value <= {read_value[6:0],1'bz};
                            end
                        end
            GETDATA: read_value <= (sck_cnt == SPICLOCK) ? {read_value,spi_di} : read_value;
            default: read_value <= read_value;
        endcase
    end
end

///////////////////////read_complete//////////////////
always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
        read_complete <= 1'b1;
    end else begin
        case (state)
            TRANSMIT: read_complete <= (write_value == READVALUE) ? 1'b0 : read_complete;
            GETDATA: read_complete <= (bit_cnt == 8'd8) ? 1'b1 : read_complete;
            default: read_complete <= read_complete;
        endcase
    end
end

endmodule 