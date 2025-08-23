library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

entity general_register is
    Generic (
        WIDTH : integer := 16
    );
    Port(
        clk : in std_logic;
        reset : in std_logic;

        we_1 : in std_logic;
        we_2 : in std_logic;
        re_1 : in std_logic;
        re_2 : in std_logic;

        data_bus_1 : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_2 : in std_logic_vector(WIDTH-1 downto 0);
        register_data : out std_logic_vector(WIDTH-1 downto 0)
    );
end general_register;

architecture behavioral of general_register is

    signal data : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin
    process(clk, reset) begin
        if reset = '0' then
            register_data <= (others => '0');
        end if;

        if rising_edge(clk) then
            if re_1 = '0' or re_2 = '0' then
                register_data <= data;
            end if;
            if we_1 = '0' and we_2 = '0' then
                data <= data_bus_2;

            elsif we_1 = '0' and we_2 = '1' then
                data <= data_bus_1;

            elsif we_1 = '1' and we_2 = '0' then
                data <= data_bus_2;
            end if;
        end if;
    end process;
end behavioral;