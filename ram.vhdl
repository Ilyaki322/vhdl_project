library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
    Generic (
        WIDTH : integer := 16;
        SIZE : integer := 8
    );
    Port(
        clk : in std_logic;
        reset : in std_logic;

        read_enable : in std_logic;
        write_enable : in std_logic;

        address : in std_logic_vector(WIDTH-1 downto 0);
        data_bus : inout std_logic_vector(WIDTH-1 downto 0)
    );
end ram;

architecture behavioral of ram is

    type ram_t is array(0 to (2**SIZE) - 1) of std_logic_vector(WIDTH-1 downto 0);
    signal data : ram_t := (others => (others => '0'));

begin
    process(clk, reset)
    begin
        if reset = '0' then
            data <= (others => (others => '0'));
        end if;

        if rising_edge(clk) then
            if read_enable = '0' then
                data_bus <= data(to_integer(unsigned(address)));
            end if;
            if write_enable = '0' then
                data(to_integer(unsigned(address))) <= data_bus;
            end if;
        end if;
    end process;
end behavioral;