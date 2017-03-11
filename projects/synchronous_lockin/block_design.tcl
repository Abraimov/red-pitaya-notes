#synchronous lockin 108

# Create processing_system7
cell xilinx.com:ip:processing_system7:5.5 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
  PCW_USE_S_AXI_HP0 1
} {
  M_AXI_GP0_ACLK ps_0/FCLK_CLK0
  S_AXI_HP0_ACLK ps_0/FCLK_CLK0
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create util_ds_buf
cell xilinx.com:ip:util_ds_buf:2.1 buf_0 {
  C_SIZE 2
  C_BUF_TYPE IBUFDS
} {
  IBUF_DS_P daisy_p_i
  IBUF_DS_N daisy_n_i
}

# Create util_ds_buf
cell xilinx.com:ip:util_ds_buf:2.1 buf_1 {
  C_SIZE 2
  C_BUF_TYPE OBUFDS
} {
  OBUF_DS_P daisy_p_o
  OBUF_DS_N daisy_n_o
}

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset:5.0 rst_0


# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc:1.0 adc_0 {} {
  adc_clk_p adc_clk_p_i
  adc_clk_n adc_clk_n_i
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# Create c_counter_binary
cell xilinx.com:ip:c_counter_binary:12.0 cntr_0 {
  Output_Width 32
} {
  CLK adc_0/adc_clk
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 32 DIN_FROM 25 DIN_TO 25 DOUT_WIDTH 1
} {
  Din cntr_0/Q
 }


# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register:1.0 cfg_0 {
  CFG_DATA_WIDTH 256
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins cfg_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_1 {
  DIN_WIDTH 256 DIN_FROM 134 DIN_TO 128 DOUT_WIDTH 7
} {
  Din cfg_0/cfg_data
}

# Create xlconcat
cell xilinx.com:ip:xlconcat:2.1 concat_0 {
  IN1_WIDTH 7
} {
  In0 slice_0/Dout
  In1 slice_1/Dout
  dout led_o
}


# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_pktzr_reset {
  DIN_WIDTH 256 DIN_FROM 0 DIN_TO 0
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_write_enable {
  DIN_WIDTH 256 DIN_FROM 1 DIN_TO 1
} {
  Din cfg_0/cfg_data
}


# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_record_length {
  DIN_WIDTH 256 DIN_FROM 63 DIN_TO 32 DOUT_WIDTH 32
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_trig_record {
  DIN_WIDTH 256 DIN_FROM 3 DIN_TO 3
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_trx_reset {
  DIN_WIDTH 256 DIN_FROM 4 DIN_TO 4
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_filter_reset {
  DIN_WIDTH 256 DIN_FROM 5 DIN_TO 5
} {
  Din cfg_0/cfg_data
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_1



# Create axis_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_ADC { 
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 2
} {
  S_AXIS adc_0/M_AXIS
  s_axis_aclk adc_0/adc_clk
  s_axis_aresetn const_1/dout
  m_axis_aclk ps_0/FCLK_CLK0
  m_axis_aresetn slice_trx_reset/dout
}

# Create gpio_trigger
cell pavel-demin:user:gpio_trigger:1.0 trigger_0 {
	GPIO_DATA_WIDTH 8
} {
  gpio_data exp_p_tri_io
  soft_trig slice_trig_record/Dout
  aclk ps_0/FCLK_CLK0
  aresetn slice_pktzr_reset/Dout
}


# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_frequency {
  DIN_WIDTH 256 DIN_FROM 95 DIN_TO 64
} {
  Din cfg_0/cfg_data
}

# Create axis_constant
cell pavel-demin:user:axis_constant:1.0 phase_0 {
  AXIS_TDATA_WIDTH 32
} {
  cfg_data slice_frequency/Dout
  aclk ps_0/FCLK_CLK0
}


# Create dds_compiler
cell xilinx.com:ip:dds_compiler:6.0 dds_0 {
  MODE_OF_OPERATION Rasterized
  MODULUS 15120
  DDS_CLOCK_RATE 125
  parameter_entry Hardware_Parameters
  OUTPUT_WIDTH 14
  PHASE_WIDTH 14
  PHASE_INCREMENT Streaming
  DSP48_USE Maximal
  HAS_TREADY true
  Has_ARESETn true
  Has_Phase_Out false
} {
  S_AXIS_PHASE phase_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_trx_reset/dout
}

# Create clk_wiz
cell xilinx.com:ip:clk_wiz:5.3 pll_0 {
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 125.0
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 250.0
} {
  clk_in1 adc_0/adc_clk
}


# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_DDS {
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 4
 } {
  S_AXIS  dds_0/M_AXIS_DATA
  aclk ps_0/FCLK_CLK0
  aresetn slice_trx_reset/dout
}


# Create axis_lfsr
cell pavel-demin:user:axis_lfsr:1.0 lfsr_0 {} {
  aclk ps_0/FCLK_CLK0
  aresetn slice_trx_reset/dout
}

# create delay line
module delay_dds {
  source projects/modules/delay_line_32.tcl
} {
  s_axis bcast_DDS/M00_AXIS
  cfg cfg_0/cfg_data
  aclk ps_0/FCLK_CLK0
  aresetn slice_filter_reset/dout
}

# Create cmpy
cell xilinx.com:ip:cmpy:6.0 mult_0 {
  FLOWCONTROL Blocking
  APORTWIDTH.VALUE_SRC USER
  BPORTWIDTH.VALUE_SRC USER
  APORTWIDTH 14
  BPORTWIDTH 14
  ROUNDMODE Random_Rounding
  OUTPUTWIDTH 28
  ARESETN true
} {
  S_AXIS_A fifo_ADC/M_AXIS
  s_axis_b delay_dds/M_AXIS
  S_AXIS_CTRL lfsr_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_trx_reset/dout
}

# create filter
module filter_xy {
  source projects/modules/filter_xy_avg_32.tcl
} {
  s_axis mult_0/M_AXIS_DOUT
  cfg cfg_0/cfg_data
  aclk ps_0/FCLK_CLK0
  aresetn slice_filter_reset/dout
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_xy {
  S_TDATA_NUM_BYTES 8
} {
  S_AXIS filter_xy/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_trx_reset/dout
}


# create filter
module filter_xy_value {
  source projects/modules/filter_xy_avg_32_2.tcl
} {
  s_axis bcast_xy/M01_AXIS
  cfg cfg_0/cfg_data
  aclk ps_0/FCLK_CLK0
  aresetn slice_trx_reset/dout
}

#create value
cell pavel-demin:user:axis_value:1.0 value_xy {
AXIS_TDATA_WIDTH 64
} {
  s_axis filter_xy_value/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create axis_packetizer
cell pavel-demin:user:axis_circular_packetizer:1.0 pktzr_0 {
  AXIS_TDATA_WIDTH 64
  AXIS_TDATA_PHASE_WIDTH 64
  CNTR_WIDTH 25
  CONTINUOUS FALSE
  NON_BLOCKING TRUE
} {
  S_AXIS bcast_xy/M00_AXIS
  cfg_data slice_record_length/Dout
  trigger trigger_0/trigger
  aclk ps_0/FCLK_CLK0
  aresetn slice_pktzr_reset/Dout
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_2 {
  CONST_WIDTH 32
  CONST_VAL 268435456
}

# Create axis_ram_writer
cell pavel-demin:user:axis_ram_writer:1.0 writer_0 {
  ADDR_WIDTH 25
} {
  S_AXIS pktzr_0/M_AXIS
  M_AXI ps_0/S_AXI_HP0
  m_axi_awready  ps_0/S_AXI_HP0_AWREADY
  m_axi_wready ps_0/S_AXI_HP0_WREADY
  cfg_data const_2/dout
  aclk ps_0/FCLK_CLK0
  aresetn slice_write_enable/Dout
}

assign_bd_address [get_bd_addr_segs ps_0/S_AXI_HP0/HP0_DDR_LOWOCM]


# Create dac_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_DAC {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
} {
  s_axis bcast_DDS/M01_AXIS
  s_axis_aclk ps_0/FCLK_CLK0
  s_axis_aresetn slice_trx_reset/dout
  m_axis_aclk adc_0/adc_clk
  m_axis_aresetn const_1/dout
}

# Create axis_red_pitaya_dac
cell pavel-demin:user:axis_red_pitaya_dac:1.0 dac_0 {} {
  aclk adc_0/adc_clk
  ddr_clk pll_0/clk_out1
  locked pll_0/locked
  S_AXIS fifo_DAC/M_AXIS
  dac_clk dac_clk_o
  dac_rst dac_rst_o
  dac_sel dac_sel_o
  dac_wrt dac_wrt_o
  dac_dat dac_dat_o
}



# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_ID {
  CONST_WIDTH 16
  CONST_VAL 108
}

# Create xlconcat
cell xilinx.com:ip:xlconcat:2.1 concat_sts {
  NUM_PORTS 10
  IN0_WIDTH 32
  IN1_WIDTH 32
  IN2_WIDTH 1
  IN3_WIDTH 1
  IN4_WIDTH 1
  IN5_WIDTH 1
  IN6_WIDTH 12
  IN7_WIDTH 16
  IN8_WIDTH 32
  IN9_WIDTH 64
} {
  In0 writer_0/sts_data
  In1 pktzr_0/trigger_pos
  In2 trigger_0/trigger
  In3 pktzr_0/complete
  In4 ps_0/S_AXI_HP0_AWREADY
  In5 ps_0/S_AXI_HP0_WREADY
  In7 const_ID/dout
  In9 value_xy/data
}

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register:1.0 sts_0 {
  STS_DATA_WIDTH 256
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data concat_sts/dout
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins sts_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]
set_property OFFSET 0x40001000 [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]
