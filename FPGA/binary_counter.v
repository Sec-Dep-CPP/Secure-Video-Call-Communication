module binary_counter
    #(parameter N = 8)
    (
        input  clk, reset,
        input  en,
        output  [N - 1:0] q,
        output  max_tick
    );
        
    // signal declaration
    reg [N - 1:0] r_reg;
    wire [N - 1:0] r_next;
    
    // body
    // [1] Register segment
    always @(posedge clk, posedge reset)
    begin
        if(reset)
            r_reg <= 0;
        else
            r_reg <= r_next;
    end
    
    // [2] next-state logic segment
    assign r_next = en? r_reg + 1: r_reg;
    
    // [3] output logic segment
    assign q = r_reg;    
    
    assign max_tick = (r_reg == 2**N-1) ? 1'b1: 1'b0;
    
endmodule
