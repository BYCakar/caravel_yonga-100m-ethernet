`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 04.08.2021 17:21:28
// Design Name:
// Module Name: udp_host
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module udp_host(
    input  wire       clk,
    input  wire       rst,

    /*
     * Ethernet: 100BASE-T MII
     */
    input  wire [3:0] phy_txd,
    input  wire       phy_tx_en,
    output wire       phy_tx_clk,
    output wire       phy_rx_clk,
    output wire [3:0] phy_rxd,
    output wire       phy_rx_dv,
    output wire       phy_rx_er
    );

    localparam RX_STATE_IDLE              = 2'b00;
    localparam RX_STATE_SEND_UDP_FRAME    = 2'b01;
    localparam RX_STATE_SEND_ARP_RESPONSE = 2'b10;
    localparam RX_STATE_ARP_RESPONSE_DONE = 2'b11;

    localparam TX_STATE_IDLE              = 2'b00;
    localparam TX_STATE_RECV_ARP_REQUEST  = 2'b01;
    localparam TX_STATE_RECV_UDP_FRAME    = 2'b10;
    localparam TX_STATE_ARP_REQUEST_DONE  = 2'b11;

    reg [3:0] phy_rxd_reg = 0;
    reg phy_rx_dv_reg = 0, phy_rx_er_reg = 0;

    reg [3:0] phy_txd_reg = 0;
    reg phy_tx_en_reg = 0;

    assign phy_tx_clk = ~clk;
    assign phy_rx_clk = ~clk;
    assign phy_rxd    = phy_rxd_reg;
    assign phy_rx_dv  = phy_rx_dv_reg;
    assign phy_rx_er  = phy_rx_er_reg;

    reg [7:0] rx_udp_frame [0:309];
    reg [7:0] rx_arp_frame [0:71];

    reg [7:0] tx_udp_frame [0:309];
    reg [7:0] tx_arp_frame [0:71];

    reg [7:0] tx_udp_frame_diff [0:309];
    reg [7:0] tx_arp_frame_diff [0:71];

    reg reset_flag = 0;
    reg reset_diff = 0;

    reg [1:0] rx_state = RX_STATE_IDLE;
    reg [1:0] tx_state = TX_STATE_IDLE;

    reg [9:0] rx_mem_sp = 0;
    reg [9:0] tx_mem_sp = 0;

    integer i;

    reg first_frame = 1;

    initial begin
        $readmemb("udp_frame.mem", rx_udp_frame);
        $readmemb("arp_resp_frame.mem", rx_arp_frame);
        $readmemb("phy_frame.mem", tx_udp_frame_diff);
        $readmemb("arp_rqst_frame.mem", tx_arp_frame_diff);
    end

    always @(negedge rst) reset_flag = ~reset_flag;

    always @(posedge clk) begin
        phy_txd_reg <= phy_txd;
        phy_tx_en_reg <= phy_tx_en;

        if(reset_flag^reset_diff) rx_state <= RX_STATE_SEND_UDP_FRAME;

        else begin
            if(phy_tx_en && tx_state == TX_STATE_IDLE) tx_state <= first_frame ? TX_STATE_RECV_ARP_REQUEST : TX_STATE_RECV_UDP_FRAME;
            if(phy_tx_en && tx_state == TX_STATE_ARP_REQUEST_DONE) tx_state <= TX_STATE_RECV_UDP_FRAME;

            if(rx_state == RX_STATE_SEND_UDP_FRAME) begin
                if(rx_mem_sp == 0) begin
                    phy_rx_dv_reg <= 1;
                    phy_rxd_reg <= rx_mem_sp[0] ? rx_udp_frame[rx_mem_sp[9:1]][7:4] : rx_udp_frame[rx_mem_sp[9:1]][3:0];
                    rx_mem_sp <= rx_mem_sp + 1;
                end

                else if (rx_mem_sp[9:1] < 310) begin
                    phy_rxd_reg <= rx_mem_sp[0] ? rx_udp_frame[rx_mem_sp[9:1]][7:4] : rx_udp_frame[rx_mem_sp[9:1]][3:0];
                    rx_mem_sp = rx_mem_sp + 1;
                end

                else begin
                    rx_state <= RX_STATE_IDLE;
                    rx_mem_sp <= 0;
                    phy_rxd_reg <= 0;
                    phy_rx_dv_reg <= 0;
                end
            end

            else if (rx_state == RX_STATE_SEND_ARP_RESPONSE) begin
                if(rx_mem_sp == 0) begin
                    phy_rx_dv_reg <= 1;
                    phy_rxd_reg <= rx_mem_sp[0] ? rx_arp_frame[rx_mem_sp[9:1]][7:4] : rx_arp_frame[rx_mem_sp[9:1]][3:0];
                    rx_mem_sp <= rx_mem_sp + 1;
                end

                else if (rx_mem_sp[9:1] < 72) begin
                    phy_rxd_reg <= rx_mem_sp[0] ? rx_arp_frame[rx_mem_sp[9:1]][7:4] : rx_arp_frame[rx_mem_sp[9:1]][3:0];
                    rx_mem_sp = rx_mem_sp + 1;
                end

                else begin
                    rx_state <= RX_STATE_ARP_RESPONSE_DONE;
                    rx_mem_sp <= 0;
                    phy_rxd_reg <= 0;
                    phy_rx_dv_reg <= 0;
                end
            end

            else if (rx_state == RX_STATE_ARP_RESPONSE_DONE) begin

            end

            if (tx_state == TX_STATE_RECV_ARP_REQUEST) begin
                if (phy_tx_en_reg) begin
                    tx_arp_frame[tx_mem_sp[9:1]] <= tx_mem_sp[0] ? {phy_txd_reg, tx_arp_frame[tx_mem_sp[9:1]][3:0]} : {4'b0, phy_txd_reg};
                    tx_mem_sp <= tx_mem_sp + 1;
                end

                else if (tx_mem_sp[9:1] == 72 && ~phy_tx_en_reg) begin
                    for (i = 0; i < 72; i = i + 1) begin
                        if(tx_arp_frame[i] != tx_arp_frame_diff[i]) begin
                            $display("ARP request wasn't received properly");
                            $finish;
                        end
                    end

                    $display("Received ARP request");
                    tx_state <= TX_STATE_ARP_REQUEST_DONE;
                    tx_mem_sp <= 0;
                end

                else begin
                    $display("ARP request wasn't received properly");
                    $finish;
                end
            end

            else if (tx_state == TX_STATE_RECV_UDP_FRAME) begin
                if (phy_tx_en_reg) begin
                    tx_udp_frame[tx_mem_sp[9:1]] <= tx_mem_sp[0] ? {phy_txd_reg, tx_udp_frame[tx_mem_sp[9:1]][3:0]} : {4'b0, phy_txd_reg};
                    tx_mem_sp <= tx_mem_sp + 1;
                end

                else if (tx_mem_sp[9:1] == 310 && ~phy_tx_en_reg) begin
                    for (i = 0; i < 310; i = i + 1) begin
                        if(tx_udp_frame[i] != tx_udp_frame_diff[i]) begin
                            $display("UDP frame wasn't received properly");
                            $finish;
                        end
                    end

                    $display("Received UDP frame");
                    tx_state  <= TX_STATE_IDLE;
                    tx_mem_sp <= 0;
                    first_frame <= 0;
                    rx_state  <= RX_STATE_SEND_UDP_FRAME;
                    rx_mem_sp <= 0;
                    $finish;
                end

                else begin
                    $display("UDP frame wasn't received properly");
                    $finish;
                end
            end

            else if (tx_state == TX_STATE_ARP_REQUEST_DONE && rx_state == RX_STATE_IDLE) rx_state <= RX_STATE_SEND_ARP_RESPONSE;
        end
    end
endmodule
