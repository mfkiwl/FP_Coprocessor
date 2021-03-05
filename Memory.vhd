library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Memory is
  Port (
  clk : in STD_LOGIC;
  rst : in STD_LOGIC;
  WriteEnable : in STD_LOGIC;
  memEN : in STD_LOGIC;
  pcEN : in STD_LOGIC;
  Address : in STD_LOGIC_VECTOR (9 downto 0); --need 10 bits for 1024 addresses
  DataWrite: in STD_LOGIC_VECTOR (31 downto 0);
  DataRead: out STD_LOGIC_VECTOR (31 downto 0); --reads data
  InstRead : out STD_LOGIC_VECTOR (31 downto 0) --reads instructions
   );
end Memory;

architecture Behavioral of Memory is
    type memArray is array(0 to 1023) of STD_LOGIC_VECTOR(31 downto 0); --Create array of 1024 addresses each of 32 bit length
    signal memory : memArray;

begin

    process(clk, rst)
     
    begin
    if rst = '1' then
        for i in 0 to 1024 loop
            memory(i) <= "00000000000000000000000000000000";    --reset memory
        end loop;
    end if;   
--FIRST FILE TEST
--    memory(0) <= "00000101100000000000000000000000"; --set r11
--    memory(1) <= "00000000000000000000000001100100"; --100 in binary
--    memory(2) <= "00000000000000000000000000000000"; --set r0
--    memory(3) <= "01000010110010000000000000000000"; --100 in fp format
--    memory(4) <= "00001000110110000000000000000000"; --load r1, r11
--    memory(5) <= "00000001000000000000000000000000"; --set r2
--    memory(6) <= "01000001100100000000000000000000"; --18.0 in FP format
--   memory(7) <= "00000001100000000000000000000000"; --set r3
--    memory(8) <= "01000000110100000000000000000000"; --6.5 in FP format
--    memory(9) <= "00000010000000000000000000000000"; --set r4
--    memory(10) <= "01000011010000000000000000000000"; --192 in FP format
--    memory(11) <= "00111010100100000000000000000000"; --FMUL r5, r2, r0
--    memory(12) <= "00111011000110000000000000000000"; --FMUL r6, r3, r0
--    memory(13) <= "01000011101010110000000000000000"; --FDIV r7, r5, r6
--    memory(14) <= "00000100000000000000000000000000"; --set r8
--    memory(15) <= "01000000000000000000000000000000"; --2 in fp format
--   memory(16) <= "00000100100000000000000000000000"; --set r9
--    memory(17) <= "00111111100000000000000000000000"; --1 in fp format
--    memory(18) <= "00101101010001001000000000000000"; --FSUB r10, r8, r9
--    memory(19) <= "00100100110011001000000000000000"; --ADD r9, r9, r9
--    memory(20) <= "10100101000000000000000000000000"; --BN r10
--    memory(100) <= "01000000010010010000111111010000";

--SECOND FILE TEST
    memory(0)  <= "00000000000000000000000000000000"; --set r0
    memory(1)  <= "01000101101001010110001110101110"; --5292.46 in FP format    
    memory(2)  <= "00000000100000000000000000000000"; --set r1
    memory(3)  <= "00111111110011100001010001111011"; --1.61 in fp format
    memory(4)  <= "00111001000000001000000000000000"; --FMUL r2, r0, r1
    memory(5)  <= "01010001100100000000000000000000"; --CEIL r3, r2
    memory(6)  <= "11110000000000000000000000000000"; --NOP
    memory(7)  <= "10100001100000000000000000000110"; --BN r3, 5
    memory(8)  <= "00000010000000000000000000000000"; --set r4
    memory(9)  <= "01000010010001000000000000000000"; --49 in FP format
    memory(10) <= "01101010100110100000000000000000"; --MIN r5, r3, r4
    memory(11) <= "00000101000000000000000000000000"; --set r10
    memory(12) <= "00000000000000000000000000000000"; --0
    memory(13) <= "10010101000000000000000000000000"; --B r10
    
   if rising_edge(clk) then
          if WriteEnable = '1' then
            memory(to_integer(unsigned(Address))) <= DataWrite;
          end if;
          if memEN = '1' then
            DataRead <= memory(to_integer(unsigned(Address)));   
          end if;
          if pcEN = '1' then
            InstRead <= memory(to_integer(unsigned(Address)));
          end if;
    end if;
    end process;  
    
--DataRead <= memory(to_integer(unsigned(Address)));     

end Behavioral;
