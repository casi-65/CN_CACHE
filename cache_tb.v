
`timescale 1ns / 1ps
module cache_tb;

  reg clk, rst;
  reg read, write;
  reg cache_ready, MM_ready;
  reg [31:0] address;
  reg [63:0] write_data;
  wire [63:0] read_data;
  wire hit, miss;
  wire [3:0] state_out;
  
  integer hit_count     = 0;
  integer miss_count    = 0;
  integer access_count  = 0;
  integer total_cycles_time;
  integer AMAT_x1000;

  cache_controller uut (
    .clk(clk),
    .rst(rst),
    .read(read),
    .write(write),
    .cache_ready(cache_ready),
    .MM_ready(MM_ready),
    .address(address),
    .write_data(write_data),
    .read_data(read_data),
    .hit(hit),
    .miss(miss),
    .state_out(state_out)
  );

  always #5 clk = ~clk;

  localparam INDEX = 7'd15;
  localparam TAG_HIT = 19'h1A1A1;
  localparam TAG_MISS = 19'h2B2B2;

  localparam DATA1 = 64'hAAAABBBBCCCCDDDD;
  localparam DATA2 = 64'h1111222233334444;
  
  task restart_cache();
    begin
      rst = 1;
      #10;
      rst = 0;
      #10;
    end
  endtask
  
  always @(posedge clk) begin
  if (hit) begin
    hit_count = hit_count + 1;
    access_count = access_count + 1;
  end else if (miss) begin
    miss_count = miss_count + 1;
    access_count = access_count + 1;
  end
end
  
  initial begin
    $display("=== Testbench: All Hit/Miss Combinations ===");

    clk = 0;
    read = 0; 
    write = 0;
    address = 0; 
    write_data = 0;
    cache_ready = 0; 
    MM_ready = 0;

    #10;
    
    restart_cache();

    //-----------------------------------------------------------------
    // 1. READ HIT (way0)
    //-----------------------------------------------------------------
    $display("\n[1] READ HIT (way0)");
    uut.valid1[INDEX] = 1;
    uut.tag1[INDEX] = TAG_HIT;
    uut.data1[INDEX] = DATA1;

    address = {TAG_HIT, INDEX, 6'b0};
    read = 1; cache_ready = 1;

    #50;
    read = 0;

    if (hit && !miss && read_data == DATA1)
      $display(" READ_HIT PASSED");
    else
      $display(" READ_HIT FAILED! hit=%b miss=%b read_data=%h", hit, miss, read_data);
     
     #20; 
      
     restart_cache();

    //-----------------------------------------------------------------
    // 2. WRITE HIT (way0)
    //-----------------------------------------------------------------
    $display("\n[2] WRITE HIT (way0)");
    address = {TAG_HIT, INDEX, 6'b0};
    uut.valid1[INDEX] = 1;
    uut.tag1[INDEX] = TAG_HIT;
    uut.data1[INDEX] = DATA1;
    write_data = DATA2; write = 1;

    #50;
    write = 0;
    #20;
    if (hit && !miss && uut.data1[INDEX] == DATA2)
      $display(" WRITE_HIT PASSED");
    else
      $display(" WRITE_HIT FAILED! hit=%b miss=%b data1=%h", hit, miss, uut.data1[INDEX]);
      
       restart_cache();

    //-----------------------------------------------------------------
    // 3. READ MISS (way1 invalid)
    //-----------------------------------------------------------------
    $display("\n[3] READ MISS (way1 invalid)");
    uut.valid2[INDEX] = 0;
    address = {TAG_MISS, INDEX, 6'b0};
    read = 1; MM_ready = 1;

    #100;
    read = 0;

    if (!hit && miss)
      $display(" READ_MISS PASSED");
    else
      $display(" READ_MISS FAILED! hit=%b miss=%b", hit, miss);
      

      restart_cache();

    //-----------------------------------------------------------------
    // 4. WRITE MISS (way1 invalid)
    //-----------------------------------------------------------------
    $display("\n[4] WRITE MISS (way1 invalid)");
    write_data = DATA1;
    write = 1;
    uut.valid2[INDEX] = 0;
    address = {TAG_MISS, INDEX, 6'b0};

    #100;
    write = 0;

    if (!hit && miss)
      $display(" WRITE_MISS PASSED");
    else
      $display(" WRITE_MISS FAILED! hit=%b miss=%b dirty2=%b", hit, miss, uut.dirty2[INDEX]);
      
       restart_cache();

    //-----------------------------------------------------------------
    // 5. WRITE MISS (way3 dirty WRITE_BACK)
    //-----------------------------------------------------------------
    $display("\n[5] WRITE MISS (dirty way3 WRITE_BACK)");
    uut.valid1[INDEX] = 1;
    uut.valid2[INDEX] = 1;
    uut.valid3[INDEX] = 1;
    uut.valid4[INDEX] = 1;
    uut.LRU3[INDEX] = 3;
    uut.dirty3[INDEX] = 1;
    uut.tag3[INDEX] = 19'hDEAD1;
    address = {TAG_MISS, INDEX, 6'b0};
    write = 1;

    #100;
    write = 0;

    if (!hit && miss && uut.tag3[INDEX] == TAG_MISS && uut.dirty3[INDEX] == 1)
  $display(" WRITE_BACK on WRITE_MISS PASSED");
else
  $display(" WRITE_BACK on WRITE_MISS FAILED! tag3=%h dirty3=%b", uut.tag3[INDEX], uut.dirty3[INDEX]);
      
       restart_cache();

    //-----------------------------------------------------------------
    // 6. READ MISS (way4 dirty  WRITE_BACK)
    //-----------------------------------------------------------------
    $display("\n[6] READ MISS (dirty way4 WRITE_BACK)");
    uut.valid1[INDEX] = 1;
    uut.valid2[INDEX] = 1;
    uut.valid3[INDEX] = 1;
    uut.valid4[INDEX] = 1;
    uut.LRU4[INDEX] = 3;
    uut.dirty4[INDEX] = 1;
    uut.tag4[INDEX] = 19'hFACE1;
    address = {TAG_MISS + 1, INDEX, 6'b0};
    read = 1;

    #100;
    read = 0;

    if (!hit && miss && uut.tag4[INDEX] == TAG_MISS+1 && uut.dirty4[INDEX] == 0)
  $display(" WRITE_BACK on WRITE_MISS PASSED");
else
  $display(" WRITE_BACK on WRITE_MISS FAILED! tag4=%h dirty4=%b", uut.tag4[INDEX], uut.dirty4[INDEX]);

    //-----------------------------------------------------------------
    
    total_cycles_time = hit_count/10 * 1 + miss_count/10 * 100;
    AMAT_x1000 = (access_count/10 != 0) ? (total_cycles_time * 1000) / access_count/10 : 0;
    $display("\n=== PERFORMANCE METRICS ===");
    $display("Total accesses: %0d", access_count/10);
    $display("Hits: %0d", hit_count/10);
    $display("Misses: %0d", miss_count/10);
    $display("AMAT: %0d.%03d cycles", AMAT_x1000 / 1000, AMAT_x1000 % 1000);
    
    $stop;
  end

endmodule
