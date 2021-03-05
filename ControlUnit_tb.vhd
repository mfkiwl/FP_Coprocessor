library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnit_tb is

end ControlUnit_tb;

architecture Behavioral of ControlUnit_tb is
component ControlUnit is
Port(
        clk : in STD_LOGIC;                         --clk signal
        RESET : in STD_LOGIC;                       --resets all data    
        program_count : out STD_LOGIC_VECTOR(9 downto 0);
        instruction : out STD_LOGIC_VECTOR(31 downto 0);
        Opcode : out STD_LOGIC_VECTOR(4 downto 0);
        Reg_A : out STD_LOGIC_VECTOR(3 downto 0);
        Reg_B : out STD_LOGIC_VECTOR(3 downto 0);
        Reg_Destination : out STD_LOGIC_VECTOR(3 downto 0);    
        A_data : out STD_LOGIC_VECTOR(31 downto 0);
        B_data : out STD_LOGIC_VECTOR(31 downto 0);
        ALU_RESUlT : out STD_LOGIC_VECTOR(31 downto 0);
        inst_read : out STD_LOGIC;
        memory_read : out STD_LOGIC;      
        memWrite_EN : out STD_LOGIC;
        regWrite_EN : out STD_LOGIC;
        stop_program : out STD_LOGIC;
        to_branch : out STD_LOGIC;
        sc : out STD_LOGIC_VECTOR(2 downto 0)
        );
end component;


signal clk, RESET, inst_read, memory_read, memWrite_EN, regWrite_EN, stop_program, to_branch : STD_LOGIC := '0';
signal instruction, A_data, B_data, ALU_RESULT : STD_LOGIC_VECTOR(31 downto 0);
signal program_count : STD_LOGIC_VECTOR(9 downto 0);
signal sc : STD_LOGIC_VECTOR(2 downto 0);
signal Opcode : STD_LOGIC_VECTOR(4 downto 0);
signal Reg_A, Reg_B, Reg_Destination : STD_LOGIC_VECTOR(3 downto 0);
constant clk_period : time := 300ns;    --time for all 5 stages

begin
    
    uut: ControlUnit port map(clk => clk, RESET => RESET, program_count => program_count, instruction => instruction, Opcode => Opcode, Reg_A => Reg_A, Reg_B => Reg_B, Reg_Destination => Reg_Destination, A_data => A_data, B_data => B_data,
                             ALU_RESULT => ALU_RESULT, inst_read => inst_read, memory_read => memory_read, memWrite_EN => memWrite_EN, regWrite_EN => regWrite_EN,
                             stop_program => stop_program, to_branch => to_branch, sc => sc);    
    
                              
clock : process --clock process
        begin 
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;    
        end process;


end Behavioral;
