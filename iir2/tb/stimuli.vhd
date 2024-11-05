----------------------------------------------------------------------------------
-- Module Name: stimuli
-- Testing the IIR2 implementation
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TOP;

entity stimuli is
end stimuli;

architecture behavioral of stimuli is
  constant HALF_PERIOD : time := 5ns; 
  signal CLK           : std_logic := '0';
  signal RESETN        : std_logic := '0';
  signal DONE          : boolean := false;
  
  signal XIN           : signed(15 downto 0); -- Q2.14
  signal A2            : signed(23 downto 0); -- Q8.16
  signal A3            : signed(23 downto 0); -- Q8.16
  signal B1            : signed(23 downto 0); -- Q8.16
  signal B2            : signed(23 downto 0); -- Q8.16
  signal B3            : signed(23 downto 0); -- Q8.16
  signal YOUT          : signed(31 downto 0); -- Q2.30
  signal Y             : real;
begin
  UUT: entity TOP(rtl)
    port map(
      CLK => CLK,
      RESETN => RESETN,
      XIN => XIN,
      A2 => A2,
      A3 => A3,
      B1 => B1,
      B2 => B2,
      B3 => B3,
      YOUT => YOUT
    );

  reset_process: process is
  begin
    wait for 4*HALF_PERIOD;
    RESETN <= '1';
    wait;
  end process;
  
  clock_process: process is
  begin
    loop
      wait for HALF_PERIOD;
      CLK <= not CLK;
      if DONE then
        exit;
      end if;
    end loop;
    wait;
  end process;
  
  stimuli_process : process is
    constant   IN_EXP: real := 2.0**14;
    constant COEF_EXP: real := 2.0**16;
    constant  OUT_EXP: real := 2.0**30;
  begin
    -- A and B coefficients for Butterworth 2nd-order IIR LPF filter with a
    -- cutoff at 1/4-th of Nyquist frequency (1/8-th of sampling frequency)
    
    A2  <= to_signed(integer(-0.942809041582063 * COEF_EXP), 24);
    A3  <= to_signed(integer( 0.333333333333333 * COEF_EXP), 24);
    B1  <= to_signed(integer( 0.097631072937818 * COEF_EXP), 24);
    B2  <= to_signed(integer( 0.195262145875635 * COEF_EXP), 24);
    B3  <= to_signed(integer( 0.097631072937818 * COEF_EXP), 24);
    
    -- Impulse input signal. Should be driven to zero after 1 clock cycle
    -- after reset deassertion.

    XIN <= to_signed(integer( 1.0               *   IN_EXP), 16);
    
    wait until rising_edge(RESETN);

    report " X:" & real'image(real(to_integer( XIN)) /   IN_EXP);
    report "A2:" & real'image(real(to_integer(  A2)) / COEF_EXP);
    report "A3:" & real'image(real(to_integer(  A3)) / COEF_EXP);
    report "B1:" & real'image(real(to_integer(  B1)) / COEF_EXP);
    report "B2:" & real'image(real(to_integer(  B2)) / COEF_EXP);
    report "B3:" & real'image(real(to_integer(  B3)) / COEF_EXP);
    
    -- The first impulse sample will be captured here.
    
    wait until rising_edge(CLK);

    -- The first 16 impulse response samples of the Butterworth IIR filter:    
    --  9.76310729378175E-02
    --  2.87309604180767E-01
    --  3.35965474513536E-01
    --  2.20981418970514E-01
    --  9.63547883225230E-02
    --  1.71836926400290E-02
    -- -1.59173219853878E-02
    -- -2.07348926322729E-02
    -- -1.42432702548110E-02
    -- -6.51705310050832E-03
    -- -1.39657983602601E-03
    --  8.55642936806256E-04
    --  1.27223450919544E-03
    --  9.14259886013426E-04
    --  4.37894317157432E-04
    --  1.08097426135622E-04

    wait until falling_edge(CLK);
    Y <= real(to_integer(YOUT)) / OUT_EXP;
    report  "Y:" & real'image(Y);

    -- The rest of the impulse signal will now be zero for subsequent cycles.
    
    XIN <= to_signed(integer(0.0 * IN_EXP), 16);
    for i in 2 to 16 loop
      wait until falling_edge(CLK);
      Y <= real(to_integer(YOUT)) / OUT_EXP;
      report  "Y:" & real'image(Y);
    end loop;
    DONE <= true;
    wait;
  end process;
end behavioral;
