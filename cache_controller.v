module cache_controller(
  input clk,rst,
  input read,
  input write,
  input cache_ready,
  input MM_ready,
  input [31:0]address,
  input [64:0]write_data,
  output reg [63:0] read_data,
  output reg hit,
  output reg miss
);

  localparam CACHE_SIZE = 32 * 1024;    
  localparam BLOCK_SIZE = 64;            
  localparam SETS = 128;           
  localparam ASSOCIATIVITY = 4;          
	localparam TAG= 19;
	
	localparam IDLE = 0,
	         WAIT_CACHE_READY = 1,
	         TAG_CHECK = 2,
	         VALID = 3,
           READ_HIT = 4,
           WRITE_HIT = 5,
           UPDATE_LRU = 6,
           DONE = 7,
           MISS_SELECT = 8,
           WAIT_READY_MM = 9,
           WRITE_BACK = 10,
           ALLOCATE = 11,
           READ_ALLOC = 12,
           WRITE_ALLOC = 13;
	reg [3:0] curr_state;
	reg [3:0] next_state;
	
	// WAY 1 cache data
  reg		valid1 [0: SETS-1];
  reg [TAG-1:0] tag1 [0: SETS-1];
  reg	[BLOCK_SIZE-1:0] data1 [0: SETS-1];
  reg		dirty1 [0: SETS-1];
  reg [1:0] LRU1 [0: SETS-1];
  
  // WAY 2 cache data
  reg		valid2 [0: SETS-1];
  reg [TAG-1:0] tag2 [0: SETS-1];
  reg	[BLOCK_SIZE-1:0] data2 [0: SETS-1];
  reg		dirty2 [0: SETS-1];
  reg [1:0] LRU2 [0: SETS-1];
  
  // WAY 3 cache data
  reg		valid3 [0: SETS-1];
  reg [TAG-1:0] tag3 [0: SETS-1];
  reg	[BLOCK_SIZE-1:0] data3 [0: SETS-1];
  reg		dirty3 [0: SETS-1];
  reg [1:0] LRU3 [0: SETS-1];
  
  // WAY 4 cache data
  reg		valid4 [0: SETS-1];
  reg [TAG-1:0] tag4 [0: SETS-1];
  reg	[BLOCK_SIZE-1:0] data4 [0: SETS-1];
  reg		dirty4 [0: SETS-1];
  reg [1:0] LRU4 [0: SETS-1];
  
  integer i;
  initial begin
	for(i = 0; i < SETS; i = i +1)
	 begin
		valid1[i] = 0;
		valid2[i] = 0;
		valid3[i] = 0;
		valid4[i] = 0;
		dirty1[i] = 0;
		dirty2[i] = 0;
		dirty3[i] = 0;
		dirty4[i] = 0;
		LRU1[i] = 2'b00;
		LRU2[i] = 2'b00;
		LRU3[i] = 2'b00;
		LRU4[i] = 2'b00;
	 end
  end
  
  initial begin
	 read_data=0;
  end
  
  reg [1:0] hit_way;
  reg [1:0] way_used;

  
  wire [3:0] offsetW;
  wire [5:0] offsetB;  
  wire [6:0] index;   
  wire [16:0] tag;    
  reg [3:0] selected_way;
  assign offsetW = address[1:0];
  assign offsetB = address[5:2];
  assign index  = address[12:6];
  assign tag    = address[31:13];
  
  always @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state <= IDLE;      
        end else begin
            curr_state <= next_state;
        end
    end

    always @(*) begin
        case (curr_state)
            IDLE: begin
                if (read) begin
                  next_state = WAIT_CACHE_READY;
                end else if (write) begin
                  next_state = WAIT_CACHE_READY;
                end else begin
                  next_state = IDLE;
                end
            end
            WAIT_CACHE_READY: begin
                if (cache_ready == 1'b1) begin
                  next_state = VALID;
                end else begin
                  next_state = WAIT_CACHE_READY;
                end
            end
            VALID: begin
                if((valid1[index]) ||
                   (valid2[index]) ||
                   (valid3[index]) ||
                   (valid4[index])) begin
                  next_state = TAG_CHECK;
                end else begin
                  next_state = MISS_SELECT; 
                end
            end
            TAG_CHECK: begin
              if (valid1[index] && tag1[index] == tag) begin
               hit_way = 2'd1;
               next_state = read ? READ_HIT : WRITE_HIT;
              end else if (valid2[index] && tag2[index] == tag) begin
                hit_way = 2'd2;
                next_state = read ? READ_HIT : WRITE_HIT;
              end else if (valid3[index] && tag3[index] == tag) begin
                hit_way = 2'd3;
                next_state = read ? READ_HIT : WRITE_HIT;
              end else if (valid4[index] && tag4[index] == tag) begin
                hit_way = 2'd4;
                next_state = read ? READ_HIT : WRITE_HIT;
              end else begin
                next_state = MISS_SELECT;
              end
            end
            READ_HIT: begin
              case (hit_way)
                 1: read_data = 
                 2: read_data = 
                 3: read_data = 
                 4: read_data = 
              endcase
              hit  = 1;
              miss = 0;
              next_state = UPDATE_LRU;
            end
            WRITE_HIT: begin
                case (hit_way)
                  1: begin
                    data1[][] = write_data[63:0];
                    dirty1[index] = 1;
                  end
                  2: begin
                    data2[][] = write_data[63:0];
                    dirty2[index] = 1;
                  end
                  3: begin
                    data3[][o] = write_data[63:0];
                    dirty3[index] = 1;
                  end
                  4: begin
                    data4[][] = write_data[63:0];
                    dirty4[index] = 1;
                  end
                endcase
                hit  = 1;
                miss = 0;
                next_state = UPDATE_LRU;
            end
            UPDATE_LRU: begin
                case (curr_state)
                  READ_HIT, WRITE_HIT: way_used = hit_way;
                  default: way_used = selected_way;
                endcase
                case (way_used)
                  1: begin
                    if (LRU2[index] < LRU1[index]) LRU2[index] = LRU2[index] + 1;
                    if (LRU3[index] < LRU1[index]) LRU3[index] = LRU3[index] + 1;
                    if (LRU4[index] < LRU1[index]) LRU4[index] = LRU4[index] + 1;
                    LRU1[index] = 0;
                  end
                  2: begin
                    if (LRU1[index] < LRU2[index]) LRU1[index] = LRU1[index] + 1;
                    if (LRU3[index] < LRU2[index]) LRU3[index] = LRU3[index] + 1;
                    if (LRU4[index] < LRU2[index]) LRU4[index] = LRU4[index] + 1;
                    LRU2[index] = 0;
                  end
                  3: begin
                    if (LRU1[index] < LRU3[index]) LRU1[index] = LRU1[index] + 1;
                    if (LRU2[index] < LRU3[index]) LRU2[index] = LRU2[index] + 1;
                    if (LRU4[index] < LRU3[index]) LRU4[index] = LRU4[index] + 1;
                    LRU3[index] = 0;
                  end
                  4: begin
                    if (LRU1[index] < LRU4[index]) LRU1[index] = LRU1[index] + 1;
                    if (LRU2[index] < LRU4[index]) LRU2[index] = LRU2[index] + 1;
                    if (LRU3[index] < LRU4[index]) LRU3[index] = LRU3[index] + 1;
                    LRU4[index] = 0;
                  end
                endcase
                next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
            MISS_SELECT: begin
              if (!valid1[index]) selected_way = 4'd1;
              else if (!valid2[index]) selected_way = 4'd2;
              else if (!valid3[index]) selected_way = 4'd3;
              else if (!valid4[index]) selected_way = 4'd4;
              else begin
              if (LRU1[index] == 2'd3) selected_way = 4'd1;
              else if (LRU2[index] == 2'd3) selected_way = 4'd2;
              else if (LRU3[index] == 2'd3) selected_way = 4'd3;
              else                          selected_way = 4'd4;
              end
            end
            DIRTY_CHECK: begin
                case (selected_way)
                   1: next_state = dirty1[index] ? WAIT_READY_MM : ALLOCATE;
                   2: next_state = dirty2[index] ? WAIT_READY_MM : ALLOCATE;
                   3: next_state = dirty3[index] ? WAIT_READY_MM : ALLOCATE;
                   4: next_state = dirty4[index] ? WAIT_READY_MM : ALLOCATE;
                default: next_state = ALLOCATE;
                endcase
            end
            WAIT_READY_MM: begin
                if (MM_ready == 1'b1) begin
                  next_state = WRITE_BACK;
                end else begin
                  next_state = WAIT_READY_MM;
                end
            end
            WRITE_BACK: begin
              //de implementat
            end
            ALLOCATE: begin
              case (selected_way)
                0: begin
                tag1[index]   <= tag;
                valid1[index] <= 1;
                dirty1[index] <= 0;
                //trebuie sa actualizez data
              end
                1: begin
                tag2[index]   <= tag;
                valid2[index] <= 1;
                dirty2[index] <= 0;
                
              end
                2: begin
                tag3[index]   <= tag;
                valid3[index] <= 1;
                dirty3[index] <= 0;
                
              end
                3: begin
                tag4[index]   <= tag;
                valid4[index] <= 1;
                dirty4[index] <= 0;
                
              end
            endcase
            if (read)
              next_state = READ_ALLOC;
            else if (write)
              next_state = WRITE_ALLOC;
            else
              next_state = DONE;
            end
            READ_ALLOC: begin
                case (selected_way)
                  1: read_data =  
                  2: read_data =
                  3: read_data = 
                  4: read_data = 
                endcase
                next_state = UPDATE_LRU;
            end
            WRITE_ALLOC: begin
              case (selected_way)
                0: begin
                  //trebuie sa actualizez data
                  dirty1[index] = 1;
                end
                1: begin
            
                  dirty2[index] = 1;
                end
                2: begin
               
                  dirty3[index] = 1;
                end
                3: begin
                  
                  dirty4[index] = 1;
                end
              endcase
              next_state = UPDATE_LRU;
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
