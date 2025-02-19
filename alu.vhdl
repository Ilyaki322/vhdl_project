library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (
        WIDTH : integer := 16
    );
    Port(
        enable: in std_logic;
        clk: in std_logic;
        reset: in std_logic;

        arg_a: in std_logic_vector(WIDTH-1 downto 0);
        arg_b: in std_logic_vector(WIDTH-1 downto 0);
        op: in std_logic_vector(3 downto 0);

        result: out std_logic_vector((2*WIDTH)-1 downto 0)
    );
end alu;

architecture behevioural of alu is
    begin
    process (clk) begin
        if reset = '0' then
            result  <= (others => '0');

        elsif rising_edge(clk) and enable = '0' then
            case op is
                when "0100" =>
                result <= std_logic_vector(resize(signed(arg_a), result'length) + 
                                           resize(signed(arg_b), result'length));
                                        report "arg-A: " & to_string(arg_a) & "arg-B: " & to_string(arg_b)
                                        severity warning;

                when "0101" => 
                result <= std_logic_vector(resize(signed(arg_a), result'length) - 
                                           resize(signed(arg_b), result'length));

                when "0110" => 
                result <= std_logic_vector(resize(signed(arg_a) * signed(arg_b), result'length));

                when others =>
                result  <= (others => '0');
            end case;
        end if;
    end process;
end behevioural;