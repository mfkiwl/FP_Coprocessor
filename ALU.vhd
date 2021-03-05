library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


entity ALU is
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
end ALU;

architecture Behavioral of ALU is

begin
process(a, b, aluOP)
    variable resultV : STD_LOGIC_VECTOR(31 downto 0); -- variable for result operations
    variable expA, expB, expR, expT, expK : unsigned(7 downto 0); --exponent of fp value
    variable mantA, mantB, mantR : unsigned(26 downto 0);  --mantissa of fp value
    variable mantTemp, tempA, tempB : unsigned(27 downto 0); 
    variable wBin : unsigned(1 downto 0);          --for operations that arent bit by bit 
    variable fpW, fpD : unsigned(31 downto 0);          --for operations that arent bit by bit
    variable dBin : unsigned(25 downto 0);         --for operations that arent bit by bit
    variable sigBin : unsigned(28 downto 0);       --for operations that arent bit by bit
    variable fpR : unsigned(63 downto 0);          --for operations that arent bit by bit
    variable intV : unsigned(18 downto 0);
    variable GRS : unsigned(2 downto 0); --rounding bits
    variable signA, signB, signR, zfv, nfv, efv, vfv : STD_LOGIC; 
    variable shiftA, shiftB, c, k, powA, powB, powR, wholeInt : integer;
    variable sumA, sumB, sumR, wholeNum : real;
begin
    zfv := '0';
    nfv := '0';
    vfv := '0';      --initialize flags
    efv := '0';
case aluOP is 
    when "00000" =>     --ALU does nothing *SET
        resultV := "00000000000000000000000000000000";
        efv := '0';
    
    when "00001" =>  --ALU passes mem address stored in Rj to address line of mem *LOAD*
        if a > "00000000000000000000001111111111" then      --not a memory location
            efv := '1';
        end if;
        resultV := a;
    
    when "00010" =>  -- mem location in a, value to store in b  *STORE*
        if a > "00000000000000000000001111111111" then          --not a memory location
            efv := '1';
        end if;
        resultV := a;  --have mux to pass b to DataWrite of mem

    when "00011" =>   --pass value of rj through alu then have alu write back to register write *MOVE*
        resultV := a;
        
    when "00100" =>  -- *ADD*
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        signB := b(31);             --breaking up fp
        expB := unsigned(b(30 downto 23));
        mantB(25 downto 3) := unsigned(b(22 downto 0));
        mantA(26) := '1';
        mantB(26) := '1';       --significand leads with 1
        mantA(2 downto 0) := "000";
        mantB(2 downto 0) := "000"; --initialize grs bits
        
if (expA = "00000000") and (mantA = "100000000000000000000000000") then
    signR := signB;                   -- addition of zero
    expR := expB;
    mantR := mantB;   
elsif (expB = "00000000") and (mantB = "100000000000000000000000000") then
    signR := signA;                   -- addition of zero
    expR := expA;
    mantR := mantA;    
elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
    signR := signA;    --addition of infinity
    expR := expA;
    mantR := mantA;
    efv := '1';
elsif (expB = "11111111") and (mantB = "100000000000000000000000000") then
    signR := signB;    --addition of infinity
    expR := expB;
    mantR := mantB;
    efv := '1';
elsif a(30 downto 0) = b(30 downto 0) then
    if(signA = '0') and (signB = '0') then
        signR := signA;
        expR := expA + "00000001";                    -- x + x = 2x 
        mantR := mantA;
    end if; 
    if(signA = '1') and (signB = '0') then
        signR := '0';
        expR := "00000000";                    -- (-x) + x = 0
        mantR := "000000000000000000000000000";
    end if;
    if(signA = '0') and (signB = '1') then
        signR := '0';
        expR := "00000000";                    -- x + (-x) = 0
        mantR := "000000000000000000000000000";
    end if;
    if(signA = '1') and (signB = '1') then
        signR := signA;
        expR := expA + "00000001";                    -- (-x) + (-x) = -2x
        mantR := mantA;
    end if;
elsif (a = "11111111100000000000000000000000") and (b = "01111111100000000000000000000000") then
    signR := '0';
    expR := "00000000";
    mantR := "000000000000000000000000000";                  -- negative infinity plus positive infinitiy = 0
elsif (b = "11111111100000000000000000000000") and (a = "01111111100000000000000000000000") then
    signR := '0';
    expR := "00000000";
    mantR := "000000000000000000000000000";
elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
    efv := '1';              --NaN
    signR := signA;
    expR := expA;
    mantR := mantA;
elsif (expB = "11111111") and (mantB /= "100000000000000000000000000") then
    efv := '1';              --NaN
    signR := signB;
    expR := expB;
    mantR := mantB;

