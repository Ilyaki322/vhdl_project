library ieee;
use ieee.std_logic_1164.all;

entity general_register is
    Generic (
        WIDTH : integer := 8
    );
    Port(
        clk : in std_logic;
        reset : in std_logic;

        d : in std_logic_vector(WIDTH-1 downto 0);
        load_en : in std_logic;

        q : out std_logic_vector(WIDTH-1 downto 0)
    );
end general_register;

architecture behavioral of general_register is
begin
    process(clk, reset)
    begin
        if reset = '0' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            if load_en = '0' then
                q <= d;
            end if;
        end if;
    end process;

end behavioral;