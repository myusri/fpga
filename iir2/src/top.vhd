----------------------------------------------------------------------------------
-- Module Name: top
-- The top module
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.IIR2;

-- Attempting to infer efficient use DSP48 slices efficiently. DSP48 does 25b x 18b
-- multiply with 48b accumulator.

entity TOP is
 port (
    CLK    : in  std_logic;
    RESETN : in  std_logic;
    YOUT   : out signed(31 downto 0); -- Q2.30
    XIN    : in  signed(15 downto 0); -- Q2.14
    A2     : in  signed(23 downto 0); -- Q8.16
    A3     : in  signed(23 downto 0); -- Q8.16
    B1     : in  signed(23 downto 0); -- Q8.16
    B2     : in  signed(23 downto 0); -- Q8.16
    B3     : in  signed(23 downto 0)  -- Q8.16
 );
end top;

architecture rtl of TOP is
begin
  IIRA: entity IIR2(rtl)
    generic map (
    IN_BITS    => 16, -- Q2.14  - 16b input data (X), normalized to 
    IN_POINT   => 14, --          [-1.0, +1.0], with 1b guard.
    GAIN_BITS  => 16, -- Q2.14  - GAIN*X, but we keep gain coef at 1.0 and
    GAIN_POINT => 14, --          keep the result at 16b still.
    COEF_BITS  => 24, -- Q8.16  - Allow 8b integer part (+sign) and 16b
    COEF_POINT => 16, -- Q8.16    fractional part
    MUL_BITS   => 40, -- Q10.30 - COEF*GAIN*X, 10b integer part (+sign) and
    MUL_POINT  => 30, --          30b fractional part.
    ACC_BITS   => 48, -- Q18.30 - allow 8 guard bits to accumulate
    ACC_POINT  => 30, -- 
    OUT_BITS   => 32, -- Q2.30  - 32b output (Y), with 1b guard.
    OUT_POINT  => 30  --
    )
    port map (
      CLK    => CLK,
      RESETN => RESETN,
      YOUT   => YOUT,
      XIN    => XIN,
      GAIN   => x"010000",
      A2     => A2,
      A3     => A3,
      B1     => B1,
      B2     => B2,
      B3     => B3
    );   
end rtl;