else

    if (expA > expB) then
        expT := expA - expB;
        shiftB := to_integer(expT);
        shiftA := 0;      --check for difference of exponenets
        expR := expA;
        mantB := shift_right(mantB, shiftB); --align mantissa
    end if;
    
    if (expB > expA) then
        expT := expB - expA;
        shiftA := to_integer(expT); 
        shiftB := 0;   --store shift value to shift mantissa  
        expR := expB;
        mantA := shift_right(mantA, shiftA);
    end if;
    
    if (expA = expB)then
        expR := expA;
    end if;                                                                                                                                                                                                                                 
    
    if (signA = signB) then
        signR := signA;
        tempA := resize(mantA, 28);
        tempB := resize(mantB, 28);
        mantTemp := tempA + tempB;
        if mantTemp(27) = '1' then
            mantTemp := shift_right(mantTemp, 1); -- normalizing mantissa
            expR := expR + "00000001"; --add one to exponent for shift right
        end if;
        mantR := mantTemp(26 downto 0);        
     end if; 
     
     if (signA /= signB) then
        if (expA > expB) then
            signR := signA;             --determining sign of result
        end if;
        if (expB > expA) then
            signR := signB;
        end if;
        if(expA = expB) then
            signR := signB;
        end if;
        
         if (signA = '1') then
            tempA := resize(mantA, 28);
            tempB := resize(mantB, 28);
            for i in 0 to 27 loop
              tempA(i) := not tempA(i); --invert part of two's complement
            end loop;
            mantTemp := tempA + tempB + "0000000000000000000000000001"; --adding one for twos complement
            k := 0;
            while mantTemp(26) /= '1' loop
                mantTemp := shift_left(mantTemp, 1);
                k := k + 1;
            end loop;
         end if;
              
          if (signB = '1') then
             tempA := resize(mantA, 28);
             tempB := resize(mantB, 28);
             for i in 0 to 27 loop 
                tempB(i) := not tempB(i);
             end loop;
             mantTemp := tempA + tempB + "0000000000000000000000000001";
             k := 0;
             while mantTemp(26) /= '1' loop
                mantTemp := shift_left(mantTemp, 1);
                k := k + 1;
             end loop;
          end if;   
         mantR := mantTemp(26 downto 0);
         expK := to_unsigned(k, 8); 
         expR := expR - expK;
       end if;
end if;
       --round check
       GRS := mantR(2 downto 0);
       case GRS is
            when "000" =>
                mantR := mantR;
            when "100" =>
                if mantR(3) = '1' then
                    mantR := mantR + "000000000000000000000001000";
                else 
                    mantR := mantR;
                end if;
            when "101" =>
                mantR := mantR + "000000000000000000000001000";
            when "110" =>
                mantR := mantR + "000000000000000000000001000";
            when "111" => 
                mantR := mantR + "000000000000000000000001000";
            when others =>
                mantR := mantR;
       end case; 
       
       
resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));
       
if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "00000000000000000000000") then
    zfv := '1';
end if;
    
    when "00101" =>  --*SUBTRACT*
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        signB := b(31);             --breaking up fp
        expB := unsigned(b(30 downto 23));
        mantB(25 downto 3) := unsigned(b(22 downto 0));
        mantA(26) := '1';
        mantB(26) := '1';       --significand leads with 1
        mantA(2 downto 0) := "000";
        mantB(2 downto 0) := "000"; --initialize grs bits
        
if (expA = "00000000") and (mantA = "100000000000000000000000000") then
        signR :=  not signB;                   -- 0 minus something is opposit sign
        expR := expB;
        mantR := mantB;           
elsif (expB = "00000000") and (mantB = "100000000000000000000000000") then
        signR := signA;                   -- subtraction of zero is same answer
        expR := expA;
        mantR := mantA;
elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
    signR := signA;    --infinity minus anything is infinity
    expR := expA;
    mantR := mantA;
elsif (expB = "11111111") and (mantB = "100000000000000000000000000") then
    signR := not signB;    --subtraction of infinity
    expR := expB;
    mantR := mantB;
elsif (a = "01111111100000000000000000000000") and (b = "11111111100000000000000000000000") then
    signR := '0';
    expR := "11111111";         --+infiity - (-infinity) = infinity
    mantR := "000000000000000000000000000";                  
elsif (a = "11111111100000000000000000000000") and (b = "11111111100000000000000000000000") then
    signR := '0';
    expR := "00000000";             --(-infinity) - (-infinity) = 0
    mantR := "000000000000000000000000000";
elsif (a = "01111111100000000000000000000000") and (b = "01111111100000000000000000000000") then
    signR := '0';
    expR := "00000000";                 -- infinity - infinity = 0
    mantR := "000000000000000000000000000";                 
elsif (a = "11111111100000000000000000000000") and (b = "01111111100000000000000000000000") then
    signR := '1';
    expR := "11111111";                     -- (-infinity) - infinity = - infinity
    mantR := "000000000000000000000000000";                  
elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
    efv := '1';     
    signR := signA;         --NaN
    expR := expA;
    mantR := mantA;
