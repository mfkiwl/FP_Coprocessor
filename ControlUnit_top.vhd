library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--unpipelined
entity ControlUnit is
    Port (
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
end ControlUnit;

architecture Behavioral of ControlUnit is

component PC is
Port (
  clk : in STD_LOGIC;
  rst : in STD_LOGIC;
  in_ADD : in STD_LOGIC_VECTOR(9 downto 0);
  out_ADD : out STD_LOGIC_VECTOR(9 downto 0)
);
end component;

component Memory is 
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
end component;

component registerfile is 
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
end component;

component ALU is 
Port(
  a : in STD_LOGIC_VECTOR (31 downto 0);
  b : in STD_LOGIC_VECTOR (31 downto 0);
  aluOP : in STD_LOGIC_VECTOR (4 downto 0);
  result : out STD_LOGIC_VECTOR (31 downto 0);
  zf : out STD_LOGIC;
  nf : out STD_LOGIC;
  vf : out STD_LOGIC;
  ef : out STD_LOGIC
);
end component;

component PCorALU_mux is
Port(
    SET : in STD_LOGIC;
    pc : in STD_LOGIC_VECTOR(9 downto 0);
    alu : in STD_LOGIC_VECTOR(31 downto 0);
    mux : out STD_LOGIC_VECTOR(9 downto 0)
    );
end component;

component alusrc_mux is 
Port ( 
    choose : in STD_LOGIC;
    x : in STD_LOGIC_VECTOR(31 downto 0);
    y : in STD_LOGIC_VECTOR(18 downto 0);
    r : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component WB_mux is
Port ( 
    S : in STD_LOGIC;
    u : in STD_LOGIC_VECTOR(31 downto 0);
    v : in STD_LOGIC_VECTOR(31 downto 0);
    o : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component PorB_mux is
Port ( 
    c : in STD_LOGIC;
    p_n : in STD_LOGIC_VECTOR (9 downto 0);
    b_n : in STD_LOGIC_VECTOR (9 downto 0);
    f : out STD_LOGIC_VECTOR (9 downto 0)
);
end component;

--control signals
signal aluI : STD_LOGIC_VECTOR(4 downto 0);
signal PCorALU, pcRead, memRead, memWrite, regWrite, MEMorALU, PCorB, ALUSrc, HALT : STD_LOGIC := '0';
--flags
signal Z, N, V, E : STD_LOGIC := '0';

signal pc_address, pc_next : STD_LOGIC_VECTOR(9 downto 0) := "0000000000";
signal next_instruction, mux_address : STD_LOGIC_VECTOR(9 downto 0);
signal regAdata, regBdata, src_mux, data_mem, data_alu, write_back, inst : STD_LOGIC_VECTOR(31 downto 0);
signal Op : STD_LOGIC_VECTOR(4 downto 0);
signal Rd, Ri, Rj : STD_LOGIC_VECTOR(3 downto 0);
signal integer_value : STD_LOGIC_VECTOR(18 downto 0);
signal branch_address : STD_LOGIC_VECTOR(9 downto 0);
signal STEP : STD_LOGIC_VECTOR(2 downto 0) := "000";

begin  

P_C : PC port map(clk => clk, rst => RESET, in_ADD => next_instruction, out_ADD => pc_address);
Mem : Memory port map(clk => clk, rst => RESET, WriteEnable => memWrite, memEN => memRead, pcEN => pcRead, Address => mux_address, DataWrite => regBdata, DataRead => data_mem,
      InstRead => inst);
Reg : registerfile port map(clk => clk, rst => RESET, inData => write_back, writeEN => regWrite, chooseA => Ri, chooseB => Rj, chooseWrite => Rd, routA => regAdata, routB => regBdata);
AL_unit : ALU port map(a => regAdata, b => src_mux, aluOP => aluI, result => data_alu, zf => Z, nf => N, vf => V, ef => E); 
mux_1 : PCorALU_mux port map(SET => PCorALU, pc => pc_address, alu => data_alu, mux => mux_address);
mux_2 : alusrc_mux port map(choose => ALUSrc, x => regBdata, y => integer_value, r => src_mux);
mux_3 : WB_mux port map(S => MEMorALU, u => data_alu, v => data_mem, o => write_back);
mux_4 : PorB_mux port map(c => PCorB, p_n => pc_next, b_n => branch_address, f => next_instruction);

step_counter : process(clk) 
    variable step_num : STD_LOGIC_VECTOR(2 downto 0) := "000";
    variable BZ : STD_LOGIC := '0';
    variable BN : STD_LOGIC := '0'; --variables for branch
    variable B : STD_LOGIC := '0';
    begin   
    if HALT = '1' then
        step_num := "000";
    else
    if rising_edge(clk) then
        case step_num is
        when "000" =>
            step_num := "001";
        when "001" =>
            step_num := "010";
        when "010" =>               --counts through FDXMW steps
            step_num := "011";
        when "011" =>
            step_num := "100";
        when "100" =>
            step_num := "000";
        when others =>
            step_num := "000";
        end case;
    end if;
    end if;
    STEP <= step_num;
    sc <= STEP;
--end process;

--execution : process(clk)

--variable BZ : STD_LOGIC := '0';
--variable BN : STD_LOGIC := '0'; --variables for branch
--variable B : STD_LOGIC := '0';

   -- begin

case STEP is 
     when "000" =>  --fetch
        PCorALU <= '0';    --reset all control signals
        pcRead <= '0';
        memRead <= '0';
        memWrite <= '0'; 
        regWrite <= '0'; 
        MEMorALU <= '0'; 
        PCorB <= '0'; 
        ALUSrc <= '0'; 
        BZ := '0';
        BN := '0';
        B := '0';
        to_branch <= PCorB;
        memory_read <= memRead;
        memWrite_EN <= memWrite;
        regWrite_EN <= regWrite;
        program_count <= pc_address;
        pc_next <= pc_address;
        pcRead <= '1';         --reads instruction from pc counter address
        inst_read <= pcRead;   --output to waveform graph
            
     when "001" =>  --decode
        instruction <= inst;
        Op <= inst(31 downto 27);
        Rd <= inst(26 downto 23);    --breaks up instruction where needed
        Ri <= inst(22 downto 19);
        Rj <= inst(18 downto 15);
        Opcode <= Op;
        Reg_A <= Ri;
        Reg_B <= Rj;
        Reg_Destination <= Rd;
        integer_value <= inst(18 downto 0);
        branch_address <= inst(9 downto 0);
        case Op is 
            when "01111" =>     --*POWER*
            ALUSrc <= '1';      --send int value to alu
            when "10010" =>     --*Branch(uncond.)*     
            B := '1';
            when "10011" =>     --*branch zero*       
            BZ := '1';
            when "10100" =>     --*branch negative*       
            BN := '1';
            when "11111" =>     --*HALT*
            HALT <= '1';    
            when others =>
            null;               --dont need to do anything to next stage   
        end case;   
     A_data <= regAdata; --output to waveform graph
     B_data <= regBdata;
        
     when "010" =>   --execute
        aluI <= Op; --alu has data now gets instruction to execute
        if Op = "00000" then
            pc_next <= STD_LOGIC_VECTOR(unsigned(pc_next) + "0000000001");   --go to next address where FP value is stored
            program_count <= pc_next;
        end if;
        --now have alu results for branch
        if (Op = "10010") or (Op = "10011") or (Op = "10100") then
        PCorB <= B OR (BZ AND z) OR (BN AND n);     --logic for branch instruction
        end if;
        to_branch <= PCorB;
        ALU_RESULT <= data_alu;     
        stop_program <= HALT;
        
     when "011" =>   --memory
        case Op is
            when "00000" => --*SET*
                memRead <= '1';   
                PCorALU <= '0';              
            when "00001" => --*LOAD*
                PCorALU <= '1';     --chooses address from alu
                memRead <= '1';     --reads from mem 
            when "00010" => --*STUR*
                PCorALU <= '1';     --choose address from alu
                memWrite <= '1';    --writes to mem
            when others =>
                null;               --other instructions dont access mem
        end case;
        memory_read <= memRead;
        memWrite_EN <= memWrite;
        
     when "100" =>   --write back
        case Op is 
            when "00000" => --*SET*
            MEMorALU <= '1';
            regWrite <= '1';
            when "00001" => --*LOAD*
            MEMorALU <= '1';    --writes back from mem
            regWrite <= '1';    
            when "00010" => --*STUR*
            regWrite <= '0'; --doesnt write to register
            when "10010" =>  --Branch uncond.
            regWrite <= '0'; --doesnt write to register
            when "10011" =>  --branch zero
            regWrite <= '0'; --doesnt write to register          
            when "10100" =>  --branch negative
            regWrite <= '0'; --doesnt write to register            
            when "11110" =>  --no op   
            regWrite <= '0';  
            when "11111" =>  --HALT
            regWrite <= '0';
            when others =>
            MEMorALU <= '0';  --all other instructions reads from alu
            regWrite <= '1';  --and write back
        end case;
     regWrite_EN <= regWrite;
     if Op /= "00000" then   
     pc_next <= STD_LOGIC_VECTOR(unsigned(pc_next) + "0000000001"); --increment pc    
     end if;
     when others =>
        null;
     end case;
    end process;        
end Behavioral;
