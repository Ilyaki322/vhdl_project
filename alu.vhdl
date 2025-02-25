library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    generic ( WIDTH : integer := 8 );
    port (
        A,B : in  std_logic_vector(WIDTH-1 downto 0);
        Op  : in  std_logic_vector(3 downto 0);
        Result : out std_logic_vector((WIDTH*2)-1 downto 0);
        clk, en, reset : in std_logic;
        ZeroFlag : out std_logic;
        SignFlag : out std_logic        
    );
end entity ALU;

architecture ALU_Logic of ALU is
    begin
        process(clk)
            variable a_s, b_s: signed(WIDTH-1 downto 0);
            variable sum   : signed((WIDTH*2)-1 downto 0);
            constant zero_vec : std_logic_vector(WIDTH-1 downto 0) := (others => '0'); --Zero vector for padding
        begin
            if rising_edge(clk) then
                if reset = '0' then
                    ZeroFlag <= '0';
                    SignFlag <= '0';
                    sum := (others => '0');
                elsif en = '0' then
                    a_s := signed(A);
                    b_s := signed(B);
                    case Op is
                        when "0000" => --Add A+B
                            sum := resize(a_s, WIDTH*2) + resize(b_s, WIDTH*2);

                        when "0001" => --Sub A-B
                            sum := resize(a_s, WIDTH*2) - resize(b_s, WIDTH*2);

                        when "0010" => -- Mult A*B
                            sum := resize(a_s * b_s, WIDTH*2);

                        when "0011" =>  -- OR: A or B
                            sum := signed(zero_vec & (A or B));

                        when "0100" =>  -- AND: A and B
                            sum := signed(zero_vec & (A and B));

                        when "0101" =>  -- XOR: A xor B
                            sum := signed(zero_vec & (A xor B));

                        when "0110" =>  -- Shift Left: logical shift left of A by 1 bit
                            sum := signed(zero_vec & std_logic_vector(shift_left(unsigned(A), 1)));

                        when "0111" =>  -- Shift Right: logical shift right of A by 1 bit
                            sum := signed(zero_vec & std_logic_vector(shift_right(unsigned(A), 1)));

                        when "1000" => --Compare (using flags at end)
                            sum := resize(a_s - b_s, WIDTH*2);
                        when others =>
                            sum := (others => '0');
                    end case;
                    -- Update Flags
                if sum = 0 then
                    ZeroFlag <= '1';
                else
                    ZeroFlag <= '0';
                end if;
                
                SignFlag <= sum(sum'length-1);
                Result   <= std_logic_vector(sum);
                end if;
            end if;
        end process;
    end architecture ALU_Logic;