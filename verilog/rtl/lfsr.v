/*

Copyright (c) 2016-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * Parametrizable combinatorial parallel LFSR/CRC
 */
module lfsr #
(
    // width of LFSR
    parameter LFSR_WIDTH = 32,
    // LFSR polynomial
    parameter LFSR_POLY = 31'h10000001,
    // LFSR configuration: "GALOIS", "FIBONACCI"
    parameter LFSR_CONFIG = "FIBONACCI",
    // LFSR feed forward enable
    parameter LFSR_FEED_FORWARD = 0,
    // bit-reverse input and output
    parameter REVERSE = 0,
    // width of data input
    parameter DATA_WIDTH = 8,
    // implementation style: "AUTO", "LOOP", "REDUCTION"
    parameter STYLE = "AUTO"
)
(
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire [LFSR_WIDTH-1:0] state_in,
    output wire [DATA_WIDTH-1:0] data_out,
    output wire [LFSR_WIDTH-1:0] state_out
);

/*

Fully parametrizable combinatorial parallel LFSR/CRC module.  Implements an unrolled LFSR
next state computation, shifting DATA_WIDTH bits per pass through the module.  Input data
is XORed with LFSR feedback path, tie data_in to zero if this is not required.

Works in two parts: statically computes a set of bit masks, then uses these bit masks to
select bits for XORing to compute the next state.  

Ports:

data_in

Data bits to be shifted through the LFSR (DATA_WIDTH bits)

state_in

LFSR/CRC current state input (LFSR_WIDTH bits)

data_out

Data bits shifted out of LFSR (DATA_WIDTH bits)

state_out

LFSR/CRC next state output (LFSR_WIDTH bits)

Parameters:

LFSR_WIDTH

Specify width of LFSR/CRC register

LFSR_POLY

Specify the LFSR/CRC polynomial in hex format.  For example, the polynomial

x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1

would be represented as

32'h04c11db7

Note that the largest term (x^32) is suppressed.  This term is generated automatically based
on LFSR_WIDTH.

LFSR_CONFIG

Specify the LFSR configuration, either Fibonacci or Galois.  Fibonacci is generally used
for linear-feedback shift registers (LFSR) for pseudorandom binary sequence (PRBS) generators,
scramblers, and descrambers, while Galois is generally used for cyclic redundancy check
generators and checkers.

Fibonacci style (example for 64b66b scrambler, 0x8000000001)

   DIN (LSB first)
    |
    V
   (+)<---------------------------(+)<-----------------------------.
    |                              ^                               |
    |  .----.  .----.       .----. |  .----.       .----.  .----.  |
    +->|  0 |->|  1 |->...->| 38 |-+->| 39 |->...->| 56 |->| 57 |--'
    |  '----'  '----'       '----'    '----'       '----'  '----'
    V
   DOUT

Galois style (example for CRC16, 0x8005)

    ,-------------------+-------------------------+----------(+)<-- DIN (MSB first)
    |                   |                         |           ^
    |  .----.  .----.   V   .----.       .----.   V   .----.  |
    `->|  0 |->|  1 |->(+)->|  2 |->...->| 14 |->(+)->| 15 |--+---> DOUT
       '----'  '----'       '----'       '----'       '----'

LFSR_FEED_FORWARD

Generate feed forward instead of feed back LFSR.  Enable this for PRBS checking and self-
synchronous descrambling.

Fibonacci feed-forward style (example for 64b66b descrambler, 0x8000000001)

   DIN (LSB first)
    |
    |  .----.  .----.       .----.    .----.       .----.  .----.
    +->|  0 |->|  1 |->...->| 38 |-+->| 39 |->...->| 56 |->| 57 |--.
    |  '----'  '----'       '----' |  '----'       '----'  '----'  |
    |                              V                               |
   (+)<---------------------------(+)------------------------------'
    |
    V
   DOUT

Galois feed-forward style

    ,-------------------+-------------------------+------------+--- DIN (MSB first)
    |                   |                         |            |
    |  .----.  .----.   V   .----.       .----.   V   .----.   V
    `->|  0 |->|  1 |->(+)->|  2 |->...->| 14 |->(+)->| 15 |->(+)-> DOUT
       '----'  '----'       '----'       '----'       '----'

REVERSE

Bit-reverse LFSR input and output.  Shifts MSB first by default, set REVERSE for LSB first.

DATA_WIDTH

Specify width of input and output data bus.  The module will perform one shift per input
data bit, so if the input data bus is not required tie data_in to zero and set DATA_WIDTH
to the required number of shifts per clock cycle.  

STYLE

Specify implementation style.  Can be "AUTO", "LOOP", or "REDUCTION".  When "AUTO"
is selected, implemenation will be "LOOP" or "REDUCTION" based on synthesis translate
directives.  "REDUCTION" and "LOOP" are functionally identical, however they simulate
and synthesize differently.  "REDUCTION" is implemented with a loop over a Verilog
reduction operator.  "LOOP" is implemented as a doubly-nested loop with no reduction
operator.  "REDUCTION" is very fast for simulation in iverilog and synthesizes well in
Quartus but synthesizes poorly in ISE, likely due to large inferred XOR gates causing
problems with the optimizer.  "LOOP" synthesizes will in both ISE and Quartus.  "AUTO"
will default to "REDUCTION" when simulating and "LOOP" for synthesizers that obey
synthesis translate directives.

Settings for common LFSR/CRC implementations:

Name        Configuration           Length  Polynomial      Initial value   Notes
CRC16-IBM   Galois, bit-reverse     16      16'h8005        16'hffff
CRC16-CCITT Galois                  16      16'h1021        16'h1d0f
CRC32       Galois, bit-reverse     32      32'h04c11db7    32'hffffffff    Ethernet FCS; invert final output
PRBS6       Fibonacci               6       6'h21           any
PRBS7       Fibonacci               7       7'h41           any
PRBS9       Fibonacci               9       9'h021          any             ITU V.52
PRBS10      Fibonacci               10      10'h081         any             ITU
PRBS11      Fibonacci               11      11'h201         any             ITU O.152
PRBS15      Fibonacci, inverted     15      15'h4001        any             ITU O.152
PRBS17      Fibonacci               17      17'h04001       any
PRBS20      Fibonacci               20      20'h00009       any             ITU V.57
PRBS23      Fibonacci, inverted     23      23'h040001      any             ITU O.151
PRBS29      Fibonacci, inverted     29      29'h08000001    any
PRBS31      Fibonacci, inverted     31      31'h10000001    any
64b66b      Fibonacci, bit-reverse  58      58'h8000000001  any             10G Ethernet
128b130b    Galois, bit-reverse     23      23'h210125      any             PCIe gen 3

*/