elsif (expB = "11111111") and (mantB /= "100000000000000000000000000") then
    efv := '1';              --NaN
    signR := signB;         --NaN
    expR := expB;
    mantR := mantB;
elsif a(30 downto 0) = b(30 downto 0) then
    if(signA = '0') and (signB = '0') then
        signR := '0';
        expR := "00000000";                    --x - x = 0 
        mantR := "000000000000000000000000000";
    end if; 
    if(signA = '1') and (signB = '0') then
        signR := signA;
        expR := expA + "00000001";                    -- (-x) - x = -2x 
        mantR := mantA;
    end if;
    if(signA = '0') and (signB = '1') then
        signR := signA;
        expR := expA + "00000001";                    -- (-x) - x = -2x 
        mantR := mantA;
    end if;
    if(signA = '1') and (signB = '1') then
        signR := '0';
        expR := "00000000";                    -- (-x) - (-x) = 0 
        mantR := "000000000000000000000000000";
    end if;
else
    if (expA > expB) then
        expT := expA - expB;
        shiftB := to_integer(expT);      --check for difference of exponenets
        expR := expA;
        mantB := shift_right(mantB, shiftB); --align mantissa
    end if;

    if (expB > expA) then
        expT := expB - expA;
        shiftA := to_integer(expT);   --store shift value to shift mantissa  
        expR := expB;
        mantA := shift_right(mantA, shiftA);
    end if;
    
    if (expA = expB)then
        expR := expA;
    end if;
    
    if (signA = signB) then
        if(expB > expA) then
            signR := not signA;
        elsif(expA = expB) and (mantB > mantA) then
            signR := not signA;
        else 
            signR := signA;
        end if;
        tempA := resize(mantA, 28); 
        tempB := resize(mantB, 28); 
        for i in 0 to 27 loop 
            tempB(i) := not tempB(i);
        end loop;
        mantTemp := tempA + tempB + "0000000000000000000000000001";
        k := 0;
        while mantTemp(26) /= '1' loop
            mantTemp := shift_left(mantTemp, 1);
            k := k + 1;
        end loop;
        mantR := mantTemp(26 downto 0);
        expK := to_unsigned(k, 8); 
        expR := expR - expK;
    end if;    
    
    if (signA /= signB) then
        if(signA = '1') then
            signR := signA;
        elsif(signA = '0') then
            signR := signA;
        end if;
        tempA := resize(mantA, 28);
        tempB := resize(mantB, 28);
        mantTemp := tempA + tempB;
        if mantTemp(27) = '1' then
             mantTemp := shift_right(mantTemp, 1); -- normalizing mantissa
             expR := expR + "00000001"; --add one to exponent for shift right
        end if;
        mantR(26 downto 0) := mantTemp(26 downto 0);         
    end if;
end if;
    --round check
    GRS := mantR(2 downto 0);
    case GRS is
    when "000" =>
        mantR := mantR;
    when "100" =>
        if mantR(3) = '1' then
            mantR := mantR + "000000000000000000000001000";
        else 
            mantR := mantR;
        end if;
    when "101" =>
        mantR := mantR + "000000000000000000000001000";
    when "110" =>
        mantR := mantR + "000000000000000000000001000";
    when "111" => 
        mantR := mantR + "000000000000000000000001000";
    when others =>
        mantR := mantR;
    end case;
    
resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));
           
if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "00000000000000000000000") then
    zfv := '1';     --zero check
