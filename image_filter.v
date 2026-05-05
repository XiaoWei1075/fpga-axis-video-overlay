`timescale 1 ns / 1 ns

module image_filter #
(
	// Users to add parameters here
	parameter integer ERAM_ADDR_WIDTH = 13,

	// User parameters ends

	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH	= 32,
	parameter integer C_S00_AXI_ADDR_WIDTH	= 33,

	// Parameters of Axi Stream Bus Interface
	parameter integer C_AXIS_TDATA_WIDTH	= 24,

	// Parameters of Image Filter
	parameter integer FRAME_WIDTH = 256,
	parameter integer FRAME_HEIGHT = 256
)
(
	// Users to add ports here

	// User ports ends

	// Ports of Axi Slave Bus Interface S00_AXI
	input wire  s00_axi_aclk,
	input wire  s00_axi_aresetn,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
	input wire [2 : 0] s00_axi_awprot,
	input wire  s00_axi_awvalid,
	output wire  s00_axi_awready,
	input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
	input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
	input wire  s00_axi_wvalid,
	output wire  s00_axi_wready,
	output wire [1 : 0] s00_axi_bresp,
	output wire  s00_axi_bvalid,
	input wire  s00_axi_bready,
	input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
	input wire [2 : 0] s00_axi_arprot,
	input wire  s00_axi_arvalid,
	output wire  s00_axi_arready,
	output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
	output wire [1 : 0] s00_axi_rresp,
	output wire  s00_axi_rvalid,
	input wire  s00_axi_rready,

	// Ports of Axi Stream Bus Clock and Reset
	input wire  axis_aclk,
	input wire  axis_aresetn,

	// Ports of Axi Slave Bus Interface S00_AXIS
	output wire  s00_axis_tready,
	input wire [C_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
	input wire [(C_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
	input wire  s00_axis_tlast,
	input wire  s00_axis_tvalid,
	input wire s00_axis_tuser,

	// Ports of Axi Master Bus Interface M00_AXIS
	output wire  m00_axis_tvalid,
	output wire [C_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
	output wire [(C_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
	output wire  m00_axis_tlast,
	input wire  m00_axis_tready,
	output wire m00_axis_tuser
);

	localparam integer ERAM_DATA_WIDTH = 64;
	localparam integer COUNTER_WIDTH = 24;
	localparam [COUNTER_WIDTH-1:0] FRAME_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;


	reg  [COUNTER_WIDTH-1:0] pixel_cnt;
	wire [COUNTER_WIDTH-1:0] pixel_cnt_plus1 = pixel_cnt + 1;
	wire [ERAM_ADDR_WIDTH-1:0] eram_ptr;
	wire [ERAM_DATA_WIDTH-1:0] eram_dout;
	wire [C_S00_AXI_DATA_WIDTH-1:0] pixel_format;
	wire [ERAM_ADDR_WIDTH-1:0] item_count;
	reg  [ERAM_ADDR_WIDTH-1:0] active_item_count;

// Instantiation of Axi Bus Interface S00_AXI
image_filter_slave_lite_v1_0_S00_AXI # ( 
	.ERAM_DATA_WIDTH(ERAM_DATA_WIDTH),
	.ERAM_ADDR_WIDTH(ERAM_ADDR_WIDTH),
	.COUNTER_WIDTH(COUNTER_WIDTH),
	.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
	.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
	.FRAME_WIDTH(FRAME_WIDTH),
	.FRAME_HEIGHT(FRAME_HEIGHT)
) image_filter_slave_lite_v1_0_S00_AXI_inst (
	.axis_aclk(axis_aclk),
	.axis_aresetn(axis_aresetn),
	.eram_read_ptr(eram_ptr),
	.pixel_offset(pixel_cnt),
	.active_item_count(active_item_count),
	.eram_dout(eram_dout),
	.pixel_format_out(pixel_format),
	.item_count_out(item_count),
	.S_AXI_ACLK(s00_axi_aclk),
	.S_AXI_ARESETN(s00_axi_aresetn),
	.S_AXI_AWADDR(s00_axi_awaddr),
	.S_AXI_AWPROT(s00_axi_awprot),
	.S_AXI_AWVALID(s00_axi_awvalid),
	.S_AXI_AWREADY(s00_axi_awready),
	.S_AXI_WDATA(s00_axi_wdata),
	.S_AXI_WSTRB(s00_axi_wstrb),
	.S_AXI_WVALID(s00_axi_wvalid),
	.S_AXI_WREADY(s00_axi_wready),
	.S_AXI_BRESP(s00_axi_bresp),
	.S_AXI_BVALID(s00_axi_bvalid),
	.S_AXI_BREADY(s00_axi_bready),
	.S_AXI_ARADDR(s00_axi_araddr),
	.S_AXI_ARPROT(s00_axi_arprot),
	.S_AXI_ARVALID(s00_axi_arvalid),
	.S_AXI_ARREADY(s00_axi_arready),
	.S_AXI_RDATA(s00_axi_rdata),
	.S_AXI_RRESP(s00_axi_rresp),
	.S_AXI_RVALID(s00_axi_rvalid),
	.S_AXI_RREADY(s00_axi_rready)
);

// Add user logic here

	reg axis_pipe_tvalid;
	reg [C_AXIS_TDATA_WIDTH-1:0] axis_pipe_tdata;
	reg [(C_AXIS_TDATA_WIDTH/8)-1:0] axis_pipe_tstrb;
	reg axis_pipe_tlast;
	reg axis_pipe_tuser;
	wire axis_pipe_ready = ~axis_pipe_tvalid || m00_axis_tready;

	wire axis_fire_in = s00_axis_tvalid && axis_pipe_ready;

	always @(posedge axis_aclk or negedge axis_aresetn) begin
		if (!axis_aresetn) begin
			pixel_cnt <= FRAME_PIXELS - 1;
		end else if (axis_fire_in) begin
			if (s00_axis_tuser) begin
				pixel_cnt <= 1;	// The next pixel count
			end else if (pixel_cnt == FRAME_PIXELS - 1) begin
				pixel_cnt <= 0;	// The next pixel of the end of the frame is the first pixel of the next frame
			end else begin
				pixel_cnt <= pixel_cnt_plus1;
			end
		end
	end

	wire [ERAM_DATA_WIDTH-1:0] item;
	wire [COUNTER_WIDTH-1:0] item_offset  = item[63:40];
	wire [15:0] item_runlen  = item[39:24];
	wire [23:0] item_RGB     = item[23:0];

	// alpha is selected by pixel_format[18:16]
	// 000 -> 0, 001 -> 1/4, 010 -> 1/2, 011 -> 3/4, others -> 1
	// src is the original input pixel and dst is the overlay color
	wire [2:0] alpha_sel = pixel_format[18:16];

	function [7:0] blend8;
		input [7:0] src;
		input [7:0] dst;
		input [2:0] sel;
		reg [9:0] s1;
		reg [9:0] s2;
		reg [9:0] d1;
		reg [9:0] d2;
		begin
			s1 = {2'b0, src} >> 1;	// 1/2 of src
			s2 = {2'b0, src} >> 2;	// 1/4 of src
			d1 = {2'b0, dst} >> 1;	// 1/2 of dst
			d2 = {2'b0, dst} >> 2;	// 1/4 of dst
			case (sel)
				3'b000: blend8 = dst;	// 0% src, 100% dst
				3'b001: blend8 = s2 + d1 + d2;	// 1/4 src, 3/4 dst
				3'b010: blend8 = s1 + d1;	// 1/2 src, 1/2 dst
				3'b011: blend8 = s1 + s2 + d2;	// 3/4 src, 1/4 dst
				default: blend8 = src;	// 100% src, 0% dst
			endcase
		end
	endfunction

	wire [COUNTER_WIDTH-1:0] item_end_offset = item_offset + item_runlen;

	wire match = (pixel_cnt >= item_offset) && (pixel_cnt < item_end_offset);

	always @(posedge axis_aclk or negedge axis_aresetn) begin
		if (!axis_aresetn)
			active_item_count <= 0;
		else if (pixel_cnt == FRAME_PIXELS - 1)
			active_item_count <= item_count;
	end

	fwft_fifo #(
		.DATA_WIDTH(ERAM_DATA_WIDTH),
		.ERAM_ADDR_WIDTH(ERAM_ADDR_WIDTH)
	) prefetch (
		.clk(axis_aclk),
		.rst_n(axis_aresetn),
		.clr_eram_ptr(pixel_cnt == FRAME_PIXELS - 1),
		.din(eram_dout),
		.eram_ptr(eram_ptr),
		.pixel_format(pixel_format[1:0]),
		.active_item_count(active_item_count),
		.dout(item),
		.pop(axis_fire_in && (pixel_cnt_plus1 == item_end_offset))
	);

	wire [7:0] blend_r = blend8(s00_axis_tdata[23:16], item_RGB[23:16], alpha_sel);
	wire [7:0] blend_g = blend8(s00_axis_tdata[15:8],  item_RGB[15:8],  alpha_sel);
	wire [7:0] blend_b = blend8(s00_axis_tdata[7:0],   item_RGB[7:0],   alpha_sel);
	wire [C_AXIS_TDATA_WIDTH-1:0] blended_tdata = {blend_r, blend_g, blend_b};

	wire [C_AXIS_TDATA_WIDTH-1:0] filtered_tdata = match ? blended_tdata : s00_axis_tdata;

	always @(posedge axis_aclk or negedge axis_aresetn) begin
		if (!axis_aresetn) begin
			axis_pipe_tvalid <= 1'b0;
			axis_pipe_tdata <= {C_AXIS_TDATA_WIDTH{1'b0}};
			axis_pipe_tstrb <= {(C_AXIS_TDATA_WIDTH/8){1'b0}};
			axis_pipe_tlast <= 1'b0;
			axis_pipe_tuser <= 1'b0;
		end else if (axis_pipe_ready) begin
			axis_pipe_tvalid <= s00_axis_tvalid;
			axis_pipe_tdata <= filtered_tdata;
			axis_pipe_tstrb <= s00_axis_tstrb;
			axis_pipe_tlast <= s00_axis_tlast;
			axis_pipe_tuser <= s00_axis_tuser;
		end
	end

	assign m00_axis_tvalid = axis_pipe_tvalid;
	assign s00_axis_tready = axis_pipe_ready;
	assign m00_axis_tlast  = axis_pipe_tlast;
	assign m00_axis_tuser  = axis_pipe_tuser;
	assign m00_axis_tstrb  = axis_pipe_tstrb;
	assign m00_axis_tdata  = axis_pipe_tdata;
// User logic ends

endmodule
