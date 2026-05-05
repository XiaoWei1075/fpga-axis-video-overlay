`timescale 1 ns / 1 ns

module fwft_fifo #
(
	parameter integer DATA_WIDTH = 64,
	parameter integer ERAM_ADDR_WIDTH = 13
)
(
	input wire clk,
	input wire rst_n,
	
	input wire clr_eram_ptr,
	
	input wire [DATA_WIDTH-1:0] din,
	output reg [ERAM_ADDR_WIDTH-1:0] eram_ptr,
	input wire [1:0] pixel_format,
	
	input wire [ERAM_ADDR_WIDTH-1:0] active_item_count,
	output wire [DATA_WIDTH-1:0] dout,
	input wire pop
);
	localparam DEPTH = 8;
	localparam ADDR_WIDTH = $clog2(DEPTH);

	reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	localparam [1:0] RGB888 = 2'b00;
	localparam [1:0] BGR888 = 2'b01;
	localparam [1:0] RGB565 = 2'b10;
	localparam [1:0] BGR565 = 2'b11;

	function [23:0] to_rgb888;
		input [23:0] pixel_in;
		input [1:0] format_sel;
		reg [4:0] r5;
		reg [5:0] g6;
		reg [4:0] b5;
		begin
			case (format_sel)
				RGB888: to_rgb888 = pixel_in;
				BGR888: to_rgb888 = {pixel_in[7:0], pixel_in[15:8], pixel_in[23:16]};
				RGB565:
				begin
					r5 = pixel_in[15:11];
					g6 = pixel_in[10:5];
					b5 = pixel_in[4:0];
					to_rgb888 = {{r5, r5[4:2]}, {g6, g6[5:4]}, {b5, b5[4:2]}};
				end
				BGR565:
				begin
					b5 = pixel_in[15:11];
					g6 = pixel_in[10:5];
					r5 = pixel_in[4:0];
					to_rgb888 = {{r5, r5[4:2]}, {g6, g6[5:4]}, {b5, b5[4:2]}};
				end
				default: to_rgb888 = pixel_in;
			endcase
		end
	endfunction

	reg [ADDR_WIDTH:0] wr_ptr;
	reg [ADDR_WIDTH:0] rd_ptr;
	wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];
	wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

	wire empty = (wr_ptr == rd_ptr);
	wire full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && (wr_addr == rd_addr);

	assign dout  = mem[rd_addr];

	wire do_pop  = pop && (!empty);

	wire [DATA_WIDTH-1:0] din_conv = {din[63:24], to_rgb888(din[23:0], pixel_format)};

	// The memory read has one clock of latency.
	// do_push is the read request of the current eram_ptr.
	// do_push_d goes high one clock later, when din is valid and should be written into the fifo.
	reg do_push_d;

	// wr_ptr_eff and rd_ptr_eff are the predicted pointers after this clock edge.
	// They include the write caused by do_push_d and the read caused by do_pop in this same cycle.
	// full_after is based on these predicted pointers, so do_push will not create an overflow.
	wire [ADDR_WIDTH:0] wr_ptr_eff = wr_ptr + do_push_d;
	wire [ADDR_WIDTH:0] rd_ptr_eff = rd_ptr + do_pop;
	wire full_after = (wr_ptr_eff[ADDR_WIDTH] != rd_ptr_eff[ADDR_WIDTH]) &&
	                 (wr_ptr_eff[ADDR_WIDTH-1:0] == rd_ptr_eff[ADDR_WIDTH-1:0]);

	// The request uses the current eram_ptr so the last item will also be requested.
	wire do_push = (!clr_eram_ptr) && (eram_ptr < active_item_count) && (!full_after);

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			eram_ptr <= 0;
		end else if (clr_eram_ptr) begin
			eram_ptr <= 0;
		end else if (do_push) begin
			eram_ptr <= eram_ptr + 1;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			do_push_d <= 'b0;
		end else if (clr_eram_ptr) begin
			do_push_d <= 'b0;
		end else begin
			do_push_d <= do_push;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin : reset
			integer i;
			for (i = 0; i < DEPTH; i = i + 1)
				mem[i] <= 'b0;
			wr_ptr   <= 'b0;
			rd_ptr   <= 'b0;
		end else begin
			if(do_push_d) begin
				mem[wr_addr] <= din_conv;
				wr_ptr      <= wr_ptr + 1'b1;
			end
			if(do_pop) begin
				rd_ptr      <= rd_ptr + 1'b1;
			end
		end
	end

endmodule
