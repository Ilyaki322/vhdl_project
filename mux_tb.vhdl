library ieee;
use ieee.std_logic_1164.all;
use work.mux_p;

entity mux_tb is
end mux_tb;

-- uploaded this tb as an example of how to use generic mux
architecture behevioural of mux_tb is
    signal enable : std_logic := '0';
    signal clk : std_logic := '0';

    signal selector : natural := 0;

    signal i1 : std_logic_vector(3 downto 0) := "0001";
    signal i2 : std_logic_vector(3 downto 0) := "0010";
    signal i3 : std_logic_vector(3 downto 0) := "0011";
    signal i4 : std_logic_vector(3 downto 0) := "0100";

    signal output : std_logic_vector(3 downto 0) := "0000";

    component mux
    Generic (
        WIDTH : integer := 8;
        N : integer := 4 -- number of input ports
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;

        selector : in natural range 0 to N - 1;
        inputs : in mux_p.array_t(0 to WIDTH - 1)(N - 1 downto 0);

        output : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

begin
    clk_process : process
    begin
        clk <= '0'; wait for 50 ns;
        clk <= '1'; wait for 50 ns;
    end process;

    UUT : mux
        generic map(4, 4)
        port map(enable => enable, clk => clk, selector => selector,
         inputs(0) => i1, inputs(1) => i2, inputs(2) => i3, inputs(3) => i4, output => output);

    selector <= 0, 1 after 110 ns, 2 after 210 ns, 3 after 310 ns; --, 5 after 410 ns; -- this crashes (5 is out of range).


end behevioural;