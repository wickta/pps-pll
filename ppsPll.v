module ppsPll
(
	input wire oscClock,
	input wire ext_pps_in,
	//input wire rst,
	//input wire enable,
	output wire ErrLim,
	output wire out,
	output wire lock,
	output wire xPPS_Missing
);

	//assign rst = 0;
	//assign enable = 1;

	reg[31:0] output_1khz_syncedCounter;
	reg[31:0] output_1khz_nonSyncCounter;

	initial output_1khz_syncedCounter = 0;
	initial output_1khz_nonSyncCounter = 0;
	
	localparam  pAlpha = 4; //filter parameter
	localparam	pErrCntrLen = 24;//makesure err cntr does not overflow!!
	
	//wires for the 1pps pll module
	wire ppsPLLInputClock;
	//wire iPPS_Out;
	//wire xPPS_In;
	//wire NCO_Out;
	wire PPSGate;
	wire ppsPLLLock;
	
	//TXCO pll to generate 100Mhz from 50Mhz
	wire 	oscPLL_isLocked;
	
	wire 	clock_100Mhz;
	wire	clock_1Mhz;
	
	pll_50to100_Mhz oscillatorPll (
					.areset(0),
					.inclk0(oscClock),
					.c0(clock_100Mhz),
					.c1(clock_1Mhz),
					.locked(oscPLL_isLocked)
					);
					
	assign ppsPLLInputClock = oscPLL_isLocked & clock_100Mhz;
	//assign xPPS_In = oscPLL_isLocked & ext_pps_in;
	
	DPLLv2 #(
					.pPhRefCnt(24'd1_000_000),		  // pps reference counter for 1Mhz
					.pMissingPPS_Cnt(24'd5_000_000), //if pps is not detected after 5s then declare as missing
					.pBasePhaseIncrement(32'h028F_5C29), //1MHZ @ 100MHZ
					.pPosFreqPhiBase(32'h0000_002B),		//1pps @ 100MHZ
					.pNegFreqPhiBase(32'hFFFF_FFD5),		//1pps @ 100MHZ
					.pAlpha(pAlpha),
					.pErrCntrLen(pErrCntrLen)
				)ppsPll
				(
					.Rst(0),
					.Clk(clock_100Mhz),
					.xPPS_In(ext_pps_in),
					//.DPLL_En(), 
					//.xPPS_Out(), 
					//.iPPS_Out(iPPS_Out), 
					//.CE_NCO(), 
					.NCO_Out(out), 
					//.xPPS_TFF(),
					//.iPPS_TFF(),
					.PPSGate(PPSGate), 
					.Lock(lock),

					//.MissingPlsCntr(),
					.xPPS_Missing(xPPS_Missing), //xPPS_Missing is 1 clock pulses - you will never see it in led
				 
					//.iPPS_Cntr(),

					//.Up(Up),
					//.Dn(Dn),
					//.Err(Err),
					//.PhiErr(PhiErr),

					//.ErrCntr(ErrCntr),
					.ErrLim(ErrLim),
					//.LockCntr(LockCntr),

					//.Kphi(Kphi),
					.NCODrv(NCODrv),
					//.NCO(NCO)
				);
				
	//assign out = NCO_Out;//PPSGate ? NCO_Out : clock_1Mhz;
	//assign lock = ~ppsPLLLock;//oscPLL_isLocked & ppsPLLLock;
	
	
//   wire[31:0] Sum;
//	reg[31:0] NCO;
//	assign Sum = NCO + 32'h028F_5C29;
//	wire Rst,  iCE_NCO;
//	reg CE_NCO;
//	
//	assign Rst = 0;
//	
//	always @(posedge clock_100Mhz)
//	begin
//		if(Rst)
//			NCO <= 0;
//		else
//			NCO <= Sum;
//	end
//
//	assign iCE_NCO = (NCO[31] & ~Sum[31]);
//
//	always @(posedge clock_100Mhz)
//	begin
//		if(Rst)
//			CE_NCO <= 0;
//		else
//			CE_NCO <= iCE_NCO;
//	end
//
//	assign NCO_Out = ~NCO[31]; 
//	assign out = NCO_Out;
	
endmodule