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


//=============================================================================
// Remarks:
//    PulseRain RV2T is a MCU core of Von Neumann architecture. 
//=============================================================================

`include "common.vh"

`default_nettype none

module Reindeer_mm_reg (
    
    //=======================================================================
    // clock / reset
    //=======================================================================

        input   wire                                                    clk,
        input   wire                                                    reset_n,
        input   wire                                                    sync_reset,

    //=======================================================================
    // data read / write
    //=======================================================================
        input   wire                                                    data_read_enable,
        input   wire                                                    data_write_enable,
        
        input   wire  [`MM_REG_ADDR_BITS - 1 : 0]                       data_rw_addr,
        input   wire  [`XLEN - 1 : 0]                                   data_write_word,
        
    //=======================================================================
    // UART 
    //=======================================================================
        output wire                                                     start_TX,
        output wire [7 : 0]                                             tx_data,
        input  wire                                                     tx_active,
        
    //=======================================================================
    // output
    //=======================================================================
        output  reg                                                     enable_out,
        output  wire  [`XLEN - 1 : 0]                                   word_out,
        
        output  wire                                                    timer_triggered
);

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Signals
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire                                             load_mtimecmp_low;
        wire                                             load_mtimecmp_high;
        
        wire [`XLEN - 1 : 0]                             machine_timer_data_out;
        
        reg [`MM_REG_ADDR_BITS - 1 : 0]                  data_rw_addr_d1;
        
        
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Input
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        assign load_mtimecmp_low  = (data_write_enable & (data_rw_addr == `MTIMECMP_LOW_ADDR)) ? 1'b1 : 1'b0;
        assign load_mtimecmp_high = (data_write_enable & (data_rw_addr == `MTIMECMP_HIGH_ADDR)) ? 1'b1 : 1'b0;
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Output
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                enable_out <= 0;
                data_rw_addr_d1 <= 0;
            end else begin
                enable_out <= data_read_enable | data_write_enable;
                data_rw_addr_d1 <= data_rw_addr;
            end
        end
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // machine timer
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        Reindeer_machine_timer Reindeer_machine_timer_i (
            .clk (clk),
            .reset_n (reset_n),
            .sync_reset (sync_reset),
            
            .load_mtimecmp_low (load_mtimecmp_low),
            .load_mtimecmp_high (load_mtimecmp_high),
            .mtimecmp_write_data (data_write_word),
            
            .timer_triggered (timer_triggered),
            
            .reg_read_addr (data_rw_addr [1 : 0]),
            .reg_read_data (machine_timer_data_out));
   
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // UART 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        assign start_TX = ((`UART_TX_ADDR == data_rw_addr) && data_write_enable) ? 1'b1 : 1'b0;
        assign tx_data = data_write_word [7 : 0];
        
            
        assign word_out = (data_rw_addr_d1 == `UART_TX_ADDR) ? {tx_active, 31'd0} : machine_timer_data_out;
        
        
        
endmodule

`default_nettype wire
