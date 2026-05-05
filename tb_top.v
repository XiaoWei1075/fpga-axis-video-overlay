`timescale 1ns / 1ns

module tb_top;

    localparam CLK_LITE_PERIOD = 7.518; // ~133MHz
    localparam CLK_STRM_PERIOD = 5.0;   // 200MHz
    localparam FRAME_WIDTH = 256;
    localparam FRAME_HEIGHT = 256;
    localparam NUM_FRAMES = 30;

    reg          s00_axi_aclk = 0;
    reg          s00_axi_aresetn = 0;
    reg          axis_aclk = 0;
    reg          axis_aresetn = 0;

    // AXI-Lite interface
    reg  [32:0]  s00_axi_awaddr = 0;
    reg  [2:0]   s00_axi_awprot = 0;
    reg          s00_axi_awvalid = 0;
    wire         s00_axi_awready;
    reg  [31:0]  s00_axi_wdata = 0;
    reg  [3:0]   s00_axi_wstrb = 4'hF;
    reg          s00_axi_wvalid = 0;
    wire         s00_axi_wready;
    wire [1:0]   s00_axi_bresp;
    wire         s00_axi_bvalid;
    reg          s00_axi_bready = 0;

    reg  [32:0]  s00_axi_araddr = 0;
    reg  [2:0]   s00_axi_arprot = 0;
    reg          s00_axi_arvalid = 0;
    wire         s00_axi_arready;
    wire [31:0]  s00_axi_rdata;
    wire [1:0]   s00_axi_rresp;
    wire         s00_axi_rvalid;
    reg          s00_axi_rready = 1;

    // AXI-Stream Slave (Input)
    reg  [23:0]  s00_axis_tdata = 0;
    reg  [2:0]   s00_axis_tstrb = 3'h7;
    reg          s00_axis_tvalid = 0;
    reg          s00_axis_tlast = 0;
    reg          s00_axis_tuser = 0;
    wire         s00_axis_tready;

    // AXI-Stream Master (Output)
    wire [23:0]  m00_axis_tdata;
    wire [2:0]   m00_axis_tstrb;
    wire         m00_axis_tvalid;
    wire         m00_axis_tlast;
    wire         m00_axis_tuser;
    reg          m00_axis_tready = 1;

    always #(CLK_LITE_PERIOD/2.0) s00_axi_aclk = ~s00_axi_aclk;
    always #(CLK_STRM_PERIOD/2.0) axis_aclk = ~axis_aclk;

    image_filter #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(33),
        .C_AXIS_TDATA_WIDTH(24)
    ) dut (
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready),

        .axis_aclk(axis_aclk),
        .axis_aresetn(axis_aresetn),

        .s00_axis_tready(s00_axis_tready),
        .s00_axis_tdata(s00_axis_tdata),
        .s00_axis_tstrb(s00_axis_tstrb),
        .s00_axis_tlast(s00_axis_tlast),
        .s00_axis_tvalid(s00_axis_tvalid),
        .s00_axis_tuser(s00_axis_tuser),

        .m00_axis_tvalid(m00_axis_tvalid),
        .m00_axis_tdata(m00_axis_tdata),
        .m00_axis_tstrb(m00_axis_tstrb),
        .m00_axis_tlast(m00_axis_tlast),
        .m00_axis_tready(m00_axis_tready),
        .m00_axis_tuser(m00_axis_tuser)
    );

    // AXI-Lite Write Task
    task axi_write;
        input [32:0] addr;
        input [31:0] data;
        begin
            @(posedge s00_axi_aclk);
            s00_axi_awaddr <= addr;
            s00_axi_wdata  <= data;
            s00_axi_awvalid <= 1'b1;
            s00_axi_wvalid  <= 1'b1;
            s00_axi_bready  <= 1'b1;
            
            wait(s00_axi_awready && s00_axi_wready);
            @(posedge s00_axi_aclk);
            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid  <= 1'b0;
            
            wait(s00_axi_bvalid);
            @(posedge s00_axi_aclk);
            s00_axi_bready <= 1'b0;
        end
    endtask

    task axi_read;
        input [32:0] addr;
        output [31:0] data;
        begin
            @(posedge s00_axi_aclk);
            s00_axi_araddr  <= addr;
            s00_axi_arvalid <= 1'b1;

            wait(s00_axi_arready);
            @(posedge s00_axi_aclk);
            s00_axi_arvalid <= 1'b0;

            wait(s00_axi_rvalid);
            @(posedge s00_axi_aclk);
            data = s00_axi_rdata;
        end
    endtask

    reg [31:0] reg14_value;
    task commit_and_read_counts;
        input integer frame_no;
        begin
            axi_write(33'h8040000C, 32'd1); // commit_bank = 1
            @(negedge dut.image_filter_slave_lite_v1_0_S00_AXI_inst.clear_commit);
            axi_read(33'h80400014, reg14_value);
            $display("[frame %0d] reg[0x14]=%0d", frame_no, reg14_value);
        end
    endtask

    // Write a 64-bit item to SRAM
    // Assuming even address writes low 32-bits, odd address writes high 32-bits internally
    task axi_write_item;
        input [23:0] offset;
        input [15:0] run_len;
        input [23:0] rgb;
        reg [31:0] data_l;
        reg [31:0] data_h;
        begin
            data_l = {run_len[7:0], rgb};
            data_h = {offset, run_len[15:8]};
            
            axi_write(33'h80400020, data_l); // Write lower 32 bits
            axi_write(33'h80400024, data_h); // Write upper 32 bits (triggers write to ERAM)
        end
    endtask

    task write_square;
        integer yy;
        begin
            // Top edge: y=120, x=120..135
            axi_write_item(24'd30840, 16'd16, 24'h00FF00);
            // Left and right edges: y=121..134
            for (yy = 121; yy <= 134; yy = yy + 1) begin
                axi_write_item(yy * FRAME_WIDTH + 120, 16'd1, 24'h00FF00);
                axi_write_item(yy * FRAME_WIDTH + 135, 16'd1, 24'h00FF00);
            end
            // Bottom edge: y=135, x=120..135
            axi_write_item(24'd34680, 16'd16, 24'h00FF00);
        end
    endtask

    task write_circle;
        integer cx, cy, radius, r2;
        integer dy, dx, y_pos, x_pos;
        begin
            cx = 128;
            cy = 128;
            radius = 24;
            r2 = radius * radius;
            for (dy = -radius; dy <= radius; dy = dy + 1) begin
                y_pos = cy + dy;
                if ((y_pos >= 0) && (y_pos < FRAME_HEIGHT)) begin
                    for (dx = -radius; dx <= radius; dx = dx + 1) begin
                        if ((dx * dx + dy * dy) <= r2) begin
                            x_pos = cx + dx;
                            if ((x_pos >= 0) && (x_pos < FRAME_WIDTH)) begin
                                axi_write_item(y_pos * FRAME_WIDTH + x_pos, 16'd1, 24'hFF0000);
                            end
                        end
                    end
                end
            end
        end
    endtask

    // 六芒星：两个重叠等边三角形，390+ 个像素点，run_len=1
    // 由 gen_hexagram.py 使用 Bresenham 算法预计算
    task write_hexagram;
        begin
            // y=166
            axi_write_item(24'd42624, 16'd1, 24'hFFFFFF);
            // y=167
            axi_write_item(24'd42879, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd42881, 16'd1, 24'hFFFFFF);
            // y=168
            axi_write_item(24'd43135, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd43137, 16'd1, 24'hFFFFFF);
            // y=169
            axi_write_item(24'd43390, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd43394, 16'd1, 24'hFFFFFF);
            // y=170
            axi_write_item(24'd43646, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd43650, 16'd1, 24'hFFFFFF);
            // y=171
            axi_write_item(24'd43901, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd43907, 16'd1, 24'hFFFFFF);
            // y=172
            axi_write_item(24'd44156, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd44163, 16'd1, 24'hFFFFFF);
            // y=173
            axi_write_item(24'd44412, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd44420, 16'd1, 24'hFFFFFF);
            // y=174
            axi_write_item(24'd44667, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd44677, 16'd1, 24'hFFFFFF);
            // y=175
            axi_write_item(24'd44923, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd44933, 16'd1, 24'hFFFFFF);
            // y=176
            axi_write_item(24'd45178, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd45190, 16'd1, 24'hFFFFFF);
            // y=177
            axi_write_item(24'd45434, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd45446, 16'd1, 24'hFFFFFF);
            // y=178
            axi_write_item(24'd45689, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd45703, 16'd1, 24'hFFFFFF);
            // y=179
            axi_write_item(24'd45944, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd45959, 16'd1, 24'hFFFFFF);
            // y=180
            axi_write_item(24'd46200, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd46216, 16'd1, 24'hFFFFFF);
            // y=181
            axi_write_item(24'd46455, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd46473, 16'd1, 24'hFFFFFF);
            // y=182
            axi_write_item(24'd46711, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd46729, 16'd1, 24'hFFFFFF);
            // y=183
            axi_write_item(24'd46966, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd46986, 16'd1, 24'hFFFFFF);
            // y=184
            axi_write_item(24'd47221, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47242, 16'd1, 24'hFFFFFF);
            // y=185
            axi_write_item(24'd47477, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47499, 16'd1, 24'hFFFFFF);
            // y=186
            axi_write_item(24'd47732, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47755, 16'd1, 24'hFFFFFF);
            // y=187: 三角形横向交叉段 (x=107..148)
            axi_write_item(24'd47963, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47964, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47965, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47966, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47967, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47968, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47969, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47970, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47971, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47972, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47973, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47974, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47975, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47976, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47977, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47978, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47979, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47980, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47981, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47982, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47983, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47984, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47985, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47986, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47987, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47988, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47989, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47990, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47991, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47992, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47993, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47994, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47995, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47996, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47997, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47998, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd47999, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48000, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48001, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48002, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48003, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48004, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48005, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48006, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48007, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48008, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48009, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48010, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48011, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48012, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48013, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48014, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48015, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48016, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48017, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48018, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48019, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48020, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48021, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48022, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48023, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48024, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48025, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48026, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48027, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48028, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48029, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48030, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48031, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48032, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48033, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48034, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48035, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48036, 16'd1, 24'hFFFFFF);
            // y=188
            axi_write_item(24'd48220, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48243, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48269, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48291, 16'd1, 24'hFFFFFF);
            // y=189
            axi_write_item(24'd48476, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48498, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48525, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48547, 16'd1, 24'hFFFFFF);
            // y=190
            axi_write_item(24'd48733, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48754, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48782, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd48802, 16'd1, 24'hFFFFFF);
            // y=191
            axi_write_item(24'd48989, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49009, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49038, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49058, 16'd1, 24'hFFFFFF);
            // y=192
            axi_write_item(24'd49246, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49265, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49295, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49313, 16'd1, 24'hFFFFFF);
            // y=193
            axi_write_item(24'd49503, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49520, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49551, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49569, 16'd1, 24'hFFFFFF);
            // y=194
            axi_write_item(24'd49759, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49776, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49808, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd49824, 16'd1, 24'hFFFFFF);
            // y=195
            axi_write_item(24'd50016, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50031, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50065, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50079, 16'd1, 24'hFFFFFF);
            // y=196
            axi_write_item(24'd50272, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50286, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50321, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50335, 16'd1, 24'hFFFFFF);
            // y=197
            axi_write_item(24'd50529, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50542, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50578, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50590, 16'd1, 24'hFFFFFF);
            // y=198
            axi_write_item(24'd50785, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50797, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50834, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd50846, 16'd1, 24'hFFFFFF);
            // y=199
            axi_write_item(24'd51042, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51053, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51091, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51101, 16'd1, 24'hFFFFFF);
            // y=200
            axi_write_item(24'd51299, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51308, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51347, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51357, 16'd1, 24'hFFFFFF);
            // y=201
            axi_write_item(24'd51555, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51563, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51604, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51612, 16'd1, 24'hFFFFFF);
            // y=202
            axi_write_item(24'd51812, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51819, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51861, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd51867, 16'd1, 24'hFFFFFF);
            // y=203
            axi_write_item(24'd52068, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52074, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52117, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52123, 16'd1, 24'hFFFFFF);
            // y=204
            axi_write_item(24'd52325, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52330, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52374, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52378, 16'd1, 24'hFFFFFF);
            // y=205
            axi_write_item(24'd52582, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52585, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52630, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52634, 16'd1, 24'hFFFFFF);
            // y=206
            axi_write_item(24'd52838, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52841, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52887, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd52889, 16'd1, 24'hFFFFFF);
            // y=207
            axi_write_item(24'd53095, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53096, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53143, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53145, 16'd1, 24'hFFFFFF);
            // y=208
            axi_write_item(24'd53351, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53400, 16'd1, 24'hFFFFFF);
            // y=209
            axi_write_item(24'd53607, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53608, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53655, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53657, 16'd1, 24'hFFFFFF);
            // y=210
            axi_write_item(24'd53862, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53865, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53911, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd53913, 16'd1, 24'hFFFFFF);
            // y=211
            axi_write_item(24'd54118, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54121, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54166, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54170, 16'd1, 24'hFFFFFF);
            // y=212
            axi_write_item(24'd54373, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54378, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54422, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54426, 16'd1, 24'hFFFFFF);
            // y=213
            axi_write_item(24'd54628, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54634, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54677, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54683, 16'd1, 24'hFFFFFF);
            // y=214
            axi_write_item(24'd54884, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54891, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54933, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd54939, 16'd1, 24'hFFFFFF);
            // y=215
            axi_write_item(24'd55139, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55147, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55188, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55196, 16'd1, 24'hFFFFFF);
            // y=216
            axi_write_item(24'd55395, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55404, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55443, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55453, 16'd1, 24'hFFFFFF);
            // y=217
            axi_write_item(24'd55650, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55661, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55699, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55709, 16'd1, 24'hFFFFFF);
            // y=218
            axi_write_item(24'd55905, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55917, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55954, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd55966, 16'd1, 24'hFFFFFF);
            // y=219
            axi_write_item(24'd56161, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56174, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56210, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56222, 16'd1, 24'hFFFFFF);
            // y=220
            axi_write_item(24'd56416, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56430, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56465, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56479, 16'd1, 24'hFFFFFF);
            // y=221
            axi_write_item(24'd56672, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56687, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56721, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56735, 16'd1, 24'hFFFFFF);
            // y=222
            axi_write_item(24'd56927, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56944, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56976, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd56992, 16'd1, 24'hFFFFFF);
            // y=223
            axi_write_item(24'd57183, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57200, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57231, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57249, 16'd1, 24'hFFFFFF);
            // y=224
            axi_write_item(24'd57438, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57457, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57487, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57505, 16'd1, 24'hFFFFFF);
            // y=225
            axi_write_item(24'd57693, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57713, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57742, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57762, 16'd1, 24'hFFFFFF);
            // y=226
            axi_write_item(24'd57949, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57970, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd57998, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58018, 16'd1, 24'hFFFFFF);
            // y=227
            axi_write_item(24'd58204, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58226, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58253, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58275, 16'd1, 24'hFFFFFF);
            // y=228
            axi_write_item(24'd58460, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58483, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58509, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58531, 16'd1, 24'hFFFFFF);
            // y=229: 三角形横向交叉段 (x=91..164)
            axi_write_item(24'd58715, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58716, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58717, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58718, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58719, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58720, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58721, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58722, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58723, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58724, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58725, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58726, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58727, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58728, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58729, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58730, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58731, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58732, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58733, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58734, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58735, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58736, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58737, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58738, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58739, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58740, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58741, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58742, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58743, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58744, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58745, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58746, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58747, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58748, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58749, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58750, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58751, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58752, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58753, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58754, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58755, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58756, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58757, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58758, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58759, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58760, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58761, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58762, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58763, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58764, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58765, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58766, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58767, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58768, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58769, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58770, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58771, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58772, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58773, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58774, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58775, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58776, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58777, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58778, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58779, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58780, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58781, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58782, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58783, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58784, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58785, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58786, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58787, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd58788, 16'd1, 24'hFFFFFF);
            // y=230
            axi_write_item(24'd58996, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd59019, 16'd1, 24'hFFFFFF);
            // y=231
            axi_write_item(24'd59253, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd59275, 16'd1, 24'hFFFFFF);
            // y=232
            axi_write_item(24'd59509, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd59530, 16'd1, 24'hFFFFFF);
            // y=233
            axi_write_item(24'd59766, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd59786, 16'd1, 24'hFFFFFF);
            // y=234
            axi_write_item(24'd60023, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd60041, 16'd1, 24'hFFFFFF);
            // y=235
            axi_write_item(24'd60279, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd60297, 16'd1, 24'hFFFFFF);
            // y=236
            axi_write_item(24'd60536, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd60552, 16'd1, 24'hFFFFFF);
            // y=237
            axi_write_item(24'd60792, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd60807, 16'd1, 24'hFFFFFF);
            // y=238
            axi_write_item(24'd61049, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd61063, 16'd1, 24'hFFFFFF);
            // y=239
            axi_write_item(24'd61306, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd61318, 16'd1, 24'hFFFFFF);
            // y=240
            axi_write_item(24'd61562, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd61574, 16'd1, 24'hFFFFFF);
            // y=241
            axi_write_item(24'd61819, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd61829, 16'd1, 24'hFFFFFF);
            // y=242
            axi_write_item(24'd62075, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd62085, 16'd1, 24'hFFFFFF);
            // y=243
            axi_write_item(24'd62332, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd62340, 16'd1, 24'hFFFFFF);
            // y=244
            axi_write_item(24'd62588, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd62595, 16'd1, 24'hFFFFFF);
            // y=245
            axi_write_item(24'd62845, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd62851, 16'd1, 24'hFFFFFF);
            // y=246
            axi_write_item(24'd63102, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd63106, 16'd1, 24'hFFFFFF);
            // y=247
            axi_write_item(24'd63358, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd63362, 16'd1, 24'hFFFFFF);
            // y=248
            axi_write_item(24'd63615, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd63617, 16'd1, 24'hFFFFFF);
            // y=249
            axi_write_item(24'd63871, 16'd1, 24'hFFFFFF);
            axi_write_item(24'd63873, 16'd1, 24'hFFFFFF);
            // y=250
            axi_write_item(24'd64128, 16'd1, 24'hFFFFFF);
        end
    endtask

    // Sim variables
    integer fin, fout;
    integer r, y, x, frame_idx;
    reg [8*256-1:0] in_path;
    reg [8*256-1:0] out_path;
    reg [23:0] pixel = 24'b0;
    integer stream_frame_idx;
    reg red_pattern_written;
    reg green_pattern_written;
    event first_commit_done;

    initial begin
        s00_axi_aresetn = 0;
        axis_aresetn = 0;
        stream_frame_idx = 0;
        red_pattern_written = 1'b0;
        green_pattern_written = 1'b0;
        #100;
        s00_axi_aresetn = 1;
        axis_aresetn = 1;
        #100;

        // 1. Configure Filter
        // Register 0 (enable_filter) = 1
        axi_write(33'h80400000, 32'd1);
        // Register 7 (pixel_format) = alpha 1/4 + BGR888
        axi_write(33'h8040001C, 32'h00010001);
        // Base pattern from frame 01: hexagram (white), 1/4 alpha
        write_hexagram();
        commit_and_read_counts(1);

        // 2. Wait for clear_commit to take effect before allowing frame streaming
        //    (commit_bank is cleared by clear_commit after hi_axis toggles at frame end)
        begin : wait_clear_commit
            reg [31:0] cb_val;
            repeat (4) @(posedge s00_axi_aclk);
            axi_read(33'h8040000C, cb_val);
            while (cb_val != 0) begin
                repeat (16) @(posedge s00_axi_aclk);
                axi_read(33'h8040000C, cb_val);
            end
        end
        -> first_commit_done;
    end

    // Frame streaming
    initial begin
        wait(axis_aresetn);
        @(first_commit_done);

        for (frame_idx = 1; frame_idx <= NUM_FRAMES; frame_idx = frame_idx + 1) begin
            $sformat(in_path, "/home/xiaowei/Vivado_Projects/image_filter/InData/%02d.raw", frame_idx);
            $sformat(out_path, "/home/xiaowei/Vivado_Projects/image_filter/OutData/%02d.raw", frame_idx);

            fin = $fopen(in_path, "rb");
            if (fin == 0) begin
                $display("Could not open %0s.", in_path);
                $finish;
            end

            stream_frame_idx = frame_idx;
            fout = $fopen(out_path, "wb");
            if (fout == 0) begin
                $display("Could not open %0s.", out_path);
                $fclose(fin);
                $finish;
            end

            for (y = 0; y < FRAME_HEIGHT; y = y + 1) begin
                for (x = 0; x < FRAME_WIDTH; x = x + 1) begin
                    r = $fread(pixel, fin);
                    if (r == 0) begin
                        $display("Unexpected EOF in %0s at frame=%0d x=%0d y=%0d", in_path, frame_idx, x, y);
                        $fclose(fin);
                        $fclose(fout);
                        $finish;
                    end

                    if (y == 0 && x == 0) s00_axis_tuser <= 1;
                    else s00_axis_tuser <= 0;

                    if (x == FRAME_WIDTH - 1) s00_axis_tlast <= 1;
                    else s00_axis_tlast <= 0;

                    s00_axis_tdata <= pixel;
                    s00_axis_tvalid <= 1;

                    @(posedge axis_aclk);
                    while (!s00_axis_tready) @(posedge axis_aclk);
                    while (!(m00_axis_tvalid && m00_axis_tready)) @(posedge axis_aclk);
                    $fwrite(fout, "%c%c%c", m00_axis_tdata[23:16], m00_axis_tdata[15:8], m00_axis_tdata[7:0]);
                end
            end

            s00_axis_tvalid <= 0;
            s00_axis_tdata <= 0;
            s00_axis_tlast <= 0;
            s00_axis_tuser <= 0;
            @(posedge axis_aclk);

            $fclose(fin);
            $fclose(fout);
            $display("Frame %0d done: %0s -> %0s", frame_idx, in_path, out_path);
        end

        #100;
        $display("Simulation Finished. Generated OutData/01.raw ... OutData/30.raw");
        $finish;
    end

    // Keep AXIS streaming continuous while writing overlay updates in parallel.
    initial begin
        wait(axis_aresetn);
        forever begin
            @(posedge s00_axi_aclk);
            if (!red_pattern_written && (stream_frame_idx >= 10)) begin
                write_circle();
                commit_and_read_counts(10);
                // alpha 3/4 + BGR888 for circle
                axi_write(33'h8040001C, 32'h00030001);
                red_pattern_written = 1'b1;
            end else if (!green_pattern_written && (stream_frame_idx >= 20)) begin
                write_square();
                commit_and_read_counts(20);
                // alpha 0 + BGR888 for square
                axi_write(33'h8040001C, 32'h00000001);
                green_pattern_written = 1'b1;
            end
        end
    end

endmodule
