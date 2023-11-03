`include "getval.v"
`include "bs.v"
`include "barrel.v"
`include "dff_lvl.v"

module fpa(
    input [32:1] a,
    input [32:1] b,
    input rst,clk,
    output [32:1] c
    );
output wire [32:1] man_a,man_a1,man_a2,man_a3,man_a4,man_a5,man_a6,man_a7;                                       //to store mantissa value of a
output wire [32:1] man_b,man_b1,man_b2,man_b3,man_b4,man_b5,man_b6,man_b7;                                       //to store mantissa value of b
wire [32:1] sum,ai,bi;                                                //to store sum of mantissa 
wire [8:1] exp_a,exp_b,dif,exp_a1,exp_b1,exp_a2,exp_b2,exp_a3,exp_b3,exp_a4,exp_b4,exp_a5,exp_b5;                                     //to store exp value of a,b and to store difference of exp of a exp of b
wire [32:1] man_bs;                                             //to store shifted mantissa value of b
wire sign_a,sign_b,sign_a1,sign_b1,sign_a2,sign_b2,sign_a3,sign_b3,sign_a4,sign_b4,sign_a5,sign_b5;                                             //to store sign value of a and b
reg sign_c;                                                     //to store sign value of c
reg [8:1] exp_c;                                                //to store exp value of c
reg [32:1] man_c;                                               //to store mantissa value of c
integer i;

//1
dff_lvl_1 p1(a,b,rst,clk,ai,bi);
getval m0(ai,bi,man_a1,man_b1,exp_a1,exp_b1,sign_a1,sign_b1);           //module gets two numbers as input and stores the mantissa ,exp and sign of resp nos 
//2
dff_lvl_2 p2(man_a1,man_b1,exp_a1,exp_b1,sign_a1,sign_b1,rst,clk,man_a2,man_b2,exp_a2,exp_b2,sign_a2,sign_b2);
getdif m1(exp_a2,exp_b2,dif);                                     // module gets difference between exp of a and b
//3
dff_lvl_2 p3(man_a2,man_b2,exp_a2,exp_b2,sign_a2,sign_b2,rst,clk,man_a3,man_b3,exp_a3,exp_b3,sign_a3,sign_b3);
bs_right m2(man_b3,dif,1'b1,1'b0,man_bs);
//4
dff_lvl_2 p4(man_a3,man_b3,exp_a3,exp_b3,sign_a3,sign_b3,rst,clk,man_a4,man_b4,exp_a4,exp_b4,sign_a4,sign_b4);
comparator m3(man_a4,man_bs,sign_a4,sign_b4,sum);                  //module stores sum of mantissa of a and b according to the sign of a and b
//5
dff_lvl_2 p5(man_a4,man_b4,exp_a4,exp_b4,sign_a4,sign_b4,rst,clk,man_a,man_b,exp_a,exp_b,sign_a,sign_b);
always@(posedge clk)
begin
    sign_c=sign_a;
    exp_c=exp_a;
    man_c=sum;
    if(a[31:1]==b[31:1] && sign_a!=sign_b)                      //checks whether both numbers are equal and of oppposite sign
begin
sign_c=1'b0;
exp_c=8'b0;
man_c[24]=1'b1;
end

i=32;
while(man_c[i]==0)                                              //find the difference to be shifted to normalize again incase of denormalized sum
i=i-1;

if(i>24)
begin
if(man_a==32'h0080_0000 && man_b==32'h0080_0000)                // incase of sum of mantissa being 0
i=0;
else
i=i-24;
if((a[31:24]==8'd0 && a[23:1]!=0) || (b[31:24]==8'd0 && b[23:1]!=0))  
begin
man_c=man_c;
if(sum>=32'h0180_0000)                                          //subnormal sum check
i=i+1;
end
else
man_c=man_c>>i;
exp_c=exp_c+i;
end
else
begin
i=24-i;
man_c=man_c<<i;
exp_c=exp_c-i;
end

if((a[31:24]==8'hff && a[23:1]!=23'b0) || (b[31:24]==8'hff && b[23:1]!=23'b0)) //to handle nan cases
begin
exp_c=8'hff;
man_c=32'd1;
end
else if(a[31:24]==8'hff ||b[31:24]==8'hff )                                     // to handle inf cases
begin
    exp_c=8'hff;
    man_c=32'd0;
end

//store the result 
//c[32]=sign_c;
//c[31:24]=exp_c;
//c[23:1]=man_c[23:1];

end
//6
dff_lvl_3 p6(sign_c,exp_c,man_c,rst,clk,c);
//7



endmodule

//Test Module 
module top;
reg [32:1] a,b;
reg rst,clk;
wire [32:1] c;
fpa f1(a,b,rst,clk,c);
integer i;
initial
begin

    #0 a=32'b01000010000011001010100011110110; b=32'b11000101011000000011111110111110;      //3587.984 + 35.165
    //Special cases
    //adding two inf
    //#5 a=32'b01111111100000000000000000000000;   b=32'b01111111100000000000000000000000;    //inf +inf
    //adding nan
    //#10 a=32'b01111111111111111111111111111111;    b=32'b01111111111111111110001111111111;  //naN +nan
    //adding zero
    //#15 a=32'b00000000000000000000000000000000;    b=32'b10000000000000000000000000000000;  //zero - zero


end

initial
begin
clk=1;
rst=0;
rst=1;
for (i=0;i<30;i++)
#1 clk=~clk;
end

initial
begin

    $monitor($time,"Input :\n\tA=%b\tB=%b\nOutput :\n\tC=%b\n",a,b,c);
    $dumpfile("fpa.vcd");
	$dumpvars;

end
endmodule
