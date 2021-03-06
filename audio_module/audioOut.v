module audioOut (
	// Inputs
	CLOCK_50,
	KEY,
	SW,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/
// B4: 97 samples - delay = 48  - SW[2] ;
// G4: 122 samples - delay = 61 - SW[1];
// F4: 137 samples - delay = 68 - SW[0];

wire [5:0] b4_delay, g4_delay, a4_delay;
wire [6:0] f4_delay;


assign f4_delay = 7'd68;
assign g4_delay = 6'd61;
assign a4_delay = 6'd54;
assign b4_delay = 6'd48;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input		[3:0]	SW;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers

reg [18:0] delay_cnt;
reg [6:0] delay;

reg snd;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
	if(~KEY[0]) begin
	 delay_cnt <= 18'd0;
	 snd <= 0;
	end
	else if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end
	else delay_cnt <= delay_cnt + 1;

always @(*)
	begin
	case (SW[3:0])
		4'b1000: delay <= {1'b0,a4_delay};
		4'b0100: delay <= {1'b0,b4_delay};
		4'b0010: delay <= {1'b0,g4_delay};
		4'b0001: delay <= f4_delay;
		default: delay <= 7'd0;
	endcase
end
/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

wire signed [31:0] sound = (SW == 0) ? 0 : snd ? 32'h4B000000 : 32'hB5000000;

assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= sound;
assign right_channel_audio_out	= sound;
assign write_audio_out			= audio_in_available & audio_out_allowed & (SW[3] | SW[2] | SW[1] | SW[0]);

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

 Audio_Controller Audio_Controller (
 	// Inputs
 	.CLOCK_50						(CLOCK_50),
 	.reset						(~KEY[0]),

 	.clear_audio_in_memory		(),
 	.read_audio_in				(read_audio_in),

 	.clear_audio_out_memory		(),
 	.left_channel_audio_out		(left_channel_audio_out),
 	.right_channel_audio_out	(right_channel_audio_out),
 	.write_audio_out			(write_audio_out),

 	.AUD_ADCDAT					(AUD_ADCDAT),

 	// Bidirectionals
 	.AUD_BCLK					(AUD_BCLK),
 	.AUD_ADCLRCK				(AUD_ADCLRCK),
 	.AUD_DACLRCK				(AUD_DACLRCK),


 	// Outputs
 	.audio_in_available			(audio_in_available),
 	.left_channel_audio_in		(left_channel_audio_in),
 	.right_channel_audio_in		(right_channel_audio_in),

 	.audio_out_allowed			(audio_out_allowed),

 	.AUD_XCK					(AUD_XCK),
 	.AUD_DACDAT					(AUD_DACDAT)

 );

 avconf #(.USE_MIC_INPUT(1)) avc (
 	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
 	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
 	.CLOCK_50					(CLOCK_50),
 	.reset						(~KEY[0])
 );

endmodule
