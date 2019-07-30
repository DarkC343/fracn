readme.txt

This archive contains "FracN" version 0.08.
FracN is a Perl script for designing fractional-N frequency dividers.
Both phase-accumulator and dual-modulus-prescaler designs are performed.
It also writes VHDL file to implement the divider.
Copyright (c) Allan Herriman 1999, 2000

Files:
readme.txt	This file
fracn08.pl	Perl script for designing fractional-N dividers
tb_fracn08.vhd	VHDL testbench for testing the generated VHDL code
run_modelsim08.do	TCL regression test (for Modelsim)
run_simili08.tcl	TCL regression test (for Simili)

The command line syntax for fracn08.pl is displayed if you run fracn08.pl
without any arguments.

Legal Stuff:
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
No claim is made that the Perl script or the VHDL file generated do
not infringe any patents.

Copying:
This archive may be freely copied in its original form, with all files intact.

How to use this program:
1. Work out your requirements.  You will need to know the exact
input frequency, the exact output frequency you desire to generate,
the allowable tolerance on the output frequency and the amount of jitter
you can tolerate.

2. Make sure you have Perl installed.  (It is free.)
It needs to be Perl version 5.  Version 4 has not been tested, and
may not work.

3. Run the program fracn08.pl to design the divider and generate the
VHDL.
The parameters are fed to the program on the command line; there is no
GUI.  Windows users will need to run the program from a DOS shell.
Enter the comand line:
fracn08.pl -t tolerance input_frequency output_frequency
(where input_frequency is the frequency in Hz, etc.)
E.g.
fracn08.pl -t 1e-6 1e7 2.048e6
will design a 10MHz to 2.048MHz divider, with at most 1ppm frequency
error.
The tolerance parameter is optional, and will default to 1e-7 if not
specified.
There are other command line options, which will be displayed if you
run fracn08.pl without any command line arguments.

4. If it says "... cannot execute" then either set the execute
permissions (duh), or try:
perl -w fracn08.pl ...
instead of:
fracn08.pl ...

4b. If the VHDL compiler complains about not being able to find
the library "numeric_std" then run fracn08.pl with the -s switch,
which will use std_logic_unsigned instead.

5. How to use the generated VHDL code:
The VHDL is by default in a file "fracn.vhd".
Here are the port definitions:
  port (
    async_reset       : in  std_logic;
    clock             : in  std_logic;
    clock_enable      : in  std_logic;
    output_50         : out std_logic;
    output_pulse      : out std_logic
  );

You connect your clock to the clock input, tie clock_enable high,
connect async_reset to your active-high system reset, and select
either output_50 or output_pulse to be the output,
depending on whether you want an (approximately)
50% duty cycle output, or whether you want a single
high output pulse per cycle (which would be the case if you were driving
more logic).
The output_50 output will not be implemented (it will always output
'U') if Fout/Fin > 1/2.
The registers inside the fracn.vhd module have deliberately not been given
intial values, which means that your simulation will have to drive
async_reset high briefly at the start of simulation in order for the
simulation to work correctly.  This does not affect synthesis results.

6.  How to chose which type of divider to use.
Here are the generic definitions:
  generic (
    use_phase_accumulator : boolean := FALSE;
    use_recursive_controller  : boolean := TRUE;
    minimum_jitter        : boolean := FALSE;
    improve_duty_cycle    : boolean := TRUE
  );

The first three control which of four types of divider will be used.
use_phase_accumulator has the highest priority, and if TRUE, will
cause a phase accumulator style divider to be generated, otherwise a
dual-modulus prescaler divider will be generated.
The next two generics determine which sort of controller is used for the
dual-modulus prescaler (assuming use_phase_accumulator is FALSE).
use_recursive_controller has the highest priority, and, if TRUE, will
make a controller which may have many flip flops, but not much logic.
If use_recursive_controller is FALSE, then minimum_jitter determines
which of two simple controllers are used.  If minimum_jitter is TRUE,
then *sometimes* a huge case statement will result, and if minimum
jitter is FALSE, then the controller is very simple, but the output
jitter may be quite poor.

These four types of divider have been made available because there isn't
a clear winner in terms of size or performance for all ratios.  The only
way to work out which one is best for your application is to try them.
Usually, the phase accumulator is quite good, although for some
ratios it it impossible to get the exact output frequency you want.
The dual-modulus prescaler with recursive controller is also usually
quite good, and is often superior to the phase accumulator in terms of
chip area and ease of routing, particularly for tight tolerances.
The default values of the generics will select the recursive controller.

The final generic improve_duty_cycle allows a negative edge flip flop to
be used to make the duty cycle of the output_50 output to
be closer to 50%.  If this generic is FALSE, only rising edge flip flops
will be used.  Thanks to Walter Baeck for this idea.

7.  There is a test bench supplied, in case you don't already have one.
It is in the file tb_fracn08.vhd.  It has some top level generics which
will have to be set in your simulator.
If you are using Modelsim, the syntax for setting generics is:
vsim -gname=value ...


Notes on the TCL regression test scripts:
These scripts are only of interest to users modifying the Perl script
fracn08.pl.
The scripts only test one type of divider at a time.  The scripts must be
manually edited to select a different type of divider.
The scripts are not self-checking.  The log file "fracn.log" must be analysed
to determine whether any errors have been detected.  Currently this analysis
must be performed manually.
To test the accuracy, the run time must be set to a quite large value.
For a 1MHz clock, and a tolerance of 1e-7, a run time of 100sec is suggested.
