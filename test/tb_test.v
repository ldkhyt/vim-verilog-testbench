`timescale 1ns/1ps
module tb_test;
// ---- Ports
reg               a;
reg               b;
wire              c;

test #(
) u_test (
	.a         (a         ),
	.b         (b         ),
	.c         (c         )
);

initial begin


#100 $finish;
end

initial begin
	$dumpfile("wave.vcd");
	$dumpvars(0, tb_test);
end


endmodule
