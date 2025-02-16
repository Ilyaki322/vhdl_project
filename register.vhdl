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

        we : in std_logic;
        re : in std_logic;

        data_bus : inout std_logic_vector(WIDTH-1 downto 0);
        register_data : out std_logic_vector(WIDTH-1 downto 0)
    );
end general_register;

architecture behavioral of general_register is

    signal data : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin

    register_data <= data;

    process(clk, reset) begin
        if reset = '0' then
            data <= (others => '0');
        end if;

        if rising_edge(clk) then
            if re = '0' then
                data_bus <= data;
                report "REGISTER READ: Data output on bus: " & to_hstring(data)
                        severity note;
            end if;
            if we = '0' then
                data <= data_bus;
                report "REGISTER WRITE: Data written from bus: " & to_hstring(data_bus)
                        severity note;
            end if;
        end if;
    end process;
end behavioral;