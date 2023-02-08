
module hw1(
	clk_50M,
    reset_n,
    write,
    write_value,
    uart_txd
 );

input clk_50M, reset_n, write;
input [7:0] write_value;
output reg uart_txd;

reg [1:0] temp;
reg [10:0] value;
reg [31:0] cnt;

wire write_neg_pulse, uart_pulse;
assign write_neg_pulse = (~temp[0] & temp[1]) ? 1'b1 : 1'b0;
assign uart_pulse = (cnt == 5208) ? 1'b1 : 1'b0;

always @(posedge clk_50M or negedge reset_n) begin
	if(~reset_n) begin
		temp[0] <= 1'b0;
		temp[1] <= 1'b0;
	end else begin
		temp[0] <= write;
		temp[1] <= temp[0];
	end
end

always @(posedge clk_50M or negedge reset_n) begin
	if(~reset_n) begin
		cnt <= 0;
	end else
	    cnt <= (uart_pulse) ? 0 : cnt + 1;
end

always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
    	value <= 0;
    end else if(write_neg_pulse) begin
    	value <= {2'b11,write_value,1'b0};
    end else if(uart_pulse) begin
    	value <= {1'b0,value[10:1]};
    end
end

always @(posedge clk_50M or negedge reset_n) begin
    if(~reset_n) begin
    	uart_txd <= 1'b1;
    end else if(uart_pulse && value != 11'd0) begin
    	uart_txd <= value[0];
    end
end

endmodule
