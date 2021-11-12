// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

// Include caravel global defines for the number of the user project IO pads 
`include "defines.v"
`define USE_POWER_PINS

`ifdef GL
    // Assume default net type to be wire because GL netlists don't have the wire definitions
    `default_nettype wire
    `include "gl/user_project_wrapper.v"
    `include "gl/user_proj_example.v"
`else
    `include "user_project_wrapper.v"
    `include "user_proj_example.v"
    `include "ethernet_100m.v"
    `include "arbiter.v"
    `include "arp_cache.v"
    `include "arp_eth_rx.v"
    `include "arp_eth_tx.v"
    `include "arp.v"
    `include "axis_async_fifo_adapter.v"
    `include "axis_async_fifo.v"
    `include "axis_fifo.v"
    `include "axis_gmii_rx.v"
    `include "axis_gmii_tx.v"
    `include "eth_arb_mux.v"
    `include "eth_axis_rx.v"
    `include "eth_axis_tx.v"
    `include "ethernet_core.v"
    `include "eth_mac_1g.v"
    `include "eth_mac_mii_fifo.v"
    `include "eth_mac_mii.v"
    `include "ip_arb_mux.v"
    `include "ip_complete.v"
    `include "ip_eth_rx.v"
    `include "ip_eth_tx.v"
    `include "ip.v"
    `include "lfsr.v"
    `include "mii_phy_if.v"
    `include "priority_encoder.v"
    `include "ssio_sdr_in.v"
    `include "udp_checksum_gen.v"
    `include "udp_complete.v"
    `include "udp_ip_rx.v"
    `include "udp_ip_tx.v"
    `include "udp.v"
    
`endif