wire [LFSR_WIDTH-1:0] lfsr_mask_state[LFSR_WIDTH-1:0];
wire [DATA_WIDTH-1:0] lfsr_mask_data[LFSR_WIDTH-1:0];
wire [LFSR_WIDTH-1:0] output_mask_state[DATA_WIDTH-1:0];
wire [DATA_WIDTH-1:0] output_mask_data[DATA_WIDTH-1:0];

wire [LFSR_WIDTH-1:0] state_val;
wire [DATA_WIDTH-1:0] data_val;

integer i, j;

assign lfsr_mask_state[31] = 32'h00000082;
assign lfsr_mask_state[30] = 32'h000000c3;
assign lfsr_mask_state[29] = 32'h000000e3;
assign lfsr_mask_state[28] = 32'h00000071;
assign lfsr_mask_state[27] = 32'h000000ba;
assign lfsr_mask_state[26] = 32'h000000df;
assign lfsr_mask_state[25] = 32'h0000006f;
assign lfsr_mask_state[24] = 32'h000000b5;
assign lfsr_mask_state[23] = 32'h800000d8;
assign lfsr_mask_state[22] = 32'h4000006c;
assign lfsr_mask_state[21] = 32'h200000b4;
assign lfsr_mask_state[20] = 32'h100000d8;
assign lfsr_mask_state[19] = 32'h080000ee;
assign lfsr_mask_state[18] = 32'h04000077;
assign lfsr_mask_state[17] = 32'h0200003b;
assign lfsr_mask_state[16] = 32'h0100001d;
assign lfsr_mask_state[15] = 32'h0080008c;
assign lfsr_mask_state[14] = 32'h00400046;
assign lfsr_mask_state[13] = 32'h00200023;
assign lfsr_mask_state[12] = 32'h00100011;
assign lfsr_mask_state[11] = 32'h00080008;
assign lfsr_mask_state[10] = 32'h00040004;
assign lfsr_mask_state[9] = 32'h00020080;
assign lfsr_mask_state[8] = 32'h000100c2;
assign lfsr_mask_state[7] = 32'h00008061;
assign lfsr_mask_state[6] = 32'h00004030;
assign lfsr_mask_state[5] = 32'h0000209a;
assign lfsr_mask_state[4] = 32'h0000104d;
assign lfsr_mask_state[3] = 32'h00000826;
assign lfsr_mask_state[2] = 32'h00000413;
assign lfsr_mask_state[1] = 32'h00000209;
assign lfsr_mask_state[0] = 32'h00000104;

