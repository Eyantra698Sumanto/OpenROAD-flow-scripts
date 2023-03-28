module top (in1,
    out1,
    VDD,
    VSS);
 input in1;
 output out1;
 input VDD;
 input VSS;


 BUF_X1 u1 (.A(in1),
    .Z(out1),
    .VDD(VDD),
    .VSS(VSS));
endmodule
