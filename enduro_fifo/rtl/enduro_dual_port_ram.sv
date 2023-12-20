// Dual port RAM model
module enduro_dual_port_ram
    #(parameter DATA_WIDTH           =     32, // Width of the FIFO
                ADDR_WIDTH           =     6,  // Number of address bits
                MEM_DEPTH            =     64, // Memory depth
                DO_INIT              =     1   // An option to initialize memory upon reset (with 0's)
    )			      
    (
    // Globals
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    // Write interface
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [DATA_WIDTH-1:0] wr_data,
    // Read interface 
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
    );

 
    // Memory array
    logic [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0]; 

// Write to the memory
    generate 
      // Initialize memory or not
      if (DO_INIT) begin : init_mem
          always_ff @(posedge wr_clk) begin
            if (~wr_rst_n) begin
	      for (int i=0; i<MEM_DEPTH; i++) begin
		mem[i] <= '0;
	      end
	    end
            else if (wr_en) begin
	      mem[wr_addr] <= wr_data;
	    end
	  end 
      end
      else begin : no_init
	always_ff @(posedge wr_clk) begin
          if (wr_en) begin
	    mem[wr_addr] <= wr_data;
	  end
	end
      end 
    endgenerate

// Read from the memory
assign rd_data = (rd_addr >= MEM_DEPTH) ? '0 : mem[rd_addr];

    
endmodule
