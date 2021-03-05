library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity PC is
  Port (
  clk : in STD_LOGIC;
  rst : in STD_LOGIC;
  in_ADD : in STD_LOGIC_VECTOR(9 downto 0);
  out_ADD : out STD_LOGIC_VECTOR(9 downto 0)
   ); 
end PC;

architecture Behavioral of PC is

signal pcV : unsigned(9 downto 0) := "0000000000";  --register to store address
begin
    process(clk, rst)
    begin 
    out_ADD <= STD_LOGIC_VECTOR(pcV);
        if rst = '1' then                               --resets register;
            pcV <= "0000000000";
        end if;
        if rising_edge(clk) then    --when clock is high read address   
        pcV <= unsigned(in_ADD);
        end if;
    end process;    
end Behavioral;
