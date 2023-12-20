// Simple testbench for initial very basic verification

module enduro_fifo_testbench;

  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 6;
  parameter FULL_THRESH = 60;
  parameter EMPTY_THRESH = 2;
  parameter SLAVE_CLOCK_FASTER = 1;


  logic s_axis_clk;
  logic m_axis_clk;
  logic s_axis_aresetn;
  logic m_axis_tvalid;
  logic m_axis_tready;
  logic [DATA_WIDTH-1:0] m_axis_tdata;
  logic s_axis_tvalid;
  logic s_axis_tready;
  logic [DATA_WIDTH-1:0] s_axis_tdata;

  // Verification queue for data check
  logic [DATA_WIDTH-1:0] verification_queue[$];
  logic [DATA_WIDTH-1:0] verification_queue_wdata;


  // FIFO top level module instance
  enduro_fifo_top #(
    .DATA_WIDTH         (DATA_WIDTH),
    .ADDR_WIDTH         (ADDR_WIDTH),
    .FULL_THRESH        (FULL_THRESH),
    .EMPTY_THRESH       (EMPTY_THRESH),
    .SLAVE_CLOCK_FASTER (SLAVE_CLOCK_FASTER)
) 
  dut (.*);

// Globals
  initial begin
    s_axis_clk = 1'b0;
    m_axis_clk = 1'b0;

    fork
      forever #2ns s_axis_clk = ~s_axis_clk;
      forever #2.5ns m_axis_clk = ~m_axis_clk;
    join
  end


// AXI4-Stream slave interface driver
  initial begin
    s_axis_tvalid = 1'b0;
    s_axis_tdata = '0;
    s_axis_aresetn = 1'b1;
    repeat(7) @(posedge s_axis_clk);
    s_axis_aresetn = 1'b0;
    repeat(7) @(posedge s_axis_clk);
    s_axis_aresetn = 1'b1;

    for (int iter=0; iter<3; iter++) begin
      for (int i=0; i<(32*3); i++) begin
        @(posedge s_axis_clk);
        s_axis_tvalid = (i%2 == 0)? 1'b1 : 1'b0;
        if (s_axis_tvalid && s_axis_tready) begin
          s_axis_tdata = $urandom;
          verification_queue.push_front(s_axis_tdata);
        end
      end
      #2us;
    end
  end


// AXI4-Stream master interface driver and checker
  initial begin
    m_axis_tready = 1'b0;
    repeat(10) @(posedge m_axis_clk);

    for (int iter=0; iter<3; iter++) begin
      for (int i=0; i<(32*8); i++) begin
        @(posedge m_axis_clk)
        m_axis_tready = (i%2 == 0)? 1'b1 : 1'b0;
		#1;
        if (m_axis_tready && m_axis_tvalid) begin
          verification_queue_wdata = verification_queue.pop_back();
          // Check the m_axis_tdata against modeled verification queue data
          $display("Checking m_axis_tdata: expected verification_queue_wdata = %h, m_axis_tdata = %h", verification_queue_wdata, m_axis_tdata);
          assert(m_axis_tdata === verification_queue_wdata) else $error("Checking failed: expected verification_queue_wdata = %h, m_axis_tdata = %h", verification_queue_wdata, m_axis_tdata);
        end
      end
      #2us;
    end

    $finish;
  end

endmodule
