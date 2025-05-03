module push_detect(
    input clk,
    input empty,
    output reg rd_en
    );
    
reg empty_d1;       // Delayed version of empty
wire empty_falling; // Detect falling edge of empty

always @(posedge clk) begin
    empty_d1 <= empty;  // Store previous empty state
end

assign empty_falling = ~empty & empty_d1; // Detect falling edge of empty

always @(posedge clk) begin
    rd_en <= empty_falling; // Generate one-clock pulse
end
endmodule