end if;

    when "00110" => --*NEGATE* inputs comes from read register 1 so "a"
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));            --breaking up fp        
        resultV(31) := not signA;
        resultV(30 downto 23) := STD_LOGIC_VECTOR(expA);
        resultV(22 downto 0) := STD_LOGIC_VECTOR(mantA(25 downto 3));    
        if(signR = '1') then
            nfv := '1';  --negative check
        end if;
        if(expR = "11111111") then
            vfv := '1';  --overflow check
        end if;
        if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
            vfv := '1';
        end if;
        if (expR = "00000000") and (mantR(25 downto 3) = "00000000000000000000000") then
            zfv := '1';     --zero check
        end if;   
    
    when "00111" => --*MULTIPLICATION*
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        signB := b(31);             --breaking up fp
        expB := unsigned(b(30 downto 23));
        mantB(25 downto 3) := unsigned(b(22 downto 0));
        mantA(26) := '1';
        mantB(26) := '1';       --significand leads with 1
        mantA(2 downto 0) := "000";
        mantB(2 downto 0) := "000"; --initialize grs bits
        sigBin := "00000000000000000000000000000"; --intialize sigBin
        
        if (expA = "00000000") and (mantA = "100000000000000000000000000") then
            signR := '0';                   -- multiplication of zero
            expR := "00000000";
            mantR := "000000000000000000000000000";           
        elsif (expB = "00000000") and (mantB = "100000000000000000000000000") then
            signR := '0';                   -- multiplication of zero
            expR := "00000000";
            mantR := "000000000000000000000000000";
        elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
            signR := signA XOR signB;
            expR := expA;           --multiplication of infinity
            mantR := mantA;
        elsif (expB = "11111111") and (mantB = "100000000000000000000000000") then
            signR := signA XOR signB;
            expR := expB;           --multiplication of infinity
            mantR := mantB;
        elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
            efv := '1';
            signR := signA;     --NaN
            expR := expA;
            mantR := mantA;
        elsif (expB = "11111111") and (mantB /= "100000000000000000000000000") then
            efv := '1';
            signR := signB;     --NaN
            expR := expB;
            mantR := mantB;
       
       else 
        signR := signA XOR signB;  --sets sign     
          
        powA := to_integer(expA);
        powB := to_integer(expB);
        powR := powA + powB - 127;   --add exponent value subtract bias
        
        sumA := 0.0;
        sumB := 0.0;  --initialize sums
        k := 1; --initialize increment
        for i in 25 downto 3 loop
            if mantA(i) = '1' then
                sumA := sumA + 2.0**(-k); --does decimal part of number
            end if;
            if mantB(i) = '1' then
                sumB := sumB + 2.0**(-k); --does decimal part of number
            end if;
            k := k + 1;
        end loop;
        sumA := sumA + 1.0;
        sumB := sumB + 1.0; --add first part of significand.
        sumR := sumA * sumB;     
        wholeNum := floor(sumR);    --returns the whole number part of result
        wholeInt := integer(wholeNum); --makes whole num integer to convert back to binary
        wBin := to_unsigned(wholeInt , 2);  --(max value of 3.999 base 10)
        sumR := sumR - wholeNum;        --leaves decimal part
        for i in 25 downto 0 loop
            sumR := sumR * 2.0;  
            if sumR > 1.0 then
                dBin(i) := '1';         --converting decimal part into binary
                sumR := sumR - 1.0;
            else
                dBin(i) := '0';
            end if;
        end loop;
        
        sigBin(27 downto 26) := wBin;   --putting together binary values
        sigBin(25 downto 0) := dBin;  --leave room for GRS
        
        GRS := sigBin(2 downto 0);   --round check
        case GRS is
        when "000" =>
            sigBin := sigBin;
        when "100" =>
            if sigBin(3) = '1' then
               sigBin := sigBin + "00000000000000000000000001000";
            else 
               sigBin := sigBin;
            end if;
        when "101" =>
            sigBin := sigBin + "00000000000000000000000001000";
        when "110" =>
            sigBin := sigBin + "00000000000000000000000001000";
        when "111" => 
            sigBin := sigBin + "00000000000000000000000001000";
        when others =>
            sigBin := sigBin;
        end case;      
        
        if sigBin(28) = '1' then              --normalizing
            sigBin := shift_right(sigBin, 2);
            powR := powR + 2;
        elsif sigBin(28 downto 27) = "01" then
            sigBin := shift_right(sigBin, 1);
            powR := powR + 1;
        else 
            sigBin := sigBin;
        end if;
            
            expR := to_unsigned(powR, 8); --back to binary
            mantR := sigBin(26 downto 0);
end if;
                
resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        

if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "00000000000000000000000") then
    zfv := '1';     --zero check
