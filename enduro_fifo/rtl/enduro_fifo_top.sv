// FIFO top level module
module enduro_fifo_top
    #(parameter DATA_WIDTH           =     32, // Width of the FIFO
                ADDR_WIDTH           =     6,  // Number of address bits (the depth is derivative)
                FULL_THRESH          =     60, // Defines the full threshold
                EMPTY_THRESH         =     2,  // Defines the empty threshold
                SLAVE_CLOCK_FASTER   =     1   // Set to 1 if slave clock is faster
    )
    ( 
    // Global interface
    input  logic                        s_axis_clk,
    input  logic                        m_axis_clk,
    input  logic                        s_axis_aresetn,
    // AXI4-Stream slave interface
    input  logic [DATA_WIDTH-1:0]       s_axis_tdata,
    input  logic                        s_axis_tvalid,
    output logic                        s_axis_tready,
    // AXI4-Stream master interface
    output logic [DATA_WIDTH-1:0]       m_axis_tdata,
    output logic                        m_axis_tvalid,
    input logic                         m_axis_tready
    );

localparam [ADDR_WIDTH:0] FIFO_DEPTH = (1'b1 << ADDR_WIDTH);

// Internal Signals
logic                       m_axis_aresetn;
logic                       full_ff; 
logic                       empty_ff; 
logic                       almost_full_ff;
logic                       almost_empty_ff;
logic 	                    inc_wr_pointer;
logic 	                    inc_rd_pointer;
logic                       wr_mem_en; 
logic [ADDR_WIDTH-1:0]      wr_mem_addr;
logic [ADDR_WIDTH-1:0]      rd_mem_addr;
logic [DATA_WIDTH-1:0]      wr_mem_data;
logic [DATA_WIDTH-1:0]      rd_mem_data;


//--------------------------------------------------------
// FIFO IO module
//--------------------------------------------------------
enduro_axis_io #(
    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),
    .SLAVE_CLOCK_FASTER (SLAVE_CLOCK_FASTER)
)
u_enduro_axis_io (    
    // Global interface
    .s_axis_clk         (s_axis_clk),
    .m_axis_clk         (m_axis_clk),
    .m_axis_aresetn     (m_axis_aresetn),
    .s_axis_aresetn     (s_axis_aresetn),
     // AXI4-Stream slave interface
    .s_axis_tdata       (s_axis_tdata),
    .s_axis_tvalid      (s_axis_tvalid),
    .s_axis_tready      (s_axis_tready),
    // AXI4-Stream master interface
    .m_axis_tdata       (m_axis_tdata),
    .m_axis_tvalid      (m_axis_tvalid),
    .m_axis_tready      (m_axis_tready),
    // Increment signals to Write control logic and Read control logic
    .inc_wr_pointer     (inc_wr_pointer),
    .inc_rd_pointer     (inc_rd_pointer),
    // Full and empty signals
    .full_ff            (full_ff),
    .empty_ff           (empty_ff),
    // Almost full and almost empty interface
    .almost_full_ff     (almost_full_ff),
    .almost_empty_ff    (almost_empty_ff),
    // To the memory
    .wr_mem_en          (wr_mem_en),
    .wr_mem_data        (wr_mem_data),
    .rd_mem_data        (rd_mem_data)
);


//--------------------------------------------------------
// FIFO Controller
//--------------------------------------------------------
enduro_fifo_cntl #(
    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),
    .FULL_THRESH        (FULL_THRESH),
    .EMPTY_THRESH       (EMPTY_THRESH)
)
u_enduro_fifo_cntl (    
    // Global interface
    .s_axis_clk         (s_axis_clk),
    .m_axis_clk         (m_axis_clk),
    .m_axis_aresetn     (m_axis_aresetn),
    .s_axis_aresetn     (s_axis_aresetn),
    // Increment signals to Write control logic and Read control logic
    .inc_wr_pointer     (inc_wr_pointer),
    .inc_rd_pointer     (inc_rd_pointer),
    // Full and empty signals
    .full_ff            (full_ff),
    .empty_ff           (empty_ff),
    // Almost full and almost empty interface
    .almost_full_ff     (almost_full_ff),
    .almost_empty_ff    (almost_empty_ff),
    // To the memory
    .wr_mem_addr        (wr_mem_addr),
    .rd_mem_addr        (rd_mem_addr)
);
	 

//--------------------------------------------------------
// Soft dual port memory
//--------------------------------------------------------
enduro_dual_port_ram #(
    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),
    .MEM_DEPTH          (FIFO_DEPTH),
    .DO_INIT            (1)
)			      
u_enduro_dual_port_ram (
    // Globals
    .wr_clk             (s_axis_clk),
    .wr_rst_n           (s_axis_aresetn),
    // Write interface
    .wr_en              (wr_mem_en),
    .wr_addr            (wr_mem_addr),
    .wr_data            (wr_mem_data),
    // Read interface 
    .rd_addr            (rd_mem_addr),
    .rd_data            (rd_mem_data)
);

  
endmodule
