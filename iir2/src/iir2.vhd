----------------------------------------------------------------------------------
-- Module Name: iir2
-- Second-order Infinite Impulse Response Filter
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 2nd-order IIR filter with an input gain.
-- Transfer function:
-- H(z) = Y(z) / X(z)
--      = ( B1 + B2 * z^-1 + B3 * z^-2 )
--      / (  1 + A2 * z^-1 + A3 * Z^-2 )

entity IIR2 is
  generic (
    IN_BITS    : natural := 32;  -- Q16.16 - X input
    IN_POINT   : natural := 16;
    GAIN_BITS  : natural := 64;  -- Q32.32 - GAIN*X
    GAIN_POINT : natural := 32;
    COEF_BITS  : natural := 32;  -- Q16.16 - COEF (GAIN, A2, A3, B1, B2, B3)
    COEF_POINT : natural := 16;
    MUL_BITS   : natural := 96;  -- Q48.48 - COEF*GAIN*X
    MUL_POINT  : natural := 48;    
    ACC_BITS   : natural := 104; -- Q56.48 - Feedback, allow 8b guard
    ACC_POINT  : natural := 48;
    OUT_BITS   : natural := 32;  -- Q16.16 - Y output
    OUT_POINT  : natural := 16
  );
  port (
    CLK    : in  std_logic;
    RESETN : in  std_logic;
    YOUT   : out signed( OUT_BITS-1 downto 0);
    XIN    : in  signed(  IN_BITS-1 downto 0);
    GAIN   : in  signed(COEF_BITS-1 downto 0);
    A2     : in  signed(COEF_BITS-1 downto 0);
    A3     : in  signed(COEF_BITS-1 downto 0);
    B1     : in  signed(COEF_BITS-1 downto 0);
    B2     : in  signed(COEF_BITS-1 downto 0);
    B3     : in  signed(COEF_BITS-1 downto 0)
  );
end IIR2;

-- Direct Form I of the transfer function:
-- y[n] = B1*x[n] + B2*x[n-1] + B3*x[n-2]
--                - A2*y[n-1] - A3*y[n-2]

architecture rtl of IIR2 is
  signal D1              : signed(ACC_BITS-1 downto 0);
  signal D2              : signed(ACC_BITS-1 downto 0);
  
  constant XG_FULL_BITS  : natural := COEF_BITS+IN_BITS;
  constant XG_FULL_POINT : natural := COEF_POINT+IN_POINT;
  constant YA_FULL_BITS  : natural := COEF_BITS+ACC_BITS;
  constant YA_FULL_POINT : natural := COEF_POINT+ACC_POINT;
begin
  process (CLK)
    variable XG_FULL  : signed(XG_FULL_BITS-1 downto 0);
    variable XG       : signed(   GAIN_BITS-1 downto 0);
    variable XGB1     : signed(    MUL_BITS-1 downto 0);
    variable XGB2     : signed(    MUL_BITS-1 downto 0);
    variable XGB3     : signed(    MUL_BITS-1 downto 0);
    
    variable YA2_FULL : signed(YA_FULL_BITS-1 downto 0);
    variable YA3_FULL : signed(YA_FULL_BITS-1 downto 0);
    variable YA2      : signed(    ACC_BITS-1 downto 0);
    variable YA3      : signed(    ACC_BITS-1 downto 0);
    variable Y        : signed(    ACC_BITS-1 downto 0);
  begin
    if rising_edge(CLK) then
      if RESETN = '0' then
        D2   <= (others => '0');
        D1   <= (others => '0');
        YOUT <= (others => '0');
      else
        -- Input scaling. Ideally this should be binary scaling only (bit shift)
        
        XG_FULL := Xin * GAIN;
        XG := XG_FULL(GAIN_BITS+XG_FULL_POINT-IN_POINT-1 downto XG_FULL_POINT-IN_POINT);
        
        -- Feed forward multiplications
        
        XGB1 := XG * B1;
        XGB2 := XG * B2;
        XGB3 := XG * B3;
        
        -- Feedback multiplications
        
        Y    := XGB1 + D1;         -- with guard bits   
        YA2_FULL := Y * A2;
        YA3_FULL := Y * A3;
        
        YA2 := YA2_FULL(ACC_BITS+YA_FULL_POINT-ACC_POINT-1 downto YA_FULL_POINT-ACC_POINT);
        YA3 := YA3_FULL(ACC_BITS+YA_FULL_POINT-ACC_POINT-1 downto YA_FULL_POINT-ACC_POINT);

        -- Filter delays, summations, and an output pipeline register.

        D2   <= XGB3 - YA3;        -- with guard bits
        D1   <= D2 + XGB2 - YA2;   -- with guard bits
        YOUT <= Y(OUT_BITS+ACC_POINT-OUT_POINT-1 downto ACC_POINT-OUT_POINT);                
      end if;
    end if;    
  end process;
end rtl;
