module dmux 
    (
    input [7:0] data,        // 7-bit valid data + 1-bit flag (8 bits total)
    input clk,
    input rd_en,
    output [127:0] block,    // Expanded to 128-bit block
    output block_ready
    );
    
    reg [127:0] r_block = 0;
    reg [4:0] counter = 0;          // Needs to count up to 18
    reg r_block_ready = 0;
    reg rd_en_d1 = 0;

    always @(posedge clk) begin
        rd_en_d1 <= rd_en;

        if (rd_en_d1) begin
            case (counter)
                0:   r_block[6:0]     <= data[6:0];
                1:   r_block[13:7]    <= data[6:0];
                2:   r_block[20:14]   <= data[6:0];
                3:   r_block[27:21]   <= data[6:0];
                4:   r_block[34:28]   <= data[6:0];
                5:   r_block[41:35]   <= data[6:0];
                6:   r_block[48:42]   <= data[6:0];
                7:   r_block[55:49]   <= data[6:0];
                8:   r_block[62:56]   <= data[6:0];
                9:   r_block[69:63]   <= data[6:0];
                10:  r_block[76:70]   <= data[6:0];
                11:  r_block[83:77]   <= data[6:0];
                12:  r_block[90:84]   <= data[6:0];
                13:  r_block[97:91]   <= data[6:0];
                14:  r_block[104:98]  <= data[6:0];
                15:  r_block[111:105] <= data[6:0];
                16:  r_block[118:112] <= data[6:0];
                17:  r_block[125:119] <= data[6:0];
                18:  r_block[127:126] <= data[1:0]; // last 2 bits, padded
            endcase

            if (counter == 18) begin
                r_block_ready <= 1;
                counter <= 0;
            end else begin
                counter <= counter + 1;
                r_block_ready <= 0;
            end
        end
    end

    assign block_ready = r_block_ready;
    assign block = r_block;
    
endmodule
