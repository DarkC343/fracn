////////////////////////////////////////////////////////////////////////////////
// File         : fracn.v (machine generated)
// Contains     : module fracn
// Author       : .\fracn09.pl  (version 0.09)
// Command Line : .\fracn09.pl 77.76e6 1.544e6
// Date         : Tue Jul 30 16:04:27 2019
// Complain to  : fractional_divider@hotmail.com
//
// This machine generated Verilog file contains a fixed ratio frequency divider.
// Different styles of dividers can be selected by generics or parameters.
//
//  use_phase_accumulator = TRUE   selects a "classic" phase accumulator
//                                 frequency divider
//
//  use_phase_accumulator = FALSE  selects a frequency divider made up of
//                                 a dual modulus prescaler and a controller
//                                 In this case, the generics "minimum_jitter"
//                                 and "use_recursive_controller"
//                                 control size / jitter tradeoffs in
//                                 the controller.
//
// The phase accumulator style divider has a regular structure (in the sense
// that it doesn't change much if the ratio is changed - which is good for
// floorplanning) and it is quite easy to understand.
// The output frequency is a rational multiple of the input frequency in
// the form:
//
//       c
// --------------- * Fin
// (2 ** num_bits)
//
// where c and num_bits are integers.
// The hardware consists of a constant adder, so it will be simple to
// make it work at high speed.
// The output jitter will generally be equal to or just less than one
// cycle of the input clock.
// Here is a block diagram:
// 
// 'clock'-----------------------+
//                               |
//             +-------+    +----------+
// Constant--->|       |    |          |
// 'c'         | Adder |--->| Register |-+-->'phase'
//          +->|       |    |          | |
//          |  +-------+    +----------+ |
//          |                            |
//          +----------------------------+
//
// The MSB of the 'phase' signal has approximately a 50% duty cycle, and
// is retimed (in another ff not shown) and used as the 'output_50' output.
// The carry output of the adder will be high once every output cycle,
// and is registered (in another ff not shown) and used as the
// 'output_pulse' output.
//
//
// The dual modulus prescaler divider is somewhat harder to understand, but
// it may result in less hardware, and it may enable the exact ratio to
// be produced.
// In this case, the output frequency is a rational multiple of the input
// frequency in the form:
//
//       (a + b)
// ----------------------- * Fin
// (a * n) + (b * (n + 1))
//
// where a, b, and n are integers.
// The dual modulus prescaler divides the input clock by n or (n+1).
// The controller causes the prescaler to divide by n for a cycles of the
// output, and divide by (n+1) for b cycles of the output.
// Depending on how these a and b cycles are mixed up, the output
// jitter will vary.
// There are a number of ways to make the controller.
// If the generic use_recursive_controller is TRUE, the controller consists
// of a state machine that produces the best interleaving of the a and b cycles,
// which gives about the same jitter as the phase accumulator.
// If use_recursive_controller is FALSE, the controller consists of a counter
// and a lookup table to interleave the a and b cycles.
// There are more tradeoffs: if the generic minimum_jitter is FALSE, the lookup
// table bunches all the a cycles together, and all the b cycles together.
// This results in simple hardware, but may produce lots of jitter.
// If the generic minimum_jitter is TRUE, the lookup table produces the best
// interleaving of the a and b cycles, but it may result in an excessively
// large case statement.
// (It will usually be possible to come up with a much better
// controller design by hand, but the details vary so much with
// the choice of frequencies that it is hard to generalise this
// into a simple script.)
// Here is a block diagram:
//
//             +--------------+
//             | Dual modulus | 'prescaler_out'
// 'clock'---->|  Prescaler   |------+--------->
//             | /n or /(n+1) |      |
//             +--------------+      |
//                    ^              |
//                    |       +------------+
//                    |       |            |
//                    +-------| Controller |
//          'modulus_control' |            |
//                            +------------+
//
//
// For a given set of input to output frequency ratio and tolerance,
// the only way to work out which type of divider is better is
// to try them!  Generally, the phase accumulator is better for
// loose tolerances (> 10ppm), and the dual modulus prescaler is
// better if the ratio must be exact, but this depends on the ratio.
//
// Frequency Parameters:
// Input Frequency: 77760000 Hz.
// Desired Output Frequency: 1544000 Hz.
// Requested Relative Frequency Error Bounds (+/-) : 1e-007 (0.1 ppm)
//
// Frequency Results (use_phase_accumulator = FALSE) :
//  Achieved Output Frequency: 1544000 Hz.
//  Achieved Relative Frequency Error: 0 (0 ppm)
//  Achieved Frequency Error: 0 Hz.
//
// Frequency Results (use_phase_accumulator = TRUE) :
//  Achieved Output Frequency: 1544000.12254715 Hz.
//  Achieved Relative Frequency Error: 7.93699155817378e-008 (0.0793699155817378 ppm)
//  Achieved Frequency Error: 0.122547149658203 Hz.
//
// Output Jitter Parameters (use_phase_accumulator = FALSE) :
//  The fundamental frequency is 8000 Hz.
//  The amplitude is 5.73706262393657e-007 seconds p-p (minimum_jitter = FALSE).
//  The amplitude is 1.27934497537264e-008 seconds p-p (minimum_jitter = TRUE).
//
// Output Jitter Parameters (use_phase_accumulator = TRUE) :
//  The fundamental frequency is 0.579357147216797 Hz.
//  The amplitude is 1.28600823045268e-008 seconds p-p (approx).
//
// Design Parameters (use_phase_accumulator = FALSE) :
//  Approx 17 flip flops (6 in prescaler, 9 in controller and 2 retimes).
//  The recursive controller uses approx 17 flip flops.
//  The Dual-Modulus Prescaler uses ratios /50,/51
//  The Output consists of 123 cycles of 50 input clocks,
//  and 70 cycles of 51 input clocks.
//  There are 193 output clocks for every 9720 input clocks.
//
// Design Parameters (use_phase_accumulator = TRUE) :
//  Approx 29 flip flops (27 in accumulator and 2 retimes)
//  There are 2665023 output clocks for every 134217728 input clocks.
//
// Divider summary :
//
// Approx Approx    Relative  Approx    
//  ff    Virtex    Frequency Jitter    Divider
// count  Slices    Error     (seconds) (generic parameters)
//
//  29    tbd       7.9e-008  1.3e-008  use_phase_accumulator
//  32    tbd       7.9e-008  6.4e-009  use_phase_accumulator improve_duty_cycle
//  25    tbd       0         1.3e-008  use_recursive_controller
//  26    tbd       0         1.3e-008  use_recursive_controller improve_duty_cycle
//  17    tbd       0         1.3e-008  minimum_jitter
//  18    tbd       0         1.3e-008  minimum_jitter improve_duty_cycle
//  17    tbd       0         5.7e-007  (none)
//  18    tbd       0         5.7e-007  (none) improve_duty_cycle
//
// Warnings:
//  none
//
// Do not fix bugs by hand editing this file - fix the Perl source instead!
////////////////////////////////////////////////////////////////////////////////

