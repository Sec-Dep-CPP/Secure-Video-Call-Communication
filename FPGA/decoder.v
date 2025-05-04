module decoder #(parameter N = 3)(
    input  [N - 1:0] in,
    input  enable,
    output reg [2**N - 1:0] an
    );
    
    integer i;
    
    always @*
    begin
        an = {2**N{1'b1}}; 
        
        if(enable)
        begin
            for(i = 0; i < 2**N; i = i +1)
            begin
                if (in == i)
                    an[i] = 1'b0;
            end
        end
        

    end
    
endmodule
