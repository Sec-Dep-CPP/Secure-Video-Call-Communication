module top 
(
input UART_RX,
input reset,
input clk,
input read,
input [2:0]SW,
input S,
output [6:0] sseg,
output [7:0] an,
output o_DV,
output o_push,
output o_ready,
output o_ready_des
);

wire [7:0] o_Rx_Byte;
wire DV;
wire [7:0] dout8;
wire [127:0] dout64;
wire read_db;
wire pulse_dv;
wire pulse_push8;
wire pulse_push64;
wire empty8;
wire empty64;

wire [127:0] block;
wire block_ready;

wire [127:0] msg;
wire [127:0] key;
wire [15:0] msg_p;
wire [15:0] key_p;



wire ready_des;
wire ready_des_pulse;






uart_rx_vlog RX(
.i_Clock(clk),
.i_Rx_Serial(UART_RX),
.o_Rx_DV(DV),
.o_Rx_Byte(o_Rx_Byte)
);

msg_detect msg_d(
.clk(clk),
.DV(DV),
.data(o_Rx_Byte),
.one_pulse(pulse_dv)
);



tff tff0(
.clk(clk),
.reset(reset),
.t(pulse_dv),
.q(o_DV)
);

tff tff1(
.clk(clk),
.reset(reset),
.t(pulse_push8),
.q(o_push)
);

tff tff2(
.clk(clk),
.reset(reset),
.t(block_ready_pulse),
.q(o_ready)
);


fifo_generator_0 fifo0(
.clk(clk), 
.srst(reset),
.din(o_Rx_Byte), 
.wr_en(pulse_dv), 
.rd_en(pulse_push8), 
.dout(dout8), 
.full(), 
.empty(empty8) 
 );
 
 push_detect push8(
.clk(clk),
.empty(empty8),
.rd_en(pulse_push8)
);

dmux dmux0(
.data(dout8),
.clk(clk),
.rd_en(pulse_push8),
.block(block),
.block_ready(block_ready)
);

ready_detect rd(
.clk(clk),
.block_ready(block_ready),
.block_ready_pulse(block_ready_pulse)
);

fifo_generator_1 fifo1(
    .clk(clk),
    .srst(reset),
    .din(block), 
    .wr_en(block_ready_pulse),
    .rd_en(pulse_push64),
    .dout(dout64),
    .full(),
    .empty(empty64)
  );
  
push_detect push64(
.clk(clk),
.empty(empty64),
.rd_en(pulse_push64)
);

msg_key mk(
.data(dout64),
.clk(clk),
.rd_en(pulse_push64),
.msg(msg),
.key(key),
.ready(ready_des)
);

ready_detect rd_des(
.clk(clk),
.block_ready(ready_des),
.block_ready_pulse(ready_des_pulse)
);

tff tff3(
.clk(clk),
.reset(reset),
.t(ready_des_pulse),
.q(o_ready_des)
);






//switch msg and msg_p with des output
select_data_segment sds(
.SW(SW),
.msg(msg),
.key(key),
.msg_p(msg_p),
.key_p(key_p)
);


time_mux_disp disp (
        .in0({1'b1 ,msg_p[3:0], 1'b1}),
        .in1({1'b1 ,msg_p[7:4], 1'b1}),
        .in2({1'b1 ,msg_p[11:8], 1'b1}),
        .in3({1'b1 ,msg_p[15:12], 1'b1}),
        .in4({1'b1 ,key_p[3:0], 1'b1}),
        .in5({1'b1 ,key_p[7:4], 1'b1}),
        .in6({1'b1 ,key_p[11:8], 1'b1}),
        .in7({1'b1 ,key_p[15:12], 1'b1}),
        .clk(clk),
        .dp(),
        .an(an),
        .sseg(sseg)
    );



endmodule