module fracn (async_reset, clock, clock_enable, output_50, output_pulse);
    input  async_reset;     // active high reset
    input  clock;           // 77760000 Hz input clock
    input  clock_enable;    // active high clock enable
    output output_50;       // 1544000 Hz output - approx 50% duty cycle
    output output_pulse;    // 1544000 Hz output - high for single clock per cycle

    parameter use_phase_accumulator     = 0;
        // TRUE uses classic NCO design.
        // FALSE uses prescaler / controller design
    parameter use_recursive_controller  = 1;
    parameter minimum_jitter            = 0;
        // TRUE may use more hardware, but has lowest jitter
        // (only applies when use_phase_accumulator is FALSE)
    parameter improve_duty_cycle        = 1;
        // TRUE uses a falling edge ff to make the output duty cycle closer to 50%

    // definitions for prescaler / controller design
    parameter n  = 50;  // prescaler divides by n or n + 1
    parameter a  = 123; // this many counts of 50
    parameter b  = 70;  // this many counts of 51
    wire modulus_control;
    reg [5:0] prescaler_count;
    reg [7:0] controller_count;
    reg prescaler_out;
    reg prescaler_out_50;
    reg duty_correction;
    // definitions for recursive controller design
    parameter n1 = 2;   // prescaler #1 divides by n1 or n1 + 1
    parameter m1 = 2;   // determines output duty cycle for prescaler #1
    parameter n2 = 4;   // prescaler #2 divides by n2 or n2 + 1
    parameter m2 = 4;   // determines output duty cycle for prescaler #2
    parameter n3 = 8;   // prescaler #3 divides by n3 or n3 + 1
    parameter m3 = 8;   // determines output duty cycle for prescaler #3
    parameter n4 = 1;   // prescaler #4 divides by n4 or n4 + 1
    parameter m4 = 1;   // determines output duty cycle for prescaler #4
    reg [1:0] stage1_count;
    reg [2:0] stage2_count;
    reg [3:0] stage3_count;
    reg [0:0] stage4_count;
    reg stage1_out;
    reg stage2_out;
    reg stage3_out;
    reg stage4_out;
    reg stage1_carry;
    reg stage2_carry;
    reg stage3_carry;

    // definitions for phase accumulator design
    parameter num_bits = 27;    // size of phase accumulator
    parameter c = 27'd2665023;
    reg [27:0] phase;   // MSB is carry output from adder

