--------------------------------------------------------------------------------
-- tb_fracn09.vhd
-- D.O.B.       : 6/11/00
-- Author       : Allan Herriman
-- Description  : Test bench for fracn.vhd, file generated by fracn09.pl
--                (This can be run from the TCL script run_modelsim09.do)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_fracn09 is
  generic (
    test_ClockDivider : boolean := FALSE; -- try another type of divider from Walter Baeck
    fin               : real;  -- Hz, input frequency
    fout              : real;  -- Hz, desired output frequency
    report_file_name  : string := "fracn.rpt";
    time_of_report    : time := 100 ms;
    use_output_50     : boolean := FALSE;  -- select which output of dut to use
                                          -- for frequency and jitter tests
    -- The next four generics are passed to the divider under test
    use_phase_accumulator     : boolean := FALSE;
    use_recursive_controller  : boolean := TRUE;
    minimum_jitter            : boolean := FALSE;
    improve_duty_cycle        : boolean := TRUE
  );
end tb_fracn09;

architecture testbench of tb_fracn09 is

  component fracn
    --generic (
    --  use_phase_accumulator     : boolean := FALSE;
    --  use_recursive_controller  : boolean := TRUE;
    --  minimum_jitter            : boolean := FALSE;
    --  improve_duty_cycle        : boolean := TRUE
    --);
    port (
      async_reset       : in  std_logic := '0'; -- active high reset
      clock             : in  std_logic;        -- input clock
      clock_enable      : in  std_logic := '1'; -- active high enable
      output_50         : out std_logic; -- approx 50% duty cycle
      output_pulse      : out std_logic  -- high for single clock
    );
  end component;

  -- from Walter Baeck
  component ClockDivider is
  --  generic ();
    port (
      ClkIn        : in  std_logic;
      ClkOut       : out std_logic;
      Reset        : in  std_logic
    );
  end component ClockDivider;

  signal async_reset    : std_logic := '1'; -- active high reset
  signal clock          : std_logic := '1'; -- input clock
  signal clock_enable   : std_logic := '1'; -- active high enable
  signal output_50      : std_logic; -- approx 50% duty cycle
  signal output_pulse   : std_logic; -- high for single clock

  signal measured_frequency : real := 0.0; -- in Hz.
  signal measured_jitter : time := 0 fs;
  signal measured_duty_cycle_min : real := 0.0;
  signal measured_duty_cycle_avg : real := 0.0;
  signal measured_duty_cycle_max : real := 0.0;

  constant clock_half_period : time := (0.5e15 / fin) * 1 fs;
  constant clock_period : time := 2 * clock_half_period;

  constant ideal_ratio  : real := fin/fout;

begin -- testbench

--------------------------------------------------------------------------------
-- Instantiate the divider under test
--------------------------------------------------------------------------------
select_allan_divider: if not test_ClockDivider generate

dut : fracn
    --generic map (
    --  use_phase_accumulator     => use_phase_accumulator,
    --  use_recursive_controller  => use_recursive_controller,
    --  minimum_jitter            => minimum_jitter,
    --  improve_duty_cycle        => improve_duty_cycle
    --)
    port map (
      async_reset       =>  async_reset,
      clock             =>  clock,
      clock_enable      =>  clock_enable,
      output_50         =>  output_50,
      output_pulse      =>  output_pulse
    );

end generate select_allan_divider;

select_walter_divider: if test_ClockDivider generate

dut : ClockDivider
  --  generic map ();
    port map (
      ClkIn        => clock,
      ClkOut       => output_50,
      Reset        => async_reset
    );

  edge_detect : process (async_reset, clock)
    variable last_output : std_logic;
  begin
    if (async_reset = '1') then
      output_pulse <= '0';
      last_output := '1';
    elsif (rising_edge(clock)) then
      if (output_50 = '1' and last_output = '0') then
        output_pulse <= '1';
      else
        output_pulse <= '0';
      end if;
      last_output := output_50;
    end if;
  end process edge_detect;

end generate select_walter_divider;