end if;

    when "01000" => --*DIVISION* 
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        signB := b(31);             --breaking up fp
        expB := unsigned(b(30 downto 23));
        mantB(25 downto 3) := unsigned(b(22 downto 0));
        mantA(26) := '1';
        mantB(26) := '1';       --significand leads with 1
        mantA(2 downto 0) := "000";
        mantB(2 downto 0) := "000"; --initialize grs bits
        sigBin := "00000000000000000000000000000"; --intialize sigBin
     
        if (expA = "00000000") and (mantA = "100000000000000000000000000") then
            signR := '0';                   -- 0 / x = 0
            expR := "00000000";
            mantR := "000000000000000000000000000";           
        elsif (expB = "00000000") and (mantB = "100000000000000000000000000") then
            efv := '1';
            signR := '0';                   -- x / 0 == NaN
            expR := "11111111";
            mantR := "000010000000000000000010000"; -- dont cares but can be all zero
        elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
            signR := signA XOR signB;
            expR := expA;           --infinity / x = infinity
            mantR := mantA;
        elsif (expB = "11111111") and (mantB = "100000000000000000000000000") then
            signR := '0';
            expR := "00000000";           --x / inf = 0
            mantR := mantB;
        elsif (a(30 downto 0) = "1111111100000000000000000000000") and (b(30 downto 0) = "1111111100000000000000000000000") then
            signR := signA XOR signB;
            expR := "01111111";             --inf/inf = 1;
            mantR := "100000000000000000000000000";
        elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
            efv := '1';
            signR := signA;     --NaN
            expR := expA;
            mantR := mantA;
        elsif (expB = "11111111") and (mantB /= "100000000000000000000000000") then
            efv := '1';
            signR := signB;     --NaN
            expR := expB;
            mantR := mantB;
               
        else
            signR := signA XOR signB;  --sets sign     
                 
            powA := to_integer(expA);
            powB := to_integer(expB);
            powR := powA - powB + 127;   --add exponent value subtract bias
               
            sumA := 0.0;
            sumB := 0.0;  --initialize sums
            k := 1; --initialize increment
            for i in 25 downto 3 loop
                if mantA(i) = '1' then
                    sumA := sumA + 2.0**(-k); --does decimal part of number
                end if;
                if mantB(i) = '1' then
                    sumB := sumB + 2.0**(-k); --does decimal part of number
                end if;
                k := k + 1;
            end loop; 
            sumA := sumA + 1.0;
            sumB := sumB + 1.0; --add first part of significand.
            sumR := sumA / sumB;     
            wholeNum := floor(sumR);    --returns the whole number part of result
            wholeInt := integer(wholeNum); --makes whole num integer to convert back to binary
            wBin := to_unsigned(wholeInt , 2);  --possible values of 0 or 1 with division
            sumR := sumR - wholeNum;        --leaves decimal part
            for i in 25 downto 0 loop
                sumR := sumR * 2.0;  
                if sumR > 1.0 then
                    dBin(i) := '1';         --converting decimal part into binary
                    sumR := sumR - 1.0;
                else
                    dBin(i) := '0';
                end if;
            end loop;
                    
            sigBin(27 downto 26) := wBin;   --putting together binary values
            sigBin(25 downto 0) := dBin;  --leave room for GRS 
            
            GRS := sigBin(2 downto 0);   --round check
            case GRS is
                when "000" =>
                    sigBin := sigBin;
               when "100" =>
                    if sigBin(3) = '1' then
                    sigBin := sigBin + "00000000000000000000000001000";
                    else 
                    sigBin := sigBin;
                    end if;
                when "101" =>
                    sigBin := sigBin + "00000000000000000000000001000";
                when "110" =>
                    sigBin := sigBin + "00000000000000000000000001000";
               when "111" => 
                    sigBin := sigBin + "00000000000000000000000001000";
                when others =>
                    sigBin := sigBin;
            end case;
        c := 0; --initialize counter
        while sigBin(26) /= '1' loop
            sigBin := shift_left(sigBin, 1);    --normalize
            c := c + 1;                                         
        end loop;
        
        powR := powR - c;    --change exponent from normalization                
        expR := to_unsigned(powR, 8); --back to binary
        mantR := sigBin(26 downto 0);
end if;

resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        

if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "00000000000000000000000") then
    zfv := '1';     --zero check
end if;
    
    when "01001" => --*FLOOR*
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        mantA(26) := '1';
        mantA(2 downto 0) := "000";
    
    if (expA = "00000000") and (mantA = "100000000000000000000000000") then
        signR := '0';                   -- floor zero is zero
        expR := "00000000";
        mantR := "000000000000000000000000000";           
    elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
        signR := signA;
        expR := expA;           --floor inf is inf
        mantR := mantA;
    elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
        efv := '1';
        signR := signA;     --NaN
        expR := expA;
        mantR := mantA;            
    
    else
        shiftA := to_integer(expA) - 127; --subtract bias
        for i in (25 - shiftA) downto 0 loop
            mantA(i) := '0';
        end loop;
        
        signR := signA;
        expR := expA;
        mantR := mantA;
end if;

resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        
        
if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "00000000000000000000000") then
    zfv := '1';     --zero check
end if;   

    when "01010" => --*CEIL*
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        mantA(26) := '1';
        mantA(2 downto 0) := "000";
        
        if (expA = "00000000") and (mantA = "100000000000000000000000000") then
            signR := '0';                   -- ceil zero is zero
            expR := "00000000";
            mantR := "000000000000000000000000000";           
        elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
            signR := signA;
            expR := expA;           --ceil inf is inf
            mantR := mantA;
        elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
            efv := '1';
            signR := signA;     --NaN
            expR := expA;
            mantR := mantA;            
        
        else
            shiftA := to_integer(expA) - 127; --subtract bias  
            for i in (25 - shiftA) downto 0 loop
                mantA(i) := '0';                --get rid of decimal place
            end loop;
            for i in 26 downto 0 loop
                if i = (26 - shiftA) then
                    mantB(i) := '1'; --add 1 to first spot not in decimal
                else
                    mantB(i) := '0';
                end if;
            end loop;
            mantR := mantA + mantB;
            signR := signA;
            expR := expA;
    end if;
    
    resultV(31) := signR;
    resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
    resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        
            
    if(signR = '1') then
        nfv := '1';  --negative check
    end if;
    if(expR = "11111111") then
        vfv := '1';  --overflow check
    end if;
    if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
        vfv := '1';
    end if;
    if (expR = "00000000") and (mantR(25 downto 3) = "000000000000000000000000000") then
        zfv := '1';     --zero check
    end if;     
    
    when "01011" => --*ROUND*
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        mantA(26) := '1';
        mantA(2 downto 0) := "000";    
        if (expA = "00000000") and (mantA = "100000000000000000000000000") then
            signR := '0';                   -- round zero is zero
            expR := "00000000";
            mantR := "000000000000000000000000000";           
        elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
            signR := signA;
            expR := expA;           --round inf is inf
            mantR := mantA;
        elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
            efv := '1';
            signR := signA;     --NaN
            expR := expA;
            mantR := mantA;            
                
        else
        shiftA := to_integer(expA) - 127;
        if mantA(25 - shiftA) = '1' then --if first point of decimal is 1 its greater than .5 (round up)
            for i in 26 downto 0 loop
                if i = (26 - shiftA) then
                    mantB(i) := '1';
                else                    --load b with 1 in place of first bit
                    mantB(i) := '0';
                end if;
            end loop;
        else 
            mantB := "000000000000000000000000000";
        end if;
        for i in (25 - shiftA) downto 0 loop
            mantA(i) := '0';        --discard bits
        end loop;
        signR := signA;
        expR := expA;
        mantR := mantA + mantB;
