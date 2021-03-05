library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity PCorALU_mux is
 Port( 
    SET : in STD_LOGIC;
    pc : in STD_LOGIC_VECTOR(9 downto 0);
    alu : in STD_LOGIC_VECTOR(31 downto 0);
    mux : out STD_LOGIC_VECTOR(9 downto 0)
 );
end PCorALU_mux;

architecture Behavioral of PCorALU_mux is

begin
    process(SET, pc, alu)
    begin
        if SET = '1' then
            mux <= alu(9 downto 0);
        else
            mux <= pc;
        end if;
    end process;

end Behavioral;
