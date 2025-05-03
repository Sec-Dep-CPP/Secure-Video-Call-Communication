module select_data_segment(
    input [1:0] SW,
    input [63:0] msg,
    input [63:0] key,
    output reg [15:0] msg_p,
    output reg [15:0] key_p
    );
    
    always @*
    begin
    
    case(SW)
    0:
    begin
    msg_p = msg[15:0];
    key_p = key[15:0];
    end
    
    1:
    begin
    msg_p = msg[31:16];
    key_p = key[31:16];
    end
    
    2:
    begin
    msg_p = msg[47:32];
    key_p = key[47:32];    
    end 
    
    3:
    begin
    msg_p = msg[63:48];
    key_p = key[63:48];  
    end
    
    endcase
    
    
    end
endmodule