end if;
             
resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        
            
if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "000000000000000000000000000") then
    zfv := '1';     --zero check
end if;   
    
    when "01100" => --*ABSVALUE*
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        mantA(26) := '1';
        mantA(2 downto 0) := "000";
        
    if (expA = "00000000") and (mantA = "100000000000000000000000000") then
        signR := '0';                   -- abs zero is zero
        expR := "00000000";
        mantR := "000000000000000000000000000";           
    elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
        signR := '0';
        expR := expA;           --abs inf is inf
        mantR := mantA;
    elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
        efv := '1';
        signR := signA;     --NaN
        expR := expA;
        mantR := mantA;            
            
    else
    signR := '0';
    expR := expA;       -- returns value but always positive
    mantR := mantA;
    end if;
    
resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "000000000000000000000000000") then
    zfv := '1';     --zero check
end if;

    when "01101" => --*MIN* 
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        signB := b(31);             --breaking up fp
        expB := unsigned(b(30 downto 23));
        mantB(25 downto 3) := unsigned(b(22 downto 0));
        mantA(26) := '1';
        mantB(26) := '1';       --significand leads with 1
        mantA(2 downto 0) := "000";
        mantB(2 downto 0) := "000";
    if (a = b) then
        signR := signA;
        expR := expA;
        mantR := mantA;             
    elsif(a = "11111111100000000000000000000000") and (b = "01111111100000000000000000000000") then
        signR := signA;
        expR := expA;           -- -inf < inf
        mantR := mantA;
    elsif(a = "01111111100000000000000000000000") and (b = "11111111100000000000000000000000") then
        signR := signB;
        expR := expB;           -- -inf < inf
        mantR := mantB;
    elsif(signA = '1') and (b(30 downto 0) = "0000000000000000000000000000000") then
        signR := signA;
        expR := expA; --if b zero a is negative a is min
        mantR := mantA;
    elsif(signB = '1') and (a(30 downto 0) = "0000000000000000000000000000000") then
        signR := signB;
        expR := expB;   --if a is zero b is negative b is min
        mantR := mantB;
    elsif(signA = '0') and (b(30 downto 0) = "0000000000000000000000000000000") then
        signR := signB;
        expR := expB; --if b zero a is positive b is min
        mantR := mantB;
    elsif(signB = '0') and (a(30 downto 0) = "0000000000000000000000000000000") then
        signR := signA;
        expR := expA;   --if a is zero b is positive a is min
        mantR := mantA;
    elsif(signA /= signB) then
        if(signA = '1') then
        signR := signA;
        expR := expA;      -- if signs are opposite the negative  one is min
        mantR := mantA;
        elsif(signB = '1') then
        signR := signB;
        expR := expB;      -- if signs are opposite the negative  one is min
        mantR := mantB;
        end if;
    elsif(expA = "11111111") and (mantA /= "100000000000000000000000000") then
        efv := '1';
        signR := signA;     --NaN
        expR := expA;
        mantR := mantA;    
    elsif(expB = "11111111") and (mantB /= "100000000000000000000000000") then
        efv := '1';
        signR := signA;     --NaN
        expR := expA;
        mantR := mantA;     
                    
    else  
    
    if signA = '1' then --signs equal at this point
        if expA > expB then
            signR := signA;
            expR := expA;   --since sign is negative the greater one is min
            mantR := mantA;
        elsif expB > expA then
            signR := signB;
            expR := expB;
            mantR := mantB;
        elsif expA = expB then 
            if mantA > mantB then
                signR := signA;
                expR := expA;
                mantR := mantA;
            end if;
            if mantB > mantA then
                signR := signB;
                expR := expB;
                mantR := mantB;
            end if;
        end if;
      else 
          if expA > expB then
            signR := signB;
            expR := expB;   --since sign is negative the greater one is min
            mantR := mantB;
          elsif expB > expA then
            signR := signA;
            expR := expA;
            mantR := mantA;
          elsif expA = expB then
            if mantA > mantB then
              signR := signB;
              expR := expB;
              mantR := mantB;
            end if;
            if mantB > mantA then
              signR := signA;
              expR := expA;
              mantR := mantA;
            end if;
          end if;
    end if; 
