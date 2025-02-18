library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity decoder is
    Generic (
        WIDTH : integer := 3
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        input : in std_logic_vector(WIDTH-1 downto 0);
        output : out std_logic_vector((2**WIDTH)-1 downto 0)
    );
end decoder;

architecture behavioral of decoder is
begin
    process(clk, reset)
    begin
        if reset = '0' then
            output <= (others => '0');
        end if;
        --if rising_edge(clk) then
            if enable = '0' then
                output <= (others => '0');
                output(to_integer(unsigned(input))) <= '1';
            end if;
        --end if;
    end process;
end behavioral;