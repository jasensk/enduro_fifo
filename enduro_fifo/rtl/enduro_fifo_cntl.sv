// FIFO Controller
module enduro_fifo_cntl
    #(parameter DATA_WIDTH           =     32, // Width of the FIFO
                ADDR_WIDTH           =     6,  // Number of address bits (the depth is derivative)
                FULL_THRESH          =     0,  // Defines the full threshold
                EMPTY_THRESH         =     0   // Defines the empty threshold
    )
    (    
    // Global interface
    input  logic                        s_axis_clk,
    input  logic                        m_axis_clk,
    input  logic                        m_axis_aresetn,
    input  logic                        s_axis_aresetn,

    // Increment signals to Write control logic and Read control logic
    input  logic 	                inc_wr_pointer,
    input  logic 	                inc_rd_pointer,

    // Full and empty signals
    output logic                        full_ff,
    output logic                        empty_ff,

    // Almost full and almost empty interface
//    input  logic [ADDR_WIDTH-1:0]       full_threshold,
//    input  logic [ADDR_WIDTH-1:0]       empty_threshold,
    output logic                        almost_full_ff,
    output logic                        almost_empty_ff,

    // To the memory
    output logic [ADDR_WIDTH-1:0]       wr_mem_addr,
    output logic [ADDR_WIDTH-1:0]       rd_mem_addr
    );


// Internal signals
logic                  wr_pointer_real_inc_w; 
logic [ADDR_WIDTH:0]   wr_pointer_bin_ff;
logic [ADDR_WIDTH:0]   wr_pointer_gray_w;
logic [ADDR_WIDTH:0]   wr_pointer_bin_w; 
logic [ADDR_WIDTH:0]   wr_pointer_gray_ff;
logic [ADDR_WIDTH:0]   wr_pointer_gray_synced; 
logic [ADDR_WIDTH:0]   wr_pointer_bin_synced_w; 
logic [ADDR_WIDTH-1:0] queue_diff_wr_w;           // Pointer diff in the write domain
logic 	               full_w; 
logic                  almost_full_w;
logic                  rd_pointer_real_inc_w; 
logic [ADDR_WIDTH:0]   rd_pointer_gray_synced; 
logic [ADDR_WIDTH:0]   rd_pointer_bin_synced_w; 
logic [ADDR_WIDTH:0]   rd_pointer_bin_ff;
logic [ADDR_WIDTH:0]   rd_pointer_gray_w;
logic [ADDR_WIDTH:0]   rd_pointer_bin_w; 
logic [ADDR_WIDTH:0]   rd_pointer_gray_ff;
logic [ADDR_WIDTH-1:0] queue_diff_rd_w;           // Pointer diff in the read domain
logic 	               empty_w; 
logic                  almost_empty_w; 

//--------------------------------------------------------
// Write control logic
//--------------------------------------------------------  

// *** Combinational logic for the Write pointers

// Qualifying the write increment with ~full
assign wr_pointer_real_inc_w = (inc_wr_pointer & ~full_ff);  

// Adder for the write increment
assign wr_pointer_bin_w = (wr_pointer_bin_ff + {{(ADDR_WIDTH-1){1'b0}}, wr_pointer_real_inc_w});

// Convert write binary counter to write grey counter
assign wr_pointer_gray_w = ((wr_pointer_bin_w >> 1) ^ wr_pointer_bin_w);


// Sequential logic for the Write pointers
always_ff @(posedge s_axis_clk) begin
  if (~s_axis_aresetn) begin
    wr_pointer_bin_ff <= '0;
    wr_pointer_gray_ff <= '0;    
  end
  else begin
    wr_pointer_bin_ff <= wr_pointer_bin_w;
    wr_pointer_gray_ff <= wr_pointer_gray_w;
  end
end
  

// Combinational logic for generation of the full signal
assign full_w = ((wr_pointer_gray_w[ADDR_WIDTH] != rd_pointer_gray_synced[ADDR_WIDTH]) && (wr_pointer_gray_w[ADDR_WIDTH-1] != rd_pointer_gray_synced[ADDR_WIDTH-1]) && (wr_pointer_gray_w[ADDR_WIDTH-2:0] == rd_pointer_gray_synced[ADDR_WIDTH-2:0]));


// *** Combinational logic for almost full indication

// Gray to binary conversion of the synced read pointer
   genvar i;
    generate 
      for (i = 0; i <= ADDR_WIDTH; i = i + 1)               
	begin : gray_to_binary_read_pointer
          assign rd_pointer_bin_synced_w[i] = ^(rd_pointer_gray_synced >> i);
        end                                          
    endgenerate

//  Calculate queue pointer difference for write domain
//assign  queue_diff_wr_w = (wr_pointer_bin_w[ADDR_WIDTH-1:0] >= rd_pointer_bin_synced_w[ADDR_WIDTH-1:0]) ? (wr_pointer_bin_w[ADDR_WIDTH-1:0] - rd_pointer_bin_synced_w[ADDR_WIDTH-1:0]) : ((FIFO_DEPTH - rd_pointer_bin_synced_w[ADDR_WIDTH-1:0]) + wr_pointer_bin_w[ADDR_WIDTH-1:0]);
assign  queue_diff_wr_w = (wr_pointer_bin_w - rd_pointer_bin_synced_w); // Since it is guaranteed by design that wr_pointer_bin_w[ADDR_WIDTH:0] is >= compared to rd_pointer_bin_synced_w[ADDR_WIDTH:0]

// Almost full flag is active when the FIFO is above the threshold. Adjust threshold by 1 in the case of registered output            
assign  almost_full_w = (queue_diff_wr_w >= FULL_THRESH[ADDR_WIDTH-1:0]);


// Sequential logic for the full signal
always_ff @(posedge s_axis_clk) begin
  if (~s_axis_aresetn) begin
    full_ff <= 1'b0;
    almost_full_ff <= 1'b0;
  end
  else begin
    full_ff <= full_w;
    almost_full_ff <= almost_full_w;
  end
end


// Synchronizer of the read gray counter to the write logic
enduro_counter_sync #(
    .BW              (ADDR_WIDTH+1)
)
u_enduro_counter_sync_s_axis_clk (
    .clk             (s_axis_clk),      
    .reset_n         (s_axis_aresetn),
    .data_in         (rd_pointer_gray_ff),
    .data_out_synced (rd_pointer_gray_synced)
);

  
//--------------------------------------------------------
// Read control logic
//--------------------------------------------------------

// --- Combinational logic for the Read pointers

// Qualifying the write increment with ~empty
assign rd_pointer_real_inc_w = (inc_rd_pointer & ~empty_ff);

// Adder for the read increment
assign rd_pointer_bin_w = (rd_pointer_bin_ff + {{(ADDR_WIDTH-1){1'b0}}, rd_pointer_real_inc_w});

// Convert read binary counter to read grey counter
assign rd_pointer_gray_w = ((rd_pointer_bin_w >> 1) ^ rd_pointer_bin_w);

  
// Sequential logic for the Read pointers  
always_ff @(posedge m_axis_clk) begin
  if (~m_axis_aresetn) begin
    rd_pointer_bin_ff <= '0;
    rd_pointer_gray_ff <= '0;
  end
  else begin
    rd_pointer_bin_ff <= rd_pointer_bin_w;
    rd_pointer_gray_ff <= rd_pointer_gray_w;
  end
end

  
// Combination logic for generation of the empty signal
assign empty_w = (rd_pointer_gray_w == wr_pointer_gray_synced);

// *** Combinational logic for almost empty indication

// Gray to binary conversion of the synced write pointer
   genvar j;
    generate 
      for (j = 0; j <= ADDR_WIDTH; j = j + 1)               
	begin : gray_to_binary_write_pointer
          assign wr_pointer_bin_synced_w[j] = ^(wr_pointer_gray_synced >> j);
        end                                          
    endgenerate

//  Calculate queue pointer difference for the read domain
//assign  queue_diff_rd_w = (wr_pointer_bin_synced_w[ADDR_WIDTH-1:0] >= rd_pointer_bin_w[ADDR_WIDTH-1:0]) ? (wr_pointer_bin_synced_w[ADDR_WIDTH-1:0] - rd_pointer_bin_w[ADDR_WIDTH-1:0]) : ((FIFO_DEPTH - rd_pointer_bin_w[ADDR_WIDTH-1:0]) + wr_pointer_bin_synced_w[ADDR_WIDTH-1:0]);
assign  queue_diff_rd_w = (wr_pointer_bin_synced_w - rd_pointer_bin_w); // Since it is guaranteed by design that wr_pointer_bin_synced_w[ADDR_WIDTH:0] is >= compared to rd_pointer_bin_w[ADDR_WIDTH:0]

// Almost empty flag is active when the FIFO is below the threshold.
assign  almost_empty_w = (EMPTY_THRESH[ADDR_WIDTH-1:0] > queue_diff_rd_w);
  

// Sequential logic for the empty signal
always_ff @(posedge m_axis_clk) begin
  if (~m_axis_aresetn) begin
    empty_ff <= 1'b1;
    almost_empty_ff <= 1'b1;
  end
  else begin
    empty_ff <= empty_w;
    almost_empty_ff <= almost_empty_w;
  end
end


// Synchronizer of the read gray counter to the write logic
enduro_counter_sync #(
    .BW              (ADDR_WIDTH+1)
)
u_enduro_counter_sync_m_axis_clk (
    .clk             (m_axis_clk),      
    .reset_n         (m_axis_aresetn),
    .data_in         (wr_pointer_gray_ff),
    .data_out_synced (wr_pointer_gray_synced)
);

  
//--------------------------------------------------------
// Interfaces to the memory
//--------------------------------------------------------
  
// Write address to the memory
assign wr_mem_addr = wr_pointer_bin_ff[ADDR_WIDTH-1:0];


// Read address to the memory
assign rd_mem_addr = rd_pointer_bin_ff[ADDR_WIDTH-1:0];
  
  
endmodule