assign lfsr_mask_data[31] = 8'h82;
assign lfsr_mask_data[30] = 8'hc3;
assign lfsr_mask_data[29] = 8'he3;
assign lfsr_mask_data[28] = 8'h71;
assign lfsr_mask_data[27] = 8'hba;
assign lfsr_mask_data[26] = 8'hdf;
assign lfsr_mask_data[25] = 8'h6f;
assign lfsr_mask_data[24] = 8'hb5;
assign lfsr_mask_data[23] = 8'hd8;
assign lfsr_mask_data[22] = 8'h6c;
assign lfsr_mask_data[21] = 8'hb4;
assign lfsr_mask_data[20] = 8'hd8;
assign lfsr_mask_data[19] = 8'hee;
assign lfsr_mask_data[18] = 8'h77;
assign lfsr_mask_data[17] = 8'h3b;
assign lfsr_mask_data[16] = 8'h1d;
assign lfsr_mask_data[15] = 8'h8c;
assign lfsr_mask_data[14] = 8'h46;
assign lfsr_mask_data[13] = 8'h23;
assign lfsr_mask_data[12] = 8'h11;
assign lfsr_mask_data[11] = 8'h08;
assign lfsr_mask_data[10] = 8'h04;
assign lfsr_mask_data[9] = 8'h80;
assign lfsr_mask_data[8] = 8'hc2;
assign lfsr_mask_data[7] = 8'h61;
assign lfsr_mask_data[6] = 8'h30;
assign lfsr_mask_data[5] = 8'h9a;
assign lfsr_mask_data[4] = 8'h4d;
assign lfsr_mask_data[3] = 8'h26;
assign lfsr_mask_data[2] = 8'h13;
assign lfsr_mask_data[1] = 8'h09;
assign lfsr_mask_data[0] = 8'h04;

assign output_mask_state[7] = 32'h00000082;
assign output_mask_state[6] = 32'h00000041;
assign output_mask_state[5] = 32'h00000020;
assign output_mask_state[4] = 32'h00000010;
assign output_mask_state[3] = 32'h00000008;
assign output_mask_state[2] = 32'h00000004;
assign output_mask_state[1] = 32'h00000002;
assign output_mask_state[0] = 32'h00000001;

assign output_mask_data[7] = 8'h82;
assign output_mask_data[6] = 8'h41;
assign output_mask_data[5] = 8'h20;
assign output_mask_data[4] = 8'h10;
assign output_mask_data[3] = 8'h08;
assign output_mask_data[2] = 8'h04;
assign output_mask_data[1] = 8'h02;
assign output_mask_data[0] = 8'h01;

assign state_val = 32'h00000082;
assign data_val = 8'h82;

// synthesis translate_off
`define SIMULATION
// synthesis translate_on

`ifdef SIMULATION
// "AUTO" style is "REDUCTION" for faster simulation
parameter STYLE_INT = (STYLE == "AUTO") ? "REDUCTION" : STYLE;
`else
// "AUTO" style is "LOOP" for better synthesis result
parameter STYLE_INT = (STYLE == "AUTO") ? "LOOP" : STYLE;
`endif

genvar n;

generate

if (STYLE_INT == "REDUCTION") begin

    // use Verilog reduction operator
    // fast in iverilog
    // significantly larger than generated code with ISE (inferred wide XORs may be tripping up optimizer)
    // slightly smaller than generated code with Quartus
    // --> better for simulation

    for (n = 0; n < LFSR_WIDTH; n = n + 1) begin : loop1
        assign state_out[n] = ^{(state_in & lfsr_mask_state[n]), (data_in & lfsr_mask_data[n])};
    end
    for (n = 0; n < DATA_WIDTH; n = n + 1) begin : loop2
        assign data_out[n] = ^{(state_in & output_mask_state[n]), (data_in & output_mask_data[n])};
    end

end else if (STYLE_INT == "LOOP") begin

    // use nested loops
    // very slow in iverilog
    // slightly smaller than generated code with ISE
    // same size as generated code with Quartus
    // --> better for synthesis

    reg [LFSR_WIDTH-1:0] state_out_reg = 0;
    reg [DATA_WIDTH-1:0] data_out_reg = 0;

    assign state_out = state_out_reg;
    assign data_out = data_out_reg;

    always @* begin
        for (i = 0; i < LFSR_WIDTH; i = i + 1) begin
            state_out_reg[i] = 0;
            for (j = 0; j < LFSR_WIDTH; j = j + 1) begin
                if (lfsr_mask_state[i][j]) begin
                    state_out_reg[i] = state_out_reg[i] ^ state_in[j];
                end
            end
            for (j = 0; j < DATA_WIDTH; j = j + 1) begin
                if (lfsr_mask_data[i][j]) begin
                    state_out_reg[i] = state_out_reg[i] ^ data_in[j];
                end
            end
        end
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            data_out_reg[i] = 0;
            for (j = 0; j < LFSR_WIDTH; j = j + 1) begin
                if (output_mask_state[i][j]) begin
                    data_out_reg[i] = data_out_reg[i] ^ state_in[j];
                end
            end
            for (j = 0; j < DATA_WIDTH; j = j + 1) begin
                if (output_mask_data[i][j]) begin
                    data_out_reg[i] = data_out_reg[i] ^ data_in[j];
                end
            end
        end
    end

end else begin

    initial begin
        $error("Error: unknown style setting!");
        $finish;
    end

end

endgenerate

endmodule
