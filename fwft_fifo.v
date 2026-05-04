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
	
	input wire [ERAM_ADDR_WIDTH-1:0] active_item_count,
	output wire [DATA_WIDTH-1:0] dout,
	input wire pop
);
	localparam DEPTH = 8;
	localparam ADDR_WIDTH = $clog2(DEPTH);

	reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	reg [ADDR_WIDTH:0] wr_ptr;
	reg [ADDR_WIDTH:0] rd_ptr;
	wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];
	wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

	wire empty = (wr_ptr == rd_ptr);
	wire full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && (wr_addr == rd_addr);

	assign dout  = mem[rd_addr];

	wire do_pop  = pop && (!empty);

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
				mem[wr_addr] <= din;
				wr_ptr      <= wr_ptr + 1'b1;
			end
			if(do_pop) begin
				rd_ptr      <= rd_ptr + 1'b1;
			end
		end
	end

endmodule
