module top (in1,
    in2,
    clk1,
    clk2,
    clk3,
    out);
 input in1;
 input in2;
 input clk1;
 input clk2;
 input clk3;
 output out;

 wire r1q;
 wire r2q;
 wire u1z;
 wire u2z;

 snl_ffqx1 r1 (.Q(r1q),
    .D(in1),
    .CP(clk1));
 snl_ffqx1 r2 (.Q(r2q),
    .D(in2),
    .CP(clk2));
 snl_ffqx1 r3 (.Q(out),
    .D(u2z),
    .CP(clk3));
 snl_bufx1 u1 (.Z(u1z),
    .A(r2q));
 snl_and02x1 u2 (.Z(u2z),
    .A(r1q),
    .B(u1z));
endmodule