--------------------------------------------------------------------------------
-- Make the test clock signal
--------------------------------------------------------------------------------
clock_generator : process
begin
  clock <= '1';
  wait for clock_half_period;
  clock <= '0';
  wait for clock_half_period;
end process clock_generator;

--------------------------------------------------------------------------------
-- Make the test reset signal
--------------------------------------------------------------------------------
reset_generator : process
begin
  async_reset <= '1';
  wait until falling_edge(clock);
  async_reset <= '0';
  wait;
end process reset_generator;

--------------------------------------------------------------------------------
-- Save the results to a file at a certain time (and repeat)
--------------------------------------------------------------------------------
dump_results : process
  file rpt : text open write_mode is report_file_name;
  variable L : line;
begin
  wait for time_of_report;
  write(L, measured_frequency);
  write(L, ht); -- tab character
  write(L, ((measured_frequency - fout) / fout)); -- frequency error
  write(L, ht); -- tab character
  write(L, measured_jitter);
  write(L, ht); -- tab character
  write(L, integer(measured_duty_cycle_min*100.0));
  write(L, '/');
  write(L, integer(measured_duty_cycle_avg*100.0));
  write(L, '/');
  write(L, integer(measured_duty_cycle_max*100.0));
  writeline(rpt, L);
  --wait;
end process dump_results;

--------------------------------------------------------------------------------
-- Measure the output frequency and jitter
--
-- The frequency measured will be correct in the long term,
-- but in the short term, jitter will cause slight errors in measurement.
--
-- Note that the method used will cause long term frequency errors to affect
-- the jitter measurement.
--
-- We measure either output_50 or output_pulse depending on
-- the value of the use_output_50 generic.
--------------------------------------------------------------------------------
measure_pulse: if not use_output_50 generate
  measure_frequency : process (async_reset, clock)
    variable num_outputs : natural;
    variable num_clocks : integer;
    variable phase_error : time;
    variable max_phase_error : time;
    variable min_phase_error : time;
    variable waiting : boolean := TRUE;
  begin
    if (async_reset = '1') then
      num_outputs := 0;
      num_clocks := 0;
      phase_error := 0 fs;
      max_phase_error := -1 hr;
      min_phase_error := +1 hr;
      measured_jitter <= 0 fs;
      waiting := TRUE;
    elsif (rising_edge(clock)) then
      if (waiting) then
        -- don't take any measurements until after the first output pulse
        if (output_pulse = '1') then
          waiting := FALSE;
        end if;
      else
        num_clocks := num_clocks + 1;
        if (output_pulse = '1') then
          num_outputs := num_outputs + 1;
          measured_frequency <= (real(num_outputs) / real(num_clocks)) * fin;
          phase_error := ((real(num_outputs) * ideal_ratio) - real(num_clocks)) * clock_period;
          if (phase_error > max_phase_error) then
            max_phase_error := phase_error;
            measured_jitter <= max_phase_error - min_phase_error;
          end if;
          if (phase_error < min_phase_error) then
            min_phase_error := phase_error;
            measured_jitter <= max_phase_error - min_phase_error;
          end if;
        end if;
      end if;
    end if;
  end process measure_frequency;
end generate measure_pulse;

-- as above, but testing the output_50 signal
measure_50: if use_output_50 generate
  measure_frequency : process (async_reset, output_50)
    variable num_outputs : natural;
    variable phase_error : time;
    variable max_phase_error : time;
    variable min_phase_error : time;
    variable waiting : boolean := TRUE;
    variable first_time : time := 0 fs;
  begin
    if (async_reset = '1') then
      num_outputs := 0;
      phase_error := 0 fs;
      max_phase_error := -1 hr;
      min_phase_error := +1 hr;
      measured_jitter <= 0 fs;
      waiting := TRUE;
    elsif (rising_edge(output_50)) then
      if (waiting) then
        -- don't take any measurements until after the first output pulse
        waiting := FALSE;
        first_time := now;
      else
        num_outputs := num_outputs + 1;
        measured_frequency <= real(num_outputs) / real((now - first_time) / clock_half_period) * fin * 2.0;
        phase_error := (((real(num_outputs) * ideal_ratio) * clock_period) - (now - first_time));
        if (phase_error > max_phase_error) then
          max_phase_error := phase_error;
          measured_jitter <= max_phase_error - min_phase_error;
        end if;
        if (phase_error < min_phase_error) then
          min_phase_error := phase_error;
          measured_jitter <= max_phase_error - min_phase_error;
        end if;
      end if;
    end if;
  end process measure_frequency;
