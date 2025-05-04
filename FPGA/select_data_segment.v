module select_data_segment(
    input [2:0] SW,
    input [127:0] msg,
    input [127:0] key,
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
    
    4:
    begin
    msg_p = msg[79:64];
    key_p = key[79:64];  
    end
    
    5:
    begin
    msg_p = msg[95:80];
    key_p = key[95:80];  
    end
    
    6:
    begin
    msg_p = msg[111:96];
    key_p = key[111:96];  
    end
    
    7:
    begin
    msg_p = msg[127:112];
    key_p = key[127:112];  
    end
    
    
    
    
    endcase
    
    
    end
endmodule
