library ieee;
use ieee.std_logic_1164.all;

package mux_p is
    type array_t is array (natural range <>) of std_logic_vector;
end package;

package body mux_p is
end package body;

library ieee;
use ieee.std_logic_1164.all;
use work.mux_p;

entity mux is
    Generic (
        WIDTH : integer := 16;
        N : integer := 4 -- number of input ports
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        selector : in natural range 0 to N - 1;
        inputs : in mux_p.array_t(0 to N - 1)(WIDTH-1 downto 0);

        output : out std_logic_vector(WIDTH-1 downto 0)
        );
end mux;

architecture behavioral of mux is
begin
    process(selector, reset, clk)--process(clk, reset)
    begin
        if reset = '0' then
            output <= (others => '0');
        end if;
        --if rising_edge(clk) then
            if enable = '0' then
                output <= inputs(selector);
            end if;
        --end if;
    end process;
end behavioral;