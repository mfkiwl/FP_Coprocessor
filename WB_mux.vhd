library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity WB_mux is
Port ( 
        S : in STD_LOGIC;
        u : in STD_LOGIC_VECTOR(31 downto 0);
        v : in STD_LOGIC_VECTOR(31 downto 0);
        o : out STD_LOGIC_VECTOR(31 downto 0)
);
end WB_mux;

architecture Behavioral of WB_mux is

begin
    process(s, u , v)
    begin
        if S = '1' then
            o <= v;
        else
            o <= u;
        end if;
    end process;
end Behavioral;
