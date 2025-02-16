library ieee;
use ieee.std_logic_1164.all;
use work.mux_p;

entity mux2to1 is
    Generic (
        WIDTH : integer := 16
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;

        selector : in natural range 0 to 1;
        input_1, input_2 : in std_logic_vector(WIDTH-1 downto 0);

        output : out std_logic_vector(WIDTH-1 downto 0)
        );
end mux2to1;

architecture behavioral of mux2to1 is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '0' then
                if selector = 0 then
                    output <= input_1;
                else
                    output <= input_2;
                end if;
            end if;
        end if;
    end process;
end behavioral;