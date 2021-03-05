library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PorB_mux is
Port ( 
       c : in STD_LOGIC;
       p_n : in STD_LOGIC_VECTOR (9 downto 0);
       b_n : in STD_LOGIC_VECTOR (9 downto 0);
       f : out STD_LOGIC_VECTOR (9 downto 0)
);
end PorB_mux;

architecture Behavioral of PorB_mux is

begin
process(c, p_n, b_n)
begin
    if c = '1' then
        f <= b_n;
    else 
        f <= p_n;
    end if;
end process;
end Behavioral;
