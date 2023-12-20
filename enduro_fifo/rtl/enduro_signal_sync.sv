// Synchronizer for the Gray counter
module enduro_signal_sync #(parameter SLAVE_CLOCK_FASTER = 1) (
        input  logic dst_clk,
        input  logic src_clk,
        input  logic src_reset_n,
        output logic signal_out_synced
    );


logic signal_out_sync_ff1;
logic signal_out_sync_ff2;
logic signal_out_sync_ff3;
logic signal_in_ff1;
logic signal_in_ff2;
logic signal_in_ff3;
logic signal_in_req;

  generate
    if (SLAVE_CLOCK_FASTER == 1) // Slave clock is faster than the master clock
      begin

	// Register for the signal at the output of ths Source domain (a small state machine)
	always_ff @(posedge src_clk) begin
	  if (~src_reset_n) begin
	    signal_in_req <= 1'b0;
	  end
	  else if (~signal_out_sync_ff3) begin
	    signal_in_req <= 1'b1;
	  end
	  else begin
	    signal_in_req <= signal_in_req;
	  end
	end
	

	// Feedback to clear the resiter in the Source domain
	always_ff @(posedge src_clk) begin
	  if (~src_reset_n) begin
	    signal_out_sync_ff1 <= 1'b1;
	    signal_out_sync_ff2 <= 1'b1;
	    signal_out_sync_ff3 <= 1'b1;
	  end
	  else begin
	    signal_out_sync_ff1 <= signal_out_synced;
	    signal_out_sync_ff2 <= signal_out_sync_ff1;
	    signal_out_sync_ff3 <= signal_out_sync_ff2;
	  end
	end

      end

    else     // Slave clock is slower than ot the same as the master clock
      begin

	// Register for the signal at the output of ths Source domain
	always_ff @(posedge src_clk) begin
	  if (~src_reset_n) begin
	    signal_in_req <= 1'b0;
	  end
	  else begin
	    signal_in_req <= 1'b1;
	  end
	end

      end
  endgenerate


// Synchronizing the source signal to the destination clock (there is no reset yet in the Destination domain)
always_ff @(posedge dst_clk) begin
  signal_in_ff1 <= signal_in_req;
  signal_in_ff2 <= signal_in_ff1;
  signal_in_ff3 <= signal_in_ff2;
end


// Syncrhonized signal (reset) for the destination domain
assign signal_out_synced = signal_in_ff3;


endmodule
