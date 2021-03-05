library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity alusrc_mux is
Port ( 
        choose : in  STD_LOGIC;
        x   : in  STD_LOGIC_VECTOR(31 downto 0);
        y   : in  STD_LOGIC_VECTOR(18 downto 0);
        r : out STD_LOGIC_VECTOR(31 downto 0)
);
end alusrc_mux;

architecture Behavioral of alusrc_mux is

begin

    process(choose, x, y)
        begin
        if choose = '1' then
            r(18 downto 0) <= y;
        else
            r <= x;
        end if;
    end process;           

end Behavioral;
