module dmux 
    (
    input [7:0] data,     // 7-bit data from FIFO
    input clk,             // Clock signal
    input rd_en,           // Read enable signal from FIFO
    output [63:0] block,   // 64-bit output block
    output block_ready     // Block ready signal
    );
    
    reg [63:0] r_block = 0;          // Register for storing the 64-bit block
    reg [3:0] counter = 0;           // Counter to track the data storage progress
    reg r_block_ready = 0;           // Ready signal for the block
    reg rd_en_d1 = 0;                // Delayed read enable signal (1 cycle latency)

    always @(posedge clk) begin
        rd_en_d1 <= rd_en;           // Delay rd_en by 1 clock cycle (FIFO read latency)

        if (rd_en_d1) begin
            // Store the 7-bit data into the appropriate part of the 64-bit block
            case (counter)
                0:  r_block[6:0]    <= data;     // Store bits 0-6
                1:  r_block[13:7]   <= data;     // Store bits 7-13
                2:  r_block[20:14]  <= data;     // Store bits 14-20
                3:  r_block[27:21]  <= data;     // Store bits 21-27
                4:  r_block[34:28]  <= data;     // Store bits 28-34
                5:  r_block[41:35]  <= data;     // Store bits 35-41
                6:  r_block[48:42]  <= data;     // Store bits 42-48
                7:  r_block[55:49]  <= data;     // Store bits 49-55
                8:  r_block[62:56]  <= data;     // Store bits 56-62
                9:  r_block[63]     <= data[0];  // Store last bit (bit 63)
            endcase

            // Increment the counter and reset when the block is full
            if (counter == 9) begin
                r_block_ready <= 1;        // Assert block ready once the block is full
                counter <= 0;              // Reset counter after block is filled
            end else begin
                counter <= counter + 1;    // Increment counter
                r_block_ready <= 0;        // Keep block ready low until block is full
            end
        end
    end
    
    // Output assignments
    assign block_ready = r_block_ready;   // Output the block ready signal
    assign block = r_block;               // Output the 64-bit block
    
endmodule