end generate measure_50;

--------------------------------------------------------------------------------
-- Measure the min/avg/max duty cycle of the "50%" duty cycle output.
-- Note that times are turned into integers by dividing them by another time,
-- and if we use the (FAQ suggested) value of 1 fs, we will get overflow
-- problems after 2.1 us.  Hence the division by half the clock period.
--------------------------------------------------------------------------------
measure_duty_cycle : process (async_reset, output_50)
  variable total_time_high : time := 0 fs;
  variable total_time_low : time := 0 fs;
  variable last_rising : time := 0 fs;
  variable last_falling : time := 0 fs;
  variable pw_high : time := 0 fs;
  variable pw_low : time := 0 fs;
  variable duty_cycle : real;
  variable duty_cycle_min : real := 1.0;
  variable duty_cycle_max : real := 0.0;
begin
  if (async_reset = '1') then
    measured_duty_cycle_min <= 0.0;
    measured_duty_cycle_avg <= 0.0;
    measured_duty_cycle_max <= 0.0;
    duty_cycle_min := 1.0;
    duty_cycle_max := 0.0;
  else
    if (rising_edge(output_50)) then
      if (last_falling > 0 fs) then
        pw_low := now - last_falling;
        total_time_low := total_time_low + pw_low;
        measured_duty_cycle_avg <= real(total_time_high / clock_half_period) /
                             real((total_time_high + total_time_low) / clock_half_period);
      end if;
      last_rising := now;
    end if;
    if (falling_edge(output_50)) then
      if (last_rising > 0 fs) then
        pw_high := now - last_rising;
        total_time_high := total_time_high + pw_high;
        if (pw_low > 0 fs) then
          duty_cycle := real(pw_high / clock_half_period) /
                        real((pw_high + pw_low) / clock_half_period);
          if (duty_cycle < duty_cycle_min) then
            duty_cycle_min := duty_cycle;
            measured_duty_cycle_min <= duty_cycle_min;
          end if;
          if (duty_cycle > duty_cycle_max) then
            duty_cycle_max := duty_cycle;
            measured_duty_cycle_max <= duty_cycle_max;
          end if;
        end if;
      end if;
      last_falling := now;
    end if;
  end if;
end process measure_duty_cycle;

--------------------------------------------------------------------------------
-- Process to check that output_50 and output_pulse are the same frequency.
-- (to check that the duty cycle correction doesn't miss pulses, glitch, etc.)
-- Comparison is disabled when output_50 is not driven, as is the case when
-- fin/fout <= 2.  (VHDL gives 'U' and Verilog gives 'Z')
-- There is no explicit test; the error is detected when the variable
-- 'phase_difference' goes out of range.
-- Note that certain versions of Modelsim have the range checking turned off
-- by default.
--------------------------------------------------------------------------------
check_output_phase : process (async_reset, output_50, clock)
  variable phase_difference : integer range -1 to +1 := 0;
begin
  if (async_reset = '1') then
    phase_difference := 0;
  else
    if (rising_edge(clock)) then
      if (output_pulse = '1' and output_50 /= 'U' and output_50 /= 'Z') then
        phase_difference := phase_difference + 1;
      end if;
    end if;
    if (rising_edge(output_50)) then
        phase_difference := phase_difference - 1;
    end if;
  end if;
end process check_output_phase;

end testbench;
--------------------------------------------------------------------------------
-- <EOF> tb_fracn09.vhd
--------------------------------------------------------------------------------
