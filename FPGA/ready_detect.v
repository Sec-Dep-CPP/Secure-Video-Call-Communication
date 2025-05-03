module ready_detect(
    input clk,
    input block_ready,
    output block_ready_pulse
    );
    
reg block_ready_d;  // Delayed version of block_ready

always @(posedge clk) begin
    block_ready_d <= block_ready;  // Store previous state
end

assign block_ready_pulse = block_ready & ~block_ready_d;  // Detect rising edge
endmodule
