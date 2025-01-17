/*
###############################################################################
# Copyright (c) 2019, PulseRain Technology LLC 
#
# This program is distributed under a dual license: an open source license, 
# and a commercial license. 
# 
# The open source license under which this program is distributed is the 
# GNU Public License version 3 (GPLv3).
#
# And for those who want to use this program in ways that are incompatible
# with the GPLv3, PulseRain Technology LLC offers commercial license instead.
# Please contact PulseRain Technology LLC (www.pulserain.com) for more detail.
#
###############################################################################
*/

`include "common.vh"
`include "config.vh"

`default_nettype none


module mem_controller (

    //=======================================================================
    // clock / reset
    //=======================================================================

        input   wire                                                    clk,
        input   wire                                                    reset_n,
        input   wire                                                    sync_reset,

    //=======================================================================
    // memory interface
    //=======================================================================
        input  wire  [`MEM_ADDR_BITS - 1 : 0]                           mem_addr,
        input  wire                                                     mem_read_en,
        input  wire  [`XLEN_BYTES - 1 : 0]                              mem_write_en,
        input  wire  [`XLEN - 1 : 0]                                    mem_write_data,
        
        output wire  [`XLEN - 1 : 0]                                    mem_read_data,
        output wire                                                     mem_write_ack,
        output wire                                                     mem_read_ack
        
);
    //=======================================================================
    // signal
    //=======================================================================
        wire                                                mem_sdram0_dram1; 
        wire [15 : 0]                                       dout_high;
        wire [15 : 0]                                       dout_low;
        
        reg [15 : 0]                                      dout_high_d1;
        reg [15 : 0]                                      dout_low_d1;
        
        reg [15 : 0]                                      dout_high_d2;
        reg [15 : 0]                                      dout_low_d2;
        
        reg                                               sram_read_ack_pre;
        reg                                               sram_read_ack_pre_pre;
        reg                                               sram_read_ack;
        
        reg                                               sram_write_ack_pre;
        
        wire                                              sram_write_ack;
        
    //=======================================================================
    // SRAM
    //=======================================================================
        assign mem_sdram0_dram1 = mem_addr [`MEM_ADDR_BITS - 1];

           single_port_ram #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16) ) ram_high_i (
                .addr (mem_addr [`SRAM_ADDR_BITS - 1 : 0]),
                .din (mem_write_data [31 : 16]),
                .write_en (mem_write_en[3 : 2] & {~mem_sdram0_dram1, ~mem_sdram0_dram1} ),
                .clk (clk),
                .dout (dout_high));

            single_port_ram #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16) ) ram_low_i (
                .addr (mem_addr[`SRAM_ADDR_BITS - 1 : 0]),
                .din (mem_write_data [15 : 0]),
                .write_en (mem_write_en[1 : 0] & {~mem_sdram0_dram1, ~mem_sdram0_dram1} ),
                .clk (clk),
                .dout (dout_low));


/*
            single_port_ram_sim_high #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16) ) ram_high_i (
                .addr (mem_addr[`SRAM_ADDR_BITS - 1 : 0]),
                .din (mem_write_data [31 : 16]),
                .write_en (mem_write_en[3 : 2]),
                .clk (clk),
                .dout (dout_high));
              
            single_port_ram_sim_low #(.ADDR_WIDTH (`SRAM_ADDR_BITS), .DATA_WIDTH (16) ) ram_low_i (
                .addr (mem_addr[`SRAM_ADDR_BITS - 1 : 0]),
                .din (mem_write_data [15 : 0]),
                .write_en (mem_write_en[1 : 0]),
                .clk (clk),
                .dout (dout_low));

*/

      //  assign mem_read_data = {dout_high, dout_low};
        assign mem_read_data = {dout_high_d1, dout_low_d1};
        //assign mem_read_data = {dout_high_d2, dout_low_d2};

        always @(posedge clk, negedge reset_n) begin : ack_proc
            if (!reset_n) begin
                sram_read_ack <= 0;
                sram_read_ack_pre <= 0;
                sram_read_ack_pre_pre <= 0;
                dout_high_d1 <= 0;
                dout_low_d1  <= 0;
                dout_high_d2 <= 0;
                dout_low_d2  <= 0;
                
           //     sram_write_ack <= 0;
             //   sram_write_ack_pre <= 0;
                
            end else begin
                sram_read_ack_pre <= mem_read_en & (~mem_sdram0_dram1);
                sram_read_ack <= sram_read_ack_pre;
         
          //      sram_read_ack_pre_pre <= mem_read_en & (~mem_sdram0_dram1);
          //      sram_read_ack_pre <= sram_read_ack_pre_pre;
          //      sram_read_ack <= sram_read_ack_pre;
                
            //    sram_read_ack <= mem_read_en & (~mem_sdram0_dram1);
                
                dout_high_d1 <= dout_high;
                dout_low_d1  <= dout_low;
                
                dout_high_d2 <= dout_high_d1;
                dout_low_d2  <= dout_low_d1;
                
               // sram_write_ack <= (|mem_write_en) & (~mem_sdram0_dram1);
               
         //      sram_write_ack_pre <= (|mem_write_en) & (~mem_sdram0_dram1);
       //        sram_write_ack <= sram_write_ack_pre;
            end
        end : ack_proc
        
        assign sram_write_ack = (|mem_write_en) & (~mem_sdram0_dram1);
        
        assign mem_write_ack = sram_write_ack;
        assign mem_read_ack  = sram_read_ack;

endmodule

`default_nettype wire
