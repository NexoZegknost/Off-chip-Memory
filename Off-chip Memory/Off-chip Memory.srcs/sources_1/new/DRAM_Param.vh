`ifndef DRAM_PARAMETERS_VH
`define DRAM_PARAMETERS_VH

parameter DATA_WIDTH   = 32;
parameter ADDR_WIDTH   = 32;
parameter QUEUE_SIZE   = 32;

parameter T_RCD        = 5;        // Row to Column Delay
parameter T_RP         = 5;        // Row Precharge Delay
parameter T_CL         = 4;        // CAS Latency
parameter T_RAS        = 12;       // Row Active Time

`endif