end if;       
resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        
            
if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "000000000000000000000000000") then
    zfv := '1';     --zero check
end if;
    
    when "01110" => --*MAX
    signA := a(31);
    expA := unsigned(a(30 downto 23));
    mantA(25 downto 3) := unsigned(a(22 downto 0));
    signB := b(31);             --breaking up fp
    expB := unsigned(b(30 downto 23));
    mantB(25 downto 3) := unsigned(b(22 downto 0));
    mantA(26) := '1';
    mantB(26) := '1';       --significand leads with 1
    mantA(2 downto 0) := "000";
    mantB(2 downto 0) := "000";
    if (a = b) then
        signR := signA;
        expR := expA;
        mantR := mantA;             
    elsif(a = "11111111100000000000000000000000") and (b = "01111111100000000000000000000000") then
        signR := signB;
        expR := expB;           -- -inf < inf
        mantR := mantB;
    elsif(a = "01111111100000000000000000000000") and (b = "11111111100000000000000000000000") then
        signR := signA;
        expR := expA;           -- -inf < inf
        mantR := mantA;
    elsif(signA = '1') and (b(30 downto 0) = "0000000000000000000000000000000") then
        signR := signB;
        expR := expB; --if b zero a is negative a is min
        mantR := mantB;
    elsif(signB = '1') and (a(30 downto 0) = "0000000000000000000000000000000") then
        signR := signA;
        expR := expA;   --if a is zero b is negative b is min
        mantR := mantA;
    elsif(signA = '0') and (b(30 downto 0) = "0000000000000000000000000000000") then
        signR := signA;
        expR := expA; --if b zero a is positive b is min
        mantR := mantA;
    elsif(signB = '0') and (a(30 downto 0) = "0000000000000000000000000000000") then
        signR := signB;
        expR := expB;   --if a is zero b is positive a is min
        mantR := mantB;
    elsif(signA /= signB) then
        if(signA = '1') then
            signR := signB;
            expR := expB;      -- if signs are opposite the negative  one is min
            mantR := mantB;
        elsif(signB = '1') then
            signR := signA;
            expR := expA;      -- if signs are opposite the negative  one is min
            mantR := mantA;
        end if;
    elsif(expA = "11111111") and (mantA /= "100000000000000000000000000") then
        efv := '1';
        signR := signA;     --NaN
        expR := expA;
        mantR := mantA;    
    elsif(expB = "11111111") and (mantB /= "100000000000000000000000000") then
        efv := '1';
        signR := signA;     --NaN
        expR := expA;
        mantR := mantA;     
                        
    else  
        
        if signA = '1' then --signs equal at this point
            if expA > expB then
                signR := signB;
                expR := expB;   --since sign is negative the greater one is min
                mantR := mantB;
            elsif expB > expA then
                signR := signA;
                expR := expA;
                mantR := mantA;
            elsif expA = expB then 
                if mantA > mantB then
                    signR := signB;
                    expR := expB;
                    mantR := mantB;
                end if;
                if mantB > mantA then
                    signR := signA;
                    expR := expA;
                    mantR := mantA;
                end if;
            end if;
          else 
              if expA > expB then
                signR := signA;
                expR := expA;   --since sign is negative the greater one is min
                mantR := mantA;
              elsif expB > expA then
                signR := signB;
                expR := expB;
                mantR := mantB;
              elsif expA = expB then
                if mantA > mantB then
                  signR := signA;
                  expR := expA;
                  mantR := mantA;
                end if;
                if mantB > mantA then
                  signR := signB;
                  expR := expB;
                  mantR := mantB;
                end if;
              end if;
        end if; 
    end if;       
    resultV(31) := signR;
    resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
    resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        
                
    if(signR = '1') then
        nfv := '1';  --negative check
    end if;
    if(expR = "11111111") then
        vfv := '1';  --overflow check
    end if;
    if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
        vfv := '1';
    end if;
    if (expR = "00000000") and (mantR(25 downto 3) = "000000000000000000000000000") then
        zfv := '1';     --zero check
    end if;
    
    when "01111" => --*POW*(doesnt work)
        signA := a(31);
        expA := unsigned(a(30 downto 23));
        mantA(25 downto 3) := unsigned(a(22 downto 0));
        mantA(26) := '1';  --significand leads with 1
        mantA(2 downto 0) := "000"; --grs bits
        intV := unsigned(b(18 downto 0));
    if (expA = "00000000") and (mantA = "100000000000000000000000000") then
        signR := '0';                   -- 0^x = 0
        expR := "00000000";
        mantR := "000000000000000000000000000";           
    elsif intV = "0000000000000000000" then
        signR := '0';                   -- x^0 = 1
        expR := "01111111";
        mantR := "000000000000000000000000000";
    elsif (expA = "11111111") and (mantA = "100000000000000000000000000") then
        if intV(0) = '1' then
            signR := signA;     --odd exponent
        end if;
        if intV(0) = '0' then
            signR := '0';   --even exponent alwyas positive
        end if;
        expR := expA;           
        mantR := mantA;
    elsif (expA = "11111111") and (mantA /= "100000000000000000000000000") then
        efv := '1';
        signR := signA;     --NaN
        expR := expA;
        mantR := mantA;
    else
        if intV(0) = '1' then --odd
            signR := signA;
        else            --if even always positive
            signR := '0';
        end if;        
    
        powR := to_integer(intV); --get int value
        powA := to_integer(expA) - 127; --get exponent value
        sumA := 0.0;
        k := 0;
        for i in 25 downto 3 loop
            if mantA(i) = '1' then
                sumA := sumA + 2.0**(-k); --get mantisa value
            else
                sumA := sumA;
            end if;
        k := k + 1;
    end loop;   
    sumA := sumA + 1.0;
    sumA := sumA * (2.0**powA);  --get full fP value
    sumR := sumA**powR;         --get answer
    wholeNum := floor(sumR);    --whole part of answer
    wholeInt := integer(wholeNum);
    fpW := to_unsigned(wholeInt,32);    
    sumR := sumR - wholeNum;  --get decimal part
    for i in 31 downto 0 loop 
        sumR := sumR * 2.0;
        if sumR > 1.0 then 
            fpD(i) := '1';
            sumR := sumR - 1.0; --convert to binary
        else 
            fpD(i) := '0';
        end if;
    end loop;
    fpR(63 downto 32) := fpW;
    fpR(31 downto 0) := fpD;
    k := 0;
    powR := 0;
    c := 63;
    normalizer: for i in 63 downto 0 loop
        if fpR(i) = '1' then
            k := c;     -- find first bit that equals a 1
            exit normalizer;
        end if;
        c := c - 1;
    end loop;
    if k = 32 then 
        mantR(25 downto 3) := fpR(31 downto 9);      --first one already in bit we want
        expR := "01111111"; --exponenet of 0 + 127
    elsif k = 0 then
        expR := "00000000";     --just incase
        mantR := "000000000000000000000000000";
    elsif k > 32 then
        powR := k - 32;
        fpR := shift_right(fpR , powR);    --want to shift our first one right
        mantR(25 downto 3) := fpR(31 downto 9);
        expR := to_unsigned(powR, 8) + "01111111"; --add bias of 127
    else 
        powR := 32 - k;
        fpR := shift_left(fpR, powR);     --want to shift our first one left
        mantR(25 downto 3) := fpR(31 downto 9); 
        expR := "01111111" - to_unsigned(powR, 8); --bias minus shift amount
    end if;
