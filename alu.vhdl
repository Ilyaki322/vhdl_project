library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    generic ( WIDTH : integer := 8 );
    port (
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        arg_a : in  std_logic_vector(WIDTH-1 downto 0);
        arg_b : in  std_logic_vector(WIDTH-1 downto 0);
        op  : in  std_logic_vector(3 downto 0);

        result : out std_logic_vector((WIDTH*2)-1 downto 0);

        zero_flag : out std_logic;
        sign_flag : out std_logic        
    );
end entity ALU;

architecture ALU_Logic of ALU is
    signal zero_delay : std_logic_vector(1 downto 0) := (others => '0');
    begin
        process(clk)
            constant zero_vec : std_logic_vector(WIDTH-1 downto 0) := (others => '0'); --Zero vector for padding
        begin
            --if rising_edge(clk) then
                if reset = '0' then
                    zero_flag <= '0';
                    sign_flag <= '0';
                    result <= (others => '0');
                    zero_delay <= (others => '0');
                elsif enable = '0' then
                    case op is
                        when "0100" => --Add A+B
                        result <= std_logic_vector(resize(signed(arg_a), result'length) + 
                                                   resize(signed(arg_b), result'length));

                        when "0101" => --Sub A-B
                        result <= std_logic_vector(resize(signed(arg_a), result'length) - 
                                                   resize(signed(arg_b), result'length));                             
                        when "0110" => -- Mult A*B
                        result <= std_logic_vector(resize(signed(arg_a) * signed(arg_b), result'length));
                            if unsigned(result) = 0 then
                                zero_flag <= '1';
                            end if; 

                        when "0111" =>  -- OR: A or B
                        result(7 downto 0) <= std_logic_vector(unsigned(arg_a) OR unsigned(arg_b));
                        --report "arg-A: " & to_string(arg_a) & "arg-B: " & to_string(arg_b)
                        --severity warning;

                        when "1000" =>  -- AND: A and B
                        result(7 downto 0) <= std_logic_vector(unsigned(arg_a) AND unsigned(arg_b));
                        --report "arg-A: " & to_string(arg_a) & "arg-B: " & to_string(arg_b)
                        --severity warning;

                        when "1001" =>  -- XOR: A xor B
                        result(7 downto 0) <= std_logic_vector(unsigned(arg_a) XOR unsigned(arg_b));

                        when "1010" =>  -- Shift Left: logical shift left of A by 1 bit
                        result(7 downto 0) <= std_logic_vector(shift_left(unsigned(arg_a), 1));

                        when "1011" =>  -- Shift Right: logical shift right of A by 1 bit
                        result(7 downto 0) <= std_logic_vector(shift_right(unsigned(arg_a), 1));

                        when "1100" => --Compare (using flags at end)
                        result <= std_logic_vector(resize(signed(arg_a), result'length) - 
                                                   resize(signed(arg_b), result'length));

                        when "1101" => -- MOV
                        result(7 downto 0) <= arg_a;

                        when "0000" => result <= std_logic_vector(to_unsigned(1, result'length));
                        when others =>
                        result <= (others => '0');
                    end case;
                    
                    if unsigned(result) = 0 and op /= "0000" and rising_edge(clk) then
                        zero_delay(1) <= '1';
                    else
                        zero_delay(1) <= '0';
                    end if; 

                    if enable = '0' then
                        zero_delay(0) <= zero_delay(1);
                    end if;
                    sign_flag <= result(result'length - 1);
                    zero_flag <= zero_delay(0) or zero_delay(1);
                end if;
            --end if;
        end process;
    end architecture ALU_Logic;