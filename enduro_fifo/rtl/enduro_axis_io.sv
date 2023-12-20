// AXI Stream IO and data processing module
module enduro_axis_io
    #(parameter DATA_WIDTH           =     32, // Width of the FIFO
                ADDR_WIDTH           =     6,  // Number of address bits (the depth is derivative)
                SLAVE_CLOCK_FASTER   =     1   // Set to 1 if slave clock is faster
    )
    (    
    // Global interface
    input  logic                        s_axis_clk,
    input  logic                        m_axis_clk,
    input  logic                        s_axis_aresetn,
    output logic                        m_axis_aresetn,

    // AXI4-Stream slave interface
    input  logic [DATA_WIDTH-1:0]       s_axis_tdata,
    input  logic                        s_axis_tvalid,
    output logic                        s_axis_tready,

    // AXI4-Stream master interface
    output logic [DATA_WIDTH-1:0]       m_axis_tdata,
    output logic                        m_axis_tvalid,
    input logic                         m_axis_tready,

    // Increment signals to Write control logic and Read control logic
    output  logic 	                inc_wr_pointer,
    output  logic 	                inc_rd_pointer,

    // Full and empty signals
    input logic                         full_ff,
    input logic                         empty_ff,

    // Almost full and almost empty interface
    input logic                         almost_full_ff,
    input logic                         almost_empty_ff,

    // To the memory
    output logic 	                wr_mem_en,
    output logic [DATA_WIDTH-1:0]       wr_mem_data,
    input logic [DATA_WIDTH-1:0]        rd_mem_data
    );


// Internal signals
logic                  s_axis_tvalid_ff; 
logic [DATA_WIDTH-1:0] s_axis_tdata_ff;
logic                  s_axis_tready_dly_ff; 
logic                  inc_rd_pointer_dly_ff; 
logic                  rd_mem_data_pending; 
//logic                  real_empty_ff; 


//--------------------------------------------------------
// Write domain
//--------------------------------------------------------  

// Input flops for tvalid and tdata
always_ff @(posedge s_axis_clk) begin
  if (~s_axis_aresetn) begin
    s_axis_tvalid_ff <= 1'b0;
    s_axis_tdata_ff <= '0;    
  end
  else begin
    s_axis_tvalid_ff <= s_axis_tvalid;
    s_axis_tdata_ff <= s_axis_tdata;
  end
end  


// Logic for s_axis_tready
always_ff @(posedge s_axis_clk) begin
  if (~s_axis_aresetn) begin
    s_axis_tready <= 1'b0;
  end
  else begin
    s_axis_tready <= ~almost_full_ff; // If almost_full_ff == 1'b1 then s_axis_tready <= 1'b0, but if almost_full_ff == 1'b0 then s_axis_tready <= 1'b1
  end
end


// tready once cycle delay (to understand its value during the primary input s_axis_tvalid value)
always_ff @(posedge s_axis_clk) begin
  if (~s_axis_aresetn) begin
    s_axis_tready_dly_ff <= 1'b0;
  end
  else begin
    s_axis_tready_dly_ff <= s_axis_tready;
  end
end


// Generation of the increment to the FIFO Write control logic
assign inc_wr_pointer = (s_axis_tvalid_ff & s_axis_tready_dly_ff);

assign wr_mem_data = s_axis_tdata_ff;
assign wr_mem_en = (inc_wr_pointer & ~full_ff);
// Delay 1 cycle flops for write enable and data to the memory since there is one clock cycle delay of generating wr_mem_addr in FIFO Controller module
/*always_ff @(posedge s_axis_clk) begin
  if (~s_axis_aresetn) begin
    wr_mem_data <= '0;    
    wr_mem_en <= 1'b0;
  end
  else begin
    wr_mem_data <= s_axis_tdata_ff;
    wr_mem_en <= (inc_wr_pointer & ~full_ff);
  end
end*/


//--------------------------------------------------------
// Read domain
//--------------------------------------------------------

// AXI4-Stream master data
always_ff @(posedge m_axis_clk) begin
  if (~m_axis_aresetn) begin
    m_axis_tdata <= '0;
    inc_rd_pointer_dly_ff <= 1'b0;
  end
  else begin
    m_axis_tdata <= rd_mem_data;
    inc_rd_pointer_dly_ff <= inc_rd_pointer;
  end
end


always_ff @(posedge m_axis_clk) begin
  if (~m_axis_aresetn) begin
    rd_mem_data_pending <= 1'b0;
  end
  else if (inc_rd_pointer | inc_rd_pointer_dly_ff) begin
    rd_mem_data_pending <= 1'b1;
  end
  else begin
    rd_mem_data_pending <= 1'b0;
  end
end


// AXI4-Stream master
assign m_axis_tvalid = (~empty_ff & ~rd_mem_data_pending);
//assign m_axis_tvalid = (~real_empty_ff & ~rd_mem_data_pending);

/*
// Small state machine for real empty signal, which needs to gate m_axis_tvalid (since we need to pop the latest written transaction from the FIFO memory)
always_ff @(posedge m_axis_clk) begin
  if (~m_axis_aresetn) begin
    real_empty_ff <= 1'b1;
  end
  else if (inc_rd_pointer & empty_ff) begin
    real_empty_ff <= 1'b1;
  end
  else if (~empty_ff) begin
    real_empty_ff <= 1'b0;
  end
  else begin
    real_empty_ff <= real_empty_ff;
  end
end*/


// Increment signal to the read pointer in FIFO control logic
assign inc_rd_pointer = (m_axis_tvalid & m_axis_tready);


// Synchronizer of reset signal to m_axis_clk clock domain
enduro_signal_sync #(
    .SLAVE_CLOCK_FASTER (SLAVE_CLOCK_FASTER)
)
u_enduro_signal_sync_resetn (
    .dst_clk           (m_axis_clk),      
    .src_clk           (s_axis_clk),      
    .src_reset_n       (s_axis_aresetn),
    .signal_out_synced (m_axis_aresetn)
);
  
  
endmodule
