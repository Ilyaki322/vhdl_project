library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU_tb is
end ALU_tb;

architecture test of ALU_tb is

    constant WIDTH : integer := 4;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal enable : std_logic := '1';

    signal a_vec : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal b_vec : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal op : std_logic_vector(3 downto 0) := (others => '0');

    signal res : std_logic_vector(2 * (WIDTH-1) downto 0);

    component alu
    generic (
        WIDTH : integer := 16
    );
    Port(
        enable: in std_logic;
        clk: in std_logic;
        reset: in std_logic;

        arg_a: in std_logic_vector(WIDTH-1 downto 0);
        arg_b: in std_logic_vector(WIDTH-1 downto 0);
        op: in std_logic_vector(3 downto 0);

        result: out std_logic_vector(2 * (WIDTH-1) downto 0)
    );
   end component;

   procedure test(signal a, b : out std_logic_vector(WIDTH-1 downto 0);
                  signal op : out std_logic_vector(3 downto 0);
                  constant sig_a : in integer;
                  constant sig_b : in integer;
                  constant sig_op: in std_logic_vector(3 downto 0);
                  signal clk : out std_logic) is
    begin
        clk <= '1';

        wait for 20 ns;
        b <= std_logic_vector(to_signed(sig_b, WIDTH));
        a <= std_logic_vector(to_signed(sig_a, WIDTH));
        op <= sig_op;

        wait for 30 ns;
        clk <= '0';
        wait for 50 ns;

        
    end procedure;

begin

    p_test: process
    begin
        test(a_vec, b_vec, op, 0, 0, "0000", clk);
        test(a_vec, b_vec, op, 7, 7, "0100", clk);
        test(a_vec, b_vec, op, -5, 2, "0101", clk);
        test(a_vec, b_vec, op, 5, 3, "0110", clk);
    end process;

    uut : ALU
    generic map (
        WIDTH
    )
    port map(
        enable, clk, reset, a_vec, b_vec, op, res
    );

    reset <= '0', '1' after 100 ns;
    enable <= '1', '0' after 100 ns;

end test;