module mux #(parameter BITS = 6)(
    input  [BITS - 1:0] in0,
    input  [BITS - 1:0] in1,
    input  [BITS - 1:0] in2,
    input  [BITS - 1:0] in3,
    input  [BITS - 1:0] in4,
    input  [BITS - 1:0] in5,
    input  [BITS - 1:0] in6,
    input  [BITS - 1:0] in7,
    input  [2:0] sel,
    output reg [BITS - 1:0] mux_out
    );
    
    always @*
    begin
        case(sel)
            0: mux_out = in0;
            1: mux_out = in1;
            2: mux_out = in2;
            3: mux_out = in3;
            4: mux_out = in4;
            5: mux_out = in5;
            6: mux_out = in6;
            7: mux_out = in7;
            default: mux_out = {BITS{1'bx}};
        endcase
    end
    
endmodule
