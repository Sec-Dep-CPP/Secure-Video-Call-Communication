module time_mux_disp(
    input  [5:0] in0,
    input  [5:0] in1,
    input  [5:0] in2,
    input  [5:0] in3,
    input  [5:0] in4,
    input  [5:0] in5,
    input  [5:0] in6,
    input  [5:0] in7,
    input  clk,
    output  [6:0] sseg,
    output  dp,
    output  [7:0] an
    );
    
    
    // to_display[0] is for dp
    // to_display[4:1] is the hex to be decoded
    // to_display[5] is to enable/disable a sseg digit
    wire [5:0] to_display;
    wire [19:0] counter_output;
    wire [2:0] controller_counter;
    assign controller_counter = counter_output[19:17];
    
    binary_counter #(.N(20)) c0(
                    .clk(clk),
                    .reset(1'b0),
                    .en(1'b1),
                    .q(counter_output),
                    .max_tick()
                    );
                    
    mux #(.BITS(6)) mux0(
                    .in0(in0),
                    .in1(in1),
                    .in2(in2),
                    .in3(in3),
                    .in4(in4),
                    .in5(in5),
                    .in6(in6),
                    .in7(in7),
                    .sel(controller_counter),
                    .mux_out(to_display)); //all the ins are captured by .*
                    
    decoder  #(.N(3)) decoder0(
                    .in(controller_counter),
                    .enable(1'b1),
                    .an(an));
                    
    hex2sseg ssegdecoder(
                    .hex_in(to_display[4:1]),
                    .enable(to_display[5]),
                    .sseg(sseg));
    // decimal point                
    assign dp = to_display[0];
endmodule
