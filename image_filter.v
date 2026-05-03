
`timescale 1 ns / 1 ps

module image_filter #
(
	// Users to add parameters here

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

	localparam [23:0] FRAME_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;

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
				default: to_rgb888 = pixel_in;	// default to RGB888
			endcase
		end
	endfunction

	reg [23:0] pixel_cnt;
	wire [23:0] pixel_cnt_plus1 = pixel_cnt + 1;
	reg [12:0] eram_ptr;
	wire [12:0] eram_ptr_plus1 = eram_ptr + 1;
	wire [63:0] eram_dout;
	wire [C_S00_AXI_DATA_WIDTH-1:0] pixel_format;
	wire [12:0] item_count;
	reg  [12:0] active_item_count;

// Instantiation of Axi Bus Interface S00_AXI
image_filter_slave_lite_v1_0_S00_AXI # ( 
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

	always @(posedge axis_aclk or negedge axis_aresetn) begin
		if (!axis_aresetn) begin
			pixel_cnt <= FRAME_PIXELS - 1;
		end else if (s00_axis_tvalid && m00_axis_tready) begin
			if (s00_axis_tuser) begin
				pixel_cnt <= 1;	// The next pixel count
			end else if (pixel_cnt == FRAME_PIXELS - 1) begin
				pixel_cnt <= 0;	// The next pixel of the end of the frame is the first pixel of the next frame
			end else begin
				pixel_cnt <= pixel_cnt_plus1;
			end
		end
	end

	wire [63:0] item = eram_dout;
	wire [23:0] item_offset  = item[63:40];
	wire [15:0] item_runlen  = item[39:24];
	wire [23:0] item_RGB     = item[23:0];

	wire [23:0] item_end_offset = item_offset + item_runlen;

	wire [23:0] item_rgb888 = to_rgb888(item_RGB, pixel_format[1:0]);

	always @(posedge axis_aclk or negedge axis_aresetn) begin
		if (!axis_aresetn)
			active_item_count <= 0;
		else if (pixel_cnt == FRAME_PIXELS - 1)
			active_item_count <= item_count;
	end

	always @(posedge axis_aclk or negedge axis_aresetn) begin
		if (!axis_aresetn) begin
			eram_ptr <= 0;
		end else if (s00_axis_tvalid && m00_axis_tready) begin
			if (pixel_cnt == FRAME_PIXELS - 1) begin
				eram_ptr <= 0;
			end else if (eram_ptr_plus1 < active_item_count && pixel_cnt_plus1 == item_end_offset) begin
				eram_ptr <= eram_ptr_plus1;	// The next item
			end else if (s00_axis_tuser) begin	// The statement must be after the check of the next item
				eram_ptr <= 0;	// Reset to the first item
			end
		end
	end

	wire match = (pixel_cnt >= item_offset) && (pixel_cnt < item_end_offset);

	assign m00_axis_tvalid = s00_axis_tvalid;
	assign s00_axis_tready = m00_axis_tready;
	assign m00_axis_tlast  = s00_axis_tlast;
	assign m00_axis_tuser  = s00_axis_tuser;
	assign m00_axis_tstrb  = s00_axis_tstrb;
	assign m00_axis_tdata  = match ? item_rgb888 : s00_axis_tdata;
// User logic ends

endmodule
