
`timescale 1 ns / 1 ps

module image_filter_slave_lite_v1_0_S00_AXI #
(
	// Users to add parameters here
	parameter integer ERAM_DATA_WIDTH = 64,
	parameter integer ERAM_ADDR_WIDTH = 13,
	parameter integer COUNTER_WIDTH = 24,
	// User parameters ends
	// Do not modify the parameters beyond this line

	// Width of S_AXI data bus
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	// Width of S_AXI address bus
	parameter integer C_S_AXI_ADDR_WIDTH	= 5,

	// Parameters of Image Filter
	parameter integer FRAME_WIDTH = 1920,
	parameter integer FRAME_HEIGHT = 1080
)
(
	// Users to add ports here
	input wire  axis_aclk,
	input wire  axis_aresetn,
	input wire  [ERAM_ADDR_WIDTH-1:0] eram_read_ptr,
	input wire  [COUNTER_WIDTH-1:0]	pixel_offset,
	input wire  [ERAM_ADDR_WIDTH-1:0] active_item_count,
	output wire [ERAM_DATA_WIDTH-1:0] eram_dout,
	output wire [C_S_AXI_DATA_WIDTH-1:0] pixel_format_out,
	output wire [ERAM_ADDR_WIDTH-1:0] item_count_out,
	// User ports ends
	// Do not modify the ports beyond this line

	// Global Clock Signal
	input wire  S_AXI_ACLK,
	// Global Reset Signal. This Signal is Active LOW
	input wire  S_AXI_ARESETN,
	// Write address (issued by master, acceped by Slave)
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
	// Write channel Protection type. This signal indicates the
		// privilege and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
	input wire [2 : 0] S_AXI_AWPROT,
	// Write address valid. This signal indicates that the master signaling
		// valid write address and control information.
	input wire  S_AXI_AWVALID,
	// Write address ready. This signal indicates that the slave is ready
		// to accept an address and associated control signals.
	output wire  S_AXI_AWREADY,
	// Write data (issued by master, acceped by Slave) 
	input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
	// Write strobes. This signal indicates which byte lanes hold
		// valid data. There is one write strobe bit for each eight
		// bits of the write data bus.    
	input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
	// Write valid. This signal indicates that valid write
		// data and strobes are available.
	input wire  S_AXI_WVALID,
	// Write ready. This signal indicates that the slave
		// can accept the write data.
	output wire  S_AXI_WREADY,
	// Write response. This signal indicates the status
		// of the write transaction.
	output wire [1 : 0] S_AXI_BRESP,
	// Write response valid. This signal indicates that the channel
		// is signaling a valid write response.
	output wire  S_AXI_BVALID,
	// Response ready. This signal indicates that the master
		// can accept a write response.
	input wire  S_AXI_BREADY,
	// Read address (issued by master, acceped by Slave)
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
	// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether the
		// transaction is a data access or an instruction access.
	input wire [2 : 0] S_AXI_ARPROT,
	// Read address valid. This signal indicates that the channel
		// is signaling valid read address and control information.
	input wire  S_AXI_ARVALID,
	// Read address ready. This signal indicates that the slave is
		// ready to accept an address and associated control signals.
	output wire  S_AXI_ARREADY,
	// Read data (issued by slave)
	output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
	// Read response. This signal indicates the status of the
		// read transfer.
	output wire [1 : 0] S_AXI_RRESP,
	// Read valid. This signal indicates that the channel is
		// signaling the required read data.
	output wire  S_AXI_RVALID,
	// Read ready. This signal indicates that the master can
		// accept the read data and response information.
	input wire  S_AXI_RREADY
);

// AXI4LITE signals
reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
reg  	axi_awready;
reg  	axi_wready;
reg [1 : 0] 	axi_bresp;
reg  	axi_bvalid;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
reg  	axi_arready;
reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
reg [1 : 0] 	axi_rresp;
reg  	axi_rvalid;

// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 13;

localparam integer ERAM_DEPTH = 1'b1 << ERAM_ADDR_WIDTH;

localparam [COUNTER_WIDTH-1:0] FRAME_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;

//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers
reg  [C_S_AXI_DATA_WIDTH-1:0]	enable_filter;
reg  [C_S_AXI_DATA_WIDTH-1:0]	commit_bank;
wire 							item_overflow;
reg  [ERAM_ADDR_WIDTH-1:0]		item_count;
reg  [C_S_AXI_DATA_WIDTH-1:0]	pixel_format;

integer	 byte_index;

// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP	= axi_bresp;
assign S_AXI_BVALID	= axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RDATA	= axi_rdata;
assign S_AXI_RRESP	= axi_rresp;
assign S_AXI_RVALID	= axi_rvalid;
	//state machine varibles 
	reg [1:0] state_write;
	reg [1:0] state_read;
	//State machine local parameters
	localparam Idle = 2'b00,Raddr = 2'b10,Rdata = 2'b11 ,Waddr = 2'b10,Wdata = 2'b11;
// Implement Write state machine
// Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
always @(posedge S_AXI_ACLK)                                 
begin                                 
	if (S_AXI_ARESETN == 1'b0)                                 
	begin                                 
		axi_awready <= 0;                                 
		axi_wready <= 0;                                 
		axi_bvalid <= 0;                                 
		axi_bresp <= 0;                                 
		axi_awaddr <= 0;                                 
		state_write <= Idle;                                 
	end                                 
	else                                  
	begin                                 
		case(state_write)                                 
		Idle:                                      
			begin                                 
			if(S_AXI_ARESETN == 1'b1)                                  
				begin                                 
				axi_awready <= 1'b1;                                 
				axi_wready <= 1'b1;                                 
				state_write <= Waddr;                                 
				end                                 
			else state_write <= state_write;                                 
			end                                 
		Waddr:        //At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state                                 
			begin                                 
			if (S_AXI_AWVALID && S_AXI_AWREADY)                                 
				begin                                 
				axi_awaddr <= S_AXI_AWADDR;                                 
				if(S_AXI_WVALID)                                  
					begin                                   
					axi_awready <= 1'b1;                                 
					state_write <= Waddr;                                 
					axi_bvalid <= 1'b1;                                 
					end                                 
				else                                  
					begin                                 
					axi_awready <= 1'b0;                                 
					state_write <= Wdata;                                 
					if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
					end                                 
				end                                 
			else                                  
				begin                                 
				state_write <= state_write;                                 
				if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
				end                                 
			end                                 
		Wdata:        //At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length                                 
			begin                                 
			if (S_AXI_WVALID)                                 
				begin                                 
				state_write <= Waddr;                                 
				axi_bvalid <= 1'b1;                                 
				axi_awready <= 1'b1;                                 
				end                                 
			else                                  
				begin                                 
				state_write <= state_write;                                 
				if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;                                 
				end                                              
			end                                 
		endcase                                 
	end                                 
end                                 

// Implement memory mapped register select and write logic generation
// The write data is accepted and written to memory mapped registers when
// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
// select byte enables of slave registers while writing.
// These registers are cleared when reset (active low) is applied.
// Slave register write enable is asserted when valid address and data are available
// and the slave is ready to accept the write address and write data.

wire [C_S_AXI_ADDR_WIDTH-1 : 0] slave_axi_awaddr = (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
reg  [ERAM_DATA_WIDTH-1 : 0]	item_input;
reg  [ERAM_DATA_WIDTH-1 : 0]	item_stored, item_stored_next;
reg  [ERAM_ADDR_WIDTH-1 : 0]	eram_write_ptr;
reg merge_check; // one complete item_input
reg clear_commit; // eram bank has been switched once clear_commit is set
reg eram_write_enable;

reg commit_bank_delay;
always @( posedge S_AXI_ACLK )
begin
	if ( S_AXI_ARESETN == 1'b0 )
		commit_bank_delay <= 0;
	else
		commit_bank_delay <= commit_bank ? 1 : 0;
end

wire commit_bank_rising_edge = (commit_bank ? 1 : 0) & ~commit_bank_delay;

reg [1:0] commit_bank_rising_edge_d;
always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		commit_bank_rising_edge_d <= 2'b0;
	end else begin
		commit_bank_rising_edge_d <= {commit_bank_rising_edge_d[0], commit_bank_rising_edge};
	end
end

always @( posedge S_AXI_ACLK )
begin
	if ( S_AXI_ARESETN == 1'b0 )
		item_count <= 0;
	else if (commit_bank_rising_edge_d[1])
		item_count <= eram_write_ptr;
end

always @( posedge S_AXI_ACLK )
begin
	if (clear_commit) begin
		eram_write_ptr <= 0;
	end
	if (eram_write_enable) begin
		item_stored <= item_stored_next;
		eram_write_enable <= 0;
		eram_write_ptr <= eram_write_ptr + 1;
	end
	if ( S_AXI_ARESETN == 1'b0 )
	begin
		item_stored <= 0;
		item_stored_next <= 0;
		eram_write_enable <= 0;
		eram_write_ptr <= 0;
	end
	else begin
		if (merge_check) begin
			if (item_stored == 0)
				item_stored <= item_input;
			else if (item_stored[23:0] == item_input[23:0] && item_stored[63:40] + item_stored[39:24] == item_input[63:40])
				item_stored[39:24] <= item_stored[39:24] + item_input[39:24];	// merge the two halves of the item
			else begin
				eram_write_enable <= 1;
				item_stored_next <= item_input;	// the new item
			end
		end else if (commit_bank_rising_edge && !item_overflow && (item_stored != 0)) begin
			eram_write_enable <= 1;	// flush item_stored into ERAM
			item_stored_next <= 0;
		end
	end
end

always @( posedge S_AXI_ACLK )
begin
	merge_check <= 0;
	if (clear_commit)
		commit_bank <= 0;
	if ( S_AXI_ARESETN == 1'b0 )
	begin
		enable_filter <= 0;
		commit_bank <= 0;
		pixel_format <= 0;
		item_input <= 0;
	end 
	else begin
	if (S_AXI_WVALID)
		begin
		case (slave_axi_awaddr)
			'h0:
			for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
				if ( S_AXI_WSTRB[byte_index] == 1 ) begin
				// Respective byte enables are asserted as per write strobes 
				// Slave register 0
				enable_filter[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
				end  
			'h1: begin
				// Slave register 1 is read only
			end
			'h2: begin
				// Slave register 2 is read only
			end
			'h3:
			for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
				if ( S_AXI_WSTRB[byte_index] == 1 ) begin
				// Respective byte enables are asserted as per write strobes 
				// Slave register 3
				commit_bank[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
				end  
			'h4: begin
				// Slave register 4 is modified by internal logic
			end
			'h5: begin
				// Slave register 5 is modified by internal logic
			end
			'h6: begin
				// Slave register 6 is modified by internal logic
			end
			'h7:
			for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
				if ( S_AXI_WSTRB[byte_index] == 1 ) begin
				// Respective byte enables are asserted as per write strobes 
				// Slave register 7
				pixel_format[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
				end  
			default : 
				if (!item_overflow && !commit_bank) begin
					if(slave_axi_awaddr & 1'b1 == 1'b1) begin // odd address, the high 32 bits of the 64-bit item
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						// Respective byte enables are asserted as per write strobes 
						// ERAM Data Input
						item_input[(32 + byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
						end  
					merge_check <= 1;
					end else begin // even address, the low 32 bits of the 64-bit item
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
						// Respective byte enables are asserted as per write strobes 
						// ERAM Data Input
						item_input[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
						end  
					end
				end
		endcase
		end
	end
end    

// Implement read state machine
always @(posedge S_AXI_ACLK)                                       
begin                                       
	if (S_AXI_ARESETN == 1'b0)                                       
	begin                                       
		//asserting initial values to all 0's during reset                                       
		axi_arready <= 1'b0;                                       
		axi_rvalid <= 1'b0;                                       
		axi_rresp <= 1'b0;                                       
		state_read <= Idle;                                       
	end                                       
	else                                       
	begin                                       
		case(state_read)                                       
		Idle:     //Initial state inidicating reset is done and ready to receive read/write transactions                                       
			begin                                                
			if (S_AXI_ARESETN == 1'b1)                                        
				begin                                       
				state_read <= Raddr;                                       
				axi_arready <= 1'b1;                                       
				end                                       
			else state_read <= state_read;                                       
			end                                       
		Raddr:        //At this state, slave is ready to receive address along with corresponding control signals                                       
			begin                                       
			if (S_AXI_ARVALID && S_AXI_ARREADY)                                       
				begin                                       
				state_read <= Rdata;                                       
				axi_araddr <= S_AXI_ARADDR;                                       
				axi_rvalid <= 1'b1;                                       
				axi_arready <= 1'b0;                                       
				end                                       
			else state_read <= state_read;                                       
			end                                       
		Rdata:        //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length                                       
			begin                                           
			if (S_AXI_RVALID && S_AXI_RREADY)                                       
				begin                                       
				axi_rvalid <= 1'b0;                                       
				axi_arready <= 1'b1;                                       
				state_read <= Raddr;                                       
				end                                       
			else state_read <= state_read;                                       
			end                                       
		endcase                                       
	end                                       
end                                         
// Implement memory mapped register select and read logic generation
always @(*) begin
	case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
	'h0: axi_rdata = enable_filter;
	'h1: axi_rdata = {{(C_S_AXI_DATA_WIDTH-COUNTER_WIDTH){1'b0}}, FRAME_PIXELS};
	'h2: axi_rdata = {{(C_S_AXI_DATA_WIDTH-COUNTER_WIDTH){1'b0}}, pixel_offset};
	'h3: axi_rdata = commit_bank;
	'h4: axi_rdata = {{(C_S_AXI_DATA_WIDTH-1){1'b0}}, item_overflow};
	'h5: axi_rdata = {{(C_S_AXI_DATA_WIDTH-ERAM_ADDR_WIDTH){1'b0}}, active_item_count};
	'h6: axi_rdata = {{(C_S_AXI_DATA_WIDTH-ERAM_ADDR_WIDTH){1'b0}}, eram_write_ptr};	// item_queued_count
	'h7: axi_rdata = pixel_format;
	default: axi_rdata = {C_S_AXI_DATA_WIDTH{1'b0}};
	endcase
end
// Add user logic here

assign item_overflow = eram_write_ptr >= ERAM_DEPTH ? 1 : 0;

// sync enable_filter to axis_aclk domain
reg enable_filter_sync[0:1];
always @(posedge axis_aclk or negedge axis_aresetn) begin
	if (!axis_aresetn) begin
		enable_filter_sync[0] <= 0;
		enable_filter_sync[1] <= 0;
	end else begin
		enable_filter_sync[0] <= enable_filter ? 1 : 0;
		enable_filter_sync[1] <= enable_filter_sync[0];
	end
end

// sync commit_bank to axis_aclk domain for the control of the read bank switching
reg commit_bank_sync[0:1];
always @(posedge axis_aclk or negedge axis_aresetn) begin
	if (!axis_aresetn) begin
		commit_bank_sync[0] <= 0;
		commit_bank_sync[1] <= 0;
	end else begin
		commit_bank_sync[0] <= commit_bank ? 1 : 0;
		commit_bank_sync[1] <= commit_bank_sync[0];
	end
end

reg [ERAM_ADDR_WIDTH-1:0] item_count_sync[0:1];
always @(posedge axis_aclk or negedge axis_aresetn) begin
	if (!axis_aresetn) begin
		item_count_sync[0] <= 0;
		item_count_sync[1] <= 0;
	end else begin
		item_count_sync[0] <= item_count;
		item_count_sync[1] <= item_count_sync[0];
	end
end

reg hi_axis;	// axis_aclk domain
reg hi_axis_toggled;

// switch the read bank
always @(posedge axis_aclk or negedge axis_aresetn) begin
	if (!axis_aresetn) begin
		hi_axis <= 0;
		hi_axis_toggled <= 0;
	end
	else if (enable_filter_sync[1] && commit_bank_sync[1]) begin
		if (pixel_offset == FRAME_PIXELS - 1 && hi_axis_toggled == 1'b0) begin
			hi_axis <= ~hi_axis;
			hi_axis_toggled <= 1;
		end
	end
	else if (pixel_offset == 0) begin
		hi_axis_toggled <= 0;
	end
end

reg [2:0] hi_s_axi_sync; // 3 stages for edge detection
always @(posedge S_AXI_ACLK) begin
	if (S_AXI_ARESETN == 1'b0)
		hi_s_axi_sync <= 3'b0;
	else begin
		hi_s_axi_sync <= {hi_s_axi_sync[1:0], hi_axis};
	end
end
wire hi_s_axi = hi_s_axi_sync[1];	// S_AXI_ACLK domain
wire hi_s_axi_toggled = (hi_s_axi_sync[1] ^ hi_s_axi_sync[2]);

always @(posedge S_AXI_ACLK) begin
	clear_commit <= 0;
	if (hi_s_axi_toggled) begin
		clear_commit <= 1; // trigger the clear of the commit bank and the reset of the write pointer in the next cycle
	end
end

blk_mem_gen_0 pixel_items (
	.clka(S_AXI_ACLK),
	.ena(enable_filter ? 1 : 0),
	.wea(eram_write_enable),
	.addra({~hi_s_axi, eram_write_ptr}), // ~hi_s_axi indicates the write bank
	.dina(item_stored),
	.clkb(axis_aclk),
	.enb(enable_filter_sync[1]),
	.addrb({hi_axis, eram_read_ptr}),    // hi_axis indicates the read bank
	.doutb(eram_dout)
);

assign pixel_format_out = pixel_format;
assign item_count_out = item_count_sync[1];

// User logic ends

endmodule
