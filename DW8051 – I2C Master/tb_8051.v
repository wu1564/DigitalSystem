`timescale 1ns / 10ps
module tb_8051 ();
   parameter       clkx8 = 27.08;  // 48*64=3.072 MHZ,325/12=27.08

   reg clk; 
   reg por_n; 
   reg rst_in_n; 
   wire rst_out_n; 
   reg test_mode_n; 
   wire stop_mode_n; 
   wire idle_mode_n; 
   wire [7:0] sfr_addr; 
   wire [7:0] sfr_data_out; 
   wire [7:0] sfr_data_in; 
   wire sfr_wr; 
   wire sfr_rd; 
   wire [15:0] mem_addr; 
   wire [7:0] mem_data_out; 
   wire [7:0] mem_data_in; 
   wire mem_wr_r; 
   wire mem_rd_n; 
   wire mem_pswr_n;    
   
   wire mem_psrd_n; 
   wire mem_ale; 
   reg mem_ea_n; 
   wire int0_n; 
   wire int1_n; 
   wire int2; 
   wire int3_n; 
   wire int4; 
   wire int5_n; 
   wire pfi; 
   wire wdti; 
   wire rxd0_in; 
   wire rxd0_out, txd0; 
   wire rxd1_in; 
   wire rxd1_out, txd1; 
   wire t0; 
   wire t1; 
   wire t2; 
   wire t2ex; 
   wire t0_out, t1_out, t2_out; 
   wire port_pin_reg_n, p0_mem_reg_n, p0_addr_data_n, p2_mem_reg_n; 
   wire [7:0] iram_addr, iram_data_out, iram_data_in; 
   wire iram_rd_n, iram_we1_n, iram_we2_n; 
   wire [15:0] irom_addr; 
   wire [7:0] irom_data_out; 
   wire irom_rd_n, irom_cs_n; 
  
   wire [7:0] P0,P1,P2,P3;
   
   wire	i2c_sda;
   wire	i2c_scl;

   
   pullup(i2c_sda);
   pullup(i2c_scl);
   
   always
   begin
      #(clkx8/2) clk <= 1'b1 ;
      #(clkx8/2) clk <= 1'b0 ;
   end 

   initial
    begin
   
      //$fsdbDumpfile("tb_8051.fsdb");
      //$fsdbDumpfile("tb_8051_io.fsdb"); 
      //$fsdbDumpvars;
            
      mem_ea_n = 1'b1;              // 1: external ROM ,0: Internal ROM
      por_n = 1'b1 ;
      rst_in_n  = 1'b1;
      test_mode_n = 1'b1;
      #(clkx8*10);
      por_n = 1'b0 ;
      rst_in_n  = 1'b0;
      #(clkx8*10);
      por_n = 1'b1 ;
      rst_in_n  = 1'b1;
      
      wait((irom_addr == 16'h0B16) | (irom_addr == 16'h0B19));
      #1000;
      $finish;

    end
     
     
  
//--------------------------------------------------------------- 
// DW8051 instantiation: 
//--------------------------------------------------------------- 
DW8051_core u0 ( 
               .clk (clk), 
               .por_n (por_n), 
               .rst_in_n (rst_in_n), 
               .rst_out_n (rst_out_n), 
               .test_mode_n (test_mode_n), 
               .stop_mode_n (stop_mode_n), 
               .idle_mode_n (idle_mode_n), 
               .sfr_addr (sfr_addr), 
               .sfr_data_out (sfr_data_out), 
               .sfr_data_in (sfr_data_in), 
               .sfr_wr (sfr_wr), 
               .sfr_rd (sfr_rd), 
               .mem_addr (mem_addr), 
               .mem_data_out (mem_data_out), 
               .mem_data_in (mem_data_in), 
               .mem_wr_n (mem_wr_n), 
               .mem_rd_n (mem_rd_n), 
               .mem_pswr_n (mem_pswr_n), 
               .mem_psrd_n (mem_psrd_n), 
               .mem_ale (mem_ale), 
               .mem_ea_n (mem_ea_n),
               .int0_n (int0_n), 
               .int1_n (int1_n), 
               .int2 (int2), 
               .int3_n (int3_n), 
               .int4 (int4), 
               .int5_n (int5_n), 
               .pfi (pfi), 
               .wdti (wdti), 
               .rxd0_in (rxd0_in), 
               .rxd0_out (rxd0_out), 
               .txd0 (txd0), 
               .rxd1_in (rxd1_in), 
               .rxd1_out (rxd1_out), 
               .txd1 (txd1), 
               .t0 (t0), 
               .t1 (t1), 
               .t2 (t2), 
               .t2ex (t2ex), 
               .t0_out (t0_out), 
               .t1_out (t1_out), 
               .t2_out (t2_out), 
               .port_pin_reg_n (port_pin_reg_n), 
               .p0_mem_reg_n (p0_mem_reg_n), 
               .p0_addr_data_n (p0_addr_data_n), 
               .p2_mem_reg_n (p2_mem_reg_n), 
               .iram_addr (iram_addr), 
               .iram_data_out (iram_data_out), 
               .iram_data_in (iram_data_in), 
               .iram_rd_n (), 
               .iram_we1_n (iram_we1_n), 
               .iram_we2_n (iram_we2_n), 
               .irom_addr (irom_addr), 
               .irom_data_out (irom_data_out), 
               .irom_rd_n (irom_rd_n), 
               .irom_cs_n (irom_cs_n) 
               );
  /*                   
   sfr_mem      u1_sfr_mem(
                        .clk(clk),
                        .addr(sfr_addr),     
                        .data_in(sfr_data_out),
                        .data_out(sfr_data_in),
                        .wr_n(~sfr_wr),       
                        .rd_n(~sfr_rd)) ;  
   */     
                   
   int_mem      u3_int_mem(
                        .clk(clk),
                        .addr(iram_addr),
                        .data_in(iram_data_in),
                        .data_out(iram_data_out),
                        .we1_n(iram_we1_n),
                        .we2_n(iram_we2_n),
                        .rd_n(iram_rd_n));  
                        
                                        
   ext_mem      u2_ext_mem(
                        .addr(mem_addr),
                        .data_in(mem_data_out),
                        .data_out(mem_data_in),
                        .wr_n(mem_wr_n),
                        .rd_n(mem_rd_n));    
                        
                          
  rom_mem       u4_rom_mem(
                        .addr(irom_addr),
                        .data_out(irom_data_out),                    
                        .rd_n(irom_rd_n),
                        .cs_n(irom_cs_n));  
//--------------------------------------------------------------- 
// EEPROM Model
//---------------------------------------------------------------                         
 M24AA256 u10(
    .A0(1'b0), 
    .A1(1'b0), 
    .A2(1'b0), 
    .WP(1'b0), 
    .SDA(i2c_sda), 
    .SCL(i2c_scl), 
    .RESET(~rst_in_n)
    );   
                                                         
hw3 u11(
    .rst_in_n(rst_in_n),
    .clk(clk),
    .sfr_wr(sfr_wr),
    .sfr_rd(sfr_rd),
    .sfr_addr(sfr_addr),
    .sfr_data_out(sfr_data_out),
    .sfr_data_in(sfr_data_in),
    .i2c_sda(i2c_sda),
    .i2c_scl(i2c_scl)
);                      
 
initial
  begin
  $monitor("time=%3d memory_000=0x%x memory_001=0x%x",$time,u10.MemoryByte_000[7:0],u10.MemoryByte_001[7:0]);
  end
   
endmodule