////////////////////////////////////////////////////////////////////////////////
// Standard Phase accumulator.
// Adds c to phase each clock.
// phase(num_bits) is actually the registered carry output.
////////////////////////////////////////////////////////////////////////////////
/** this section not yet implemented in the Verilog version */

////////////////////////////////////////////////////////////////////////////////
// Phase accumulator with lower jitter (on output_50) and improved duty cycle.
////////////////////////////////////////////////////////////////////////////////
/** this section not yet implemented in the Verilog version */

////////////////////////////////////////////////////////////////////////////////
// Prescaler.  Divides by either 50 or 51
// depending on whether the signal "modulus_control" is '0' or '1'.
// Note: the "terminal count" is fixed, and the load value is
// varied, to give smaller, faster logic (?)
////////////////////////////////////////////////////////////////////////////////
    always @(posedge async_reset or posedge clock ) begin : prescaler
        if (async_reset)
            begin
                prescaler_count  <= 0;
                prescaler_out    <= 0;
                prescaler_out_50 <= 0;
            end
        else
            begin
                if (clock_enable)
                    begin
                        // manage counter
                        if (prescaler_count < n)
                            prescaler_count <= prescaler_count + 1;
                        else
                            prescaler_count <= modulus_control ? 0 : 1;
                        // decode counter
                        prescaler_out <= (prescaler_count < n) ? 0 : 1;
                        // make 50% duty cycle output
                        prescaler_out_50 <= (prescaler_count <= n/2) ? 0 : 1;
                    end
            end
        end

    assign output_pulse = prescaler_out;

////////////////////////////////////////////////////////////////////////////////
// Duty cycle improvement using falling edge flip flop.
////////////////////////////////////////////////////////////////////////////////
/** this section not yet implemented in the Verilog version */


    assign output_50 = prescaler_out_50;

////////////////////////////////////////////////////////////////////////////////
// Controller.
// Wobbles the signal "modulus_control" to cause the prescaler
// to divide by the correct ratio (in the long term).
// Modulus_control must be '0' for 123 counts of prescaler_out,
// and '1' for 70 counts (out of a total of 193 counts).
// The simple way to do this is to just have modulus_control '0' for
// all 123 counts, then '1' for 70 counts, but this may result in severe jitter.
// The jitter can be reduced (at some hardware cost) by interleaving
// the '0' and '1' counts.
// This behaviour can be controlled by the generic parameter "minimum_jitter".
// Note that there are many hardware / jitter tradeoffs.
// Best results may require human intervention!
////////////////////////////////////////////////////////////////////////////////
/** this section not yet implemented in the Verilog version */

////////////////////////////////////////////////////////////////////////////////
// recursive controller
// The modulus control signal for the prescaler can be generated by another
// fractional-N divider, which in turn can have its modulus control signal
// generated by yet another fractional-N divider, and so on.
// We stop when we don't need another fractional-N divider, and can just use
// a fixed divider.
// The particular arrangement we use also produces the smallest possible jitter.
// The stageN_count and stageN_out signals have been initialised to non-zero
// values to improve the jitter measurements during simulation.  This is not
// needed for synthesis, and these values should be set to zero if this
// improves synthesis results.
// Recursive controller design information (for debugging):
//          n0=50       m0=X        a0=123      b0=70       i0=X
//          n1=2        m1=2        a1=17       b1=53       i1=0
//          n2=4        m2=4        a2=15       b2=2        i2=1
//          n3=8        m3=8        a3=1        b3=1        i3=0
//          n4=1        m4=1        a4=X        b4=X        i4=0
////////////////////////////////////////////////////////////////////////////////
    always @(posedge async_reset or posedge clock ) begin : recursive_controller
        if (async_reset)
            begin
                stage1_count <= 2;
                stage2_count <= 4;
                stage3_count <= 8;
                stage4_count <= 1;
                stage1_out <= 0;
                stage2_out <= 1;
                stage3_out <= 0;
                stage4_out <= 0;
                stage1_carry <= 0;
                stage2_carry <= 0;
                stage3_carry <= 0;
            end
        else
            begin
                if (clock_enable)
                    begin
                        // Stage 1  stage1_out is low for 123 cycles, and high for 70 cycles.
                        // n1=2 m1=2 a1=17 b1=53 i1=0
                        if (prescaler_out) begin
                            if (stage1_count < n1) begin
                                stage1_count <= stage1_count + 1;
                                stage1_carry <= 0;
                            end else begin
                                if (!stage2_out) begin
                                    stage1_count <= 1;
                                end else begin
                                    stage1_count <= 0;
                                end
                                stage1_carry <= 1;
                            end
                            if (stage1_count < m1) begin
                                stage1_out <= 0;
                            end else begin
                                stage1_out <= 1;
                            end
                        end else begin
                            stage1_carry <= 0;
                        end
                        // Stage 2  stage2_out is low for 17 cycles, and high for 53 cycles.
                        // n2=4 m2=4 a2=15 b2=2 i2=1
                        if (stage1_carry) begin
                            if (stage2_count < n2) begin
                                stage2_count <= stage2_count + 1;
                                stage2_carry <= 0;
                            end else begin
                                if (!stage3_out) begin
                                    stage2_count <= 1;
                                end else begin
                                    stage2_count <= 0;
                                end
                                stage2_carry <= 1;
                            end
                            if (stage2_count < m2) begin
                                stage2_out <= 1;
                            end else begin
                                stage2_out <= 0;
                            end
                        end else begin
                            stage2_carry <= 0;
                        end
                        // Stage 3  stage3_out is low for 15 cycles, and high for 2 cycles.
                        // n3=8 m3=8 a3=1 b3=1 i3=0
                        if (stage2_carry) begin
                            if (stage3_count < n3) begin
                                stage3_count <= stage3_count + 1;
                                stage3_carry <= 0;
                            end else begin
                                if (!stage4_out) begin
                                    stage3_count <= 1;
                                end else begin
                                    stage3_count <= 0;
                                end
                                stage3_carry <= 1;
                            end
                            if (stage3_count < m3) begin
                                stage3_out <= 0;
                            end else begin
                                stage3_out <= 1;
                            end
                        end else begin
                            stage3_carry <= 0;
                        end
                        // Stage 4  stage4_out is low for 1 cycles, and high for 1 cycles.
                        // n4=1 m4=1 a4=X b4=X i4=0
                        if (stage3_carry) begin
                            if (stage4_count < n4) begin
                                stage4_count <= stage4_count + 1;
                            end else begin
                                stage4_count <= 0;
                            end
                            if (stage4_count < m4) begin
                                stage4_out <= 0;
                            end else begin
                                stage4_out <= 1;
                            end
                        end
                    end
                end
            end

    assign modulus_control = stage1_out;

endmodule
////////////////////////////////////////////////////////////////////////////////
// <EOF> fracn.v
////////////////////////////////////////////////////////////////////////////////
