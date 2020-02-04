
//`timescale 1ns / 1ns

//module VCODriveFilter(Rst, Clk, CE, In, Out);

module VCODriveFilter #(
	parameter pWidth = 32,
	parameter pAlpha = 4,
	parameter pDefaultValue = 32'h5000_0000  // 10MHz@32MHz
)(
	input  wire Rst,
	input  wire Clk,
	input  wire CE,
	input  wire[(pWidth - 1):0] In,

	output wire[(pWidth - 1):0] Out
);

////////////////////////////////////////////////////////////////////////////////
//
//  Module Parameters
//

//parameter pWidth = 32;
//parameter pAlpha = 4;
//parameter pDefaultValue = 32'h5000_0000;  // 10MHz@32MHz

////////////////////////////////////////////////////////////////////////////////
//
//  Port Declarations
//

//    input  Rst;
//    input  Clk;
//    input  CE;
//    input  [(pWidth - 1):0] In;
//
//    output [(pWidth - 1):0] Out;

////////////////////////////////////////////////////////////////////////////////
//
//  Signal Declarations
//

    wire    Hold;

    wire    [(pWidth + pAlpha):0] A, B, C;
    wire    [(pWidth + pAlpha):0] Sum;
    wire    CY, OV, UV;
    wire    [(pWidth + pAlpha - 1):0] rYIn;
    reg     [(pWidth + pAlpha - 1):0] rY;

initial rY = {pDefaultValue, {(pAlpha){1'b0}}};	 
	 
////////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

assign Hold = ~|In;    //  Memory Enable, if (In == 0), hold rY value

//  (A   : s_ssss_snnn_nnnn_nnnn_nnnn_nnnn_nnnn_nnnn.ffff)
//  (B   : 0_0nnn_nnnn_nnnn_nnnn_nnnn_nnnn_nnnn_nnnn.ffff)
//  (C   : 0_0000_0nnn_nnnn_nnnn_nnnn_nnnn_nnnn_nnnn.ffff)
//  (Sum : 0_0nnn_nnnn_nnnn_nnnn_nnnn_nnnn_nnnn_nnnn.ffff)

assign A = {{(pAlpha+1){In[(pWidth-1)]}}, In};          // A = In / 16
assign B = {rY[(pWidth+pAlpha-1)], rY};                 // B = rY
assign C = {{(pAlpha+1){rY[(pWidth+pAlpha-1)]}}, rY[(pWidth+pAlpha-1):pAlpha]};

//  Compute the Error Sum with negative feedback term (lossy integrator)
//      Sum = (1/(2**pAlpha))Xn + (((2**pAlpha) - 1)/(2**pAlpha))Yn

assign Sum = A + B - C;

//  Compute Overflow/Underflow for unsigned rY

assign CY = Sum[(pWidth + pAlpha)];
assign OV = ~CY & Sum[(pWidth + pAlpha - 1)]; // unsigned
assign UV =  CY & Sum[(pWidth + pAlpha - 1)]; // unsigned

//  Limit rY to positive values: 0..32'h7FFF_FFFF

assign rYIn = ((UV) ? (0) : ((OV) ? ((1 << (pWidth + pAlpha - 1)) - 1)
                                  : Sum));

//  Register limited sum into filter memory

always @(posedge Clk)
begin
    if(Rst)
        #1 rY <= {pDefaultValue, {(pAlpha){1'b0}}};
    else if(CE & ~Hold)
        #1 rY <= rYIn[(pWidth + pAlpha - 1):0];
end

//  Output pWidth MSBs of filter memory register, rY

assign Out = rY[(pWidth + pAlpha - 1):pAlpha];

endmodule