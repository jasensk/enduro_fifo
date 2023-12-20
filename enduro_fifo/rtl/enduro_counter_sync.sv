// Synchronizer for the Gray counter
module enduro_counter_sync #(parameter BW = 1)(
        input  logic          clk,      
        input  logic          reset_n,
        input  logic [BW-1:0] data_in,
        output logic [BW-1:0] data_out_synced
    );


logic [BW-1:0] data_in_ff1;
logic [BW-1:0] data_in_ff2;


always_ff @(posedge clk) begin
  if (~reset_n) begin
    data_in_ff1 <= '0;
    data_in_ff2 <= '0;
  end
  else begin
    data_in_ff1 <= data_in;
    data_in_ff2 <= data_in_ff1;
  end
end


assign data_out_synced = data_in_ff2;


endmodule