end if;


resultV(31) := signR;
resultV(30 downto 23) := STD_LOGIC_VECTOR(expR);                --putting back in 32 bit format
resultV(22 downto 0) := STD_LOGIC_VECTOR(mantR(25 downto 3));        
             
if(signR = '1') then
    nfv := '1';  --negative check
end if;
if(expR = "11111111") then
    vfv := '1';  --overflow check
end if;
if(expR = "00000000") and (mantR(25 downto 3) /= "000000000000000000000000000") then
    vfv := '1';
end if;
if (expR = "00000000") and (mantR(25 downto 3) = "000000000000000000000000000") then
    zfv := '1';     --zero check
end if;    
    
    when "10000" =>     --*EXP*
        --e is stored in MATH_E
    when "10001" =>     --*SQRT*
        --function SQRT included in library
    when "10010" =>     --*branch uncond.*
        if a > "00000000000000000000001111111111" then  -- this means that this is greater than the amount of addresses in mem
            efv := '1';
        else
            resultV := a;
        end if;
    when "10011" =>     --*BZ*
        resultV := a;
    if (a = "00000000000000000000000000000000") or (a = "10000000000000000000000000000000") then
        zfv := '1';
    elsif(a(30 downto 23) = "11111111") AND (a(22 downto 0) /= "00000000000000000000000")   then
        efv := '1';                                             --NaN
    end if;
    
    when "10100" =>     --*BN*
        resultV := a;
    if a(31) = '1' then
        nfv := '1';
    elsif(a(30 downto 23) = "11111111") AND (a(22 downto 0) /= "00000000000000000000000")   then
        efv := '1';                                             --NaN
    end if;

    when others =>
        resultV := a;                   --doesnt matter for no op and halt
end case;
 
result <= resultV;
nf <= nfv;
zf <= zfv;
vf <= vfv;
ef <= efv;
    
end process;
                 
end Behavioral;
