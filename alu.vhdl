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
    begin
        process(clk)
            variable a_s, b_s: signed(WIDTH-1 downto 0);
            variable sum   : signed((WIDTH*2)-1 downto 0);
            constant zero_vec : std_logic_vector(WIDTH-1 downto 0) := (others => '0'); --Zero vector for padding
        begin
            --if rising_edge(clk) then
                if reset = '0' then
                    zero_flag <= '0';
                    sign_flag <= '0';
                    sum := (others => '0');
                elsif enable = '0' then
                    a_s := signed(arg_a);
                    b_s := signed(arg_b);
                    case op is
                        when "0100" => --Add A+B
                        result <= std_logic_vector(resize(signed(arg_a), result'length) + 
                                                   resize(signed(arg_b), result'length));
                                                report "arg-A: " & to_string(arg_a) & "arg-B: " & to_string(arg_b)
                                                severity warning;

                        when "0001" => --Sub A-B
                            sum := resize(a_s, WIDTH*2) - resize(b_s, WIDTH*2);

                        when "0010" => -- Mult A*B
                            sum := resize(a_s * b_s, WIDTH*2);

                        when "0011" =>  -- OR: A or B
                            sum := signed(zero_vec & (arg_a or arg_b));

                        when "0000" =>  -- AND: A and B
                            sum := signed(zero_vec & (arg_a and arg_b));

                        when "0101" =>  -- XOR: A xor B
                            sum := signed(zero_vec & (arg_a xor arg_b));

                        when "0110" =>  -- Shift Left: logical shift left of A by 1 bit
                            sum := signed(zero_vec & std_logic_vector(shift_left(unsigned(arg_a), 1)));

                        when "0111" =>  -- Shift Right: logical shift right of A by 1 bit
                            sum := signed(zero_vec & std_logic_vector(shift_right(unsigned(arg_a), 1)));

                        when "1000" => --Compare (using flags at end)
                            sum := resize(a_s - b_s, WIDTH*2);
                        when others =>
                            sum := (others => '0');
                    end case;
                    -- Update Flags
                if sum = 0 then
                    zero_flag <= '1';
                else
                    zero_flag <= '0';
                end if;
                
                sign_flag <= sum(sum'length-1);
                --result <= std_logic_vector(sum);
                end if;
            --end if;
        end process;
    end architecture ALU_Logic;