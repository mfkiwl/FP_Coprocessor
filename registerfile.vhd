library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VComponents.all;

entity registerfile is
  Port ( 
  clk : in STD_LOGIC;
  rst : in STD_LOGIC;
  inData : in STD_LOGIC_VECTOR(31 downto 0);
  writeEN : in STD_LOGIC;
  chooseA : in STD_LOGIC_VECTOR(3 downto 0);
  chooseB : in STD_LOGIC_VECTOR(3 downto 0);
  chooseWrite : in STD_LOGIC_VECTOR(3 downto 0);
  routA : out STD_LOGIC_VECTOR(31 downto 0);
  routB : out STD_LOGIC_VECTOR(31 downto 0)
  );    
end registerfile;

architecture Behavioral of registerfile is
    type regArray is array(0 to 15) of STD_LOGIC_VECTOR(31 downto 0); --Create array of 16 registers
    signal reg : regArray;      
begin
    process(clk, writeEn, rst)
    begin
        if rst = '1' then
            for i in 0 to 15 loop
                reg(i) <= "00000000000000000000000000000000";           --clears reg file
            end loop;
        end if;
        if rising_edge(clk) then 
          routA <= reg(to_integer(unsigned(chooseA)));  --Sends data to outputs when clock is high
          routB <= reg(to_integer(unsigned(chooseB)));       
        if writeEN = '1' then
          reg(to_integer(unsigned(chooseWrite))) <= inData;
        end if;
        end if;
       end process;

end Behavioral;
