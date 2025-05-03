module msg_key(
    input [63:0] data,     // 64-bit data from FIFO
    input clk,             // Clock signal
    input rd_en,           // Read enable signal from FIFO
    output [63:0] msg,
    output [63:0] key,     // 64-bit output block
    output ready     // Block ready signal
);

    reg [63:0] r_msg = 0;
    reg [63:0] r_key = 0;          // Register for storing the 64-bit block
    reg counter = 0;           // Counter to track the data storage progress
    reg r_ready = 0;           // Ready signal for the block
    reg rd_en_d1 = 0;                // Delayed read enable signal (1 cycle latency)

    always @(posedge clk) begin
        rd_en_d1 <= rd_en;           // Delay rd_en by 1 clock cycle (FIFO read latency)

        if (rd_en_d1) begin
            
            case (counter)
                0: r_msg <= data;
                
                1: r_key <= data;             
            endcase

            // Increment the counter and reset when the block is full
            if (counter == 1) begin
                r_ready <= 1;        // Assert block ready once the block is full
                counter <= 0;              // Reset counter after block is filled
            end else begin
                counter <= counter + 1;    // Increment counter
                r_ready <= 0;        // Keep block ready low until block is full
            end
        end
    end
    
    // Output assignments
    assign msg = r_msg;   // Output the block ready signal
    assign key = r_key;               // Output the 64-bit block
    assign ready = r_ready;
    


endmodule
