library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

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
        data_bus_in : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_out : out std_logic_vector(WIDTH-1 downto 0);

        read_enable_2 : in std_logic;
        write_enable_2 : in std_logic;
        address_2 : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_in_2 : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_out_2 : out std_logic_vector(WIDTH-1 downto 0)
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
            data_bus_out <= (others => '0');
            data_bus_out_2 <= (others => '0');
        end if;

        if rising_edge(clk) then
            if read_enable = '0' then
                data_bus_out <= data(to_integer(unsigned(address)));
            end if;

            if read_enable_2 = '0' then
                data_bus_out_2 <= data(to_integer(unsigned(address_2)));
            end if;

            if write_enable = '0' then
                data(to_integer(unsigned(address))) <= data_bus_in;
            end if;

            if write_enable_2 = '0' then
                data(to_integer(unsigned(address_2))) <= data_bus_in_2;
            end if;
        end if;
    end process;
end behavioral;