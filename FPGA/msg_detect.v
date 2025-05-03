module msg_detect(
input clk,
input DV,
input [7:0] data,
output reg one_pulse
);

reg dv_d1;
wire dv_rising;
reg one_pulse;

always @(posedge clk) begin
    dv_d1 <= DV;
end

assign dv_rising = DV & ~dv_d1;

always @(posedge clk) begin
    if(dv_rising && data[7])
    one_pulse <= 1;
    else
    one_pulse <= 0;
end



endmodule
