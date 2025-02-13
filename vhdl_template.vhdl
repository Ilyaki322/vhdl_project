library ieee;
use ieee.std_logic_1164.all;

entity template is
    Generic (
        WIDTH : integer := 8
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;
    );
end template;

architecture behavioral of template is
begin

end behavioral;