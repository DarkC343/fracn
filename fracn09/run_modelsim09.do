# Modelsim tcl script for running testbench for fracn09.pl
# The command line is "do run_modelsim09.do" (from within Modelsim)
# The results are in the file fracn.log
#
# Define test parameters
set iterations 1000;
set fin 1e6;
set fout 32768;
set tolerance 1e-7;
set run_time 100us; #the run time should be at least (1/tolerance) * (1/fin)
set use_phase_accumulator FALSE;
set use_recursive_controller TRUE;
set minimum_jitter TRUE;
set improve_duty_cycle FALSE;
set integer_fout TRUE;

set use_modelsim TRUE;
set use_verilog TRUE;

set fout_sweep_step  7.50e3;
set fout_sweep_start $fout_sweep_step;
set fout_sweep_stop  $fin;

# override test parameters from environment
if { [info exists env(iterations) ]} { set iterations $env(iterations) }
if { [info exists env(fin)        ]} { set fin        $env(fin)        }
if { [info exists env(fout)       ]} { set fout       $env(fout)       }
if { [info exists env(tolerance)  ]} { set tolerance  $env(tolerance)  }
if { [info exists env(run_time)   ]} { set run_time   $env(run_time)   }
if { [info exists env(use_phase_accumulator)    ]} { set use_phase_accumulator $env(use_phase_accumulator) }
if { [info exists env(use_recursive_controller) ]} { set use_recursive_controller $env(use_recursive_controller) }
if { [info exists env(minimum_jitter)           ]} { set minimum_jitter $env(minimum_jitter) }
if { [info exists env(improve_duty_cycle)       ]} { set improve_duty_cycle $env(improve_duty_cycle) }
if { [info exists env(integer_fout)             ]} { set integer_fout $env(integer_fout) }
if { [info exists env(use_modelsim)             ]} { set use_modelsim $env(use_modelsim) }
if { [info exists env(use_verilog)              ]} { set use_modelsim $env(use_verilog) }

if {$minimum_jitter} {set goption "-x"} else {set goption "-g"}
if {$use_phase_accumulator} {set goption "-g"}
if {$use_recursive_controller} {set goption "-g"}

set coption "-x";
set coption "-c";

set soption "-x";
#set soption "-s";

if {$use_verilog} {set target "fracn.v"} else {set target "fracn.vhd"}
if {$use_verilog} {set target_tb "tb_fracn09.v"} else {set target_tb "tb_fracn09.vhd"}

proc generate {} {
    global soption;
    global coption;
    global goption;
    global tolerance;
    global fin;
    global fout;
    exec perl -w fracn09.pl $soption $coption $goption -t $tolerance $fin $fout;
}

proc compile {file} {
    global use_modelsim;
    #puts $file; flush stdout;
    if {[string match "*.vhd" $file]} {
        # VHDL
        if {$use_modelsim} {
            exec vcom -93 -quiet -nologo -work work $file;
        } else {
            exec vhdlp -s -strict -work work $file;
        }
    } else {
        # assume Verilog
        if {$use_modelsim} {
            exec vlog -quiet -nologo -work work $file;
        } else {
            puts "Can't compile $file";
        }
    }
}

proc simulate {} {
    global use_modelsim;
    global run_time;
    global fin;
    global fout;
    global minimum_jitter;
    global use_phase_accumulator;
    global use_recursive_controller;
    global improve_duty_cycle;

    if {$use_modelsim} {
        vsim -quiet -t fs tb_fracn09;
        run $run_time;
    } else {
        exec vhdle -s -p -gfin=$fin -gfout=$fout -gminimum_jitter=$minimum_jitter -guse_phase_accumulator=$use_phase_accumulator -guse_recursive_controller=$use_recursive_controller -gimprove_duty_cycle=$improve_duty_cycle -gtime_of_report=$run_time -t $run_time tb_fracn09;
    }
}

# Generate code, and compile
# (need to do this first, because otherwise there will be no default binding
#  for fracn.)
generate;
if {$use_modelsim} {catch {exec vlib work}}
compile $target
compile $target_tb

set freq_index 0
# special set of bad test frequencies.
set freq_list {
        032768
        500000
        285000
        222000
        181000
        153000
        133000
        118000
        105000
        095000
        032768
        333333.33333333333
        250000
        200000
        166666.66666666667
        142857.14285714286
        125000
        111111.11111111111
        666666.66666666667
        750000.0
        800000
        600000
        395000
        399900
        400000
        400100
        405000
        375000
        625000
        875000
        62500
        31250
        15625
        7812.5
        3906.25
        1953.125
        1e6
        1e5
        1e4
        1e3
        1e2
        1e1
        1e0
        1.e-1
        1.e-2
        611112
        999900.0
        999990.0
        499900.0
        499999.0
        500001.0
};
#        999999.99
#        999999.999
#        500000.01
#        499999.99
#        999999.0
#        500000.1
#        499999.9
#        999999.9

# Declare function for working out fout values.
# The first values come from freq_list - a table of carefully selected
# bad case ratios, and the subsequent values are randomly generated.
proc get_fout {} {
    global fin;
    global integer_fout;
    global freq_index;
    global freq_list;
    global fout_sweep_start;
    global fout_sweep_stop;
    global fout_sweep_step;

    if {$freq_index < [llength $freq_list]} {
        # phase1 - get values from list
        set fout [lindex $freq_list $freq_index];
        incr freq_index;
    } elseif {$fout_sweep_start <= $fout_sweep_stop} {
        # phase2 - linear sweep
        set fout $fout_sweep_start;
        set fout_sweep_start [expr $fout_sweep_start + $fout_sweep_step ];
    } else {
        # phase3 - random
        set fout [expr rand() * $fin ];
        if {$integer_fout} then {
            set fout [expr int($fout)];
            set fout [expr $fout > 0 ? $fout : 1 ];
        }
    }
    return $fout;
}

proc trim_time {t} {
    # turn the execution time into a number of ms
    return [expr [string trim $t "microseconds per iteration"] / 1000 ];
}

# now run repetitive tests
set logfile [open fracn.log w]
puts $logfile "fin=$fin tolerance=$tolerance use_phase_accumulator=$use_phase_accumulator use_recursive_controller=$use_recursive_controller minimum_jitter=$minimum_jitter improve_duty_cycle=$improve_duty_cycle run_time=$run_time"
puts $logfile "use_modelsim=$use_modelsim use_verilog=$use_verilog"
puts $logfile "fout\tfout measured\trelative error\tjitter\tmn/av/mx duty %\tperl time\tcomp time\tsim time";
for {set x 1} {$x <= $iterations} {incr x} {
    set fout [ get_fout ];
    puts "******************  test number $x: $fin $fout"; flush stdout;
    puts -nonewline $logfile "$fout"; flush $logfile;
    set time1 [trim_time [time {generate } ] ];
    set time2 [trim_time [time {compile $target } ] ];
    if {$use_modelsim && $use_verilog} {compile $target_tb}
    set time3 [trim_time [time {simulate} ] ];
    set tmpfile [open fracn.rpt r];
    gets $tmpfile line;
    close $tmpfile;
    if { [string length $line] == 0} { set line "no results\t\t\t" };
    puts $logfile "\t$line\t$time1\t$time2\t$time3";
    puts "$line\t[expr $time1 + $time2 + $time3]";
}
close $logfile;
