library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_ALU is
end entity;

architecture testbench of tb_ALU is
    -- Component Declaration
    component ALU
        generic ( WIDTH : integer := 8 );
        port (
            A, B    : in  std_logic_vector(WIDTH-1 downto 0);
            Op      : in  std_logic_vector(3 downto 0);
            Result  : out std_logic_vector((WIDTH*2)-1 downto 0);
            clk, en, reset : in  std_logic;
            ZeroFlag: out std_logic;
            SignFlag: out std_logic
        );
    end component;

    constant Width_tb : integer := 8;
    -- Testbench Signals
    signal clk_tb, en_tb, reset_tb : std_logic := '1';
    signal A_tb, B_tb    : std_logic_vector((Width_tb)-1 downto 0) := (others => '0');
    signal Op_tb      : std_logic_vector(3 downto 0);
    signal Result_tb  : std_logic_vector((Width_tb*2)-1 downto 0) := (others => '0');
    signal ZeroFlag_tb, SignFlag_tb : std_logic := '0';
    
    constant clock_time : time := 20 ns;
    -- File handling signals
    file infile  : text open read_mode is "alu_input.txt";
begin
    -- Instantiate ALU
    uut: ALU
        generic map (Width_tb)
        port map (
            A_tb, B_tb, Op_tb, Result_tb, clk_tb, en_tb, reset_tb,
            ZeroFlag_tb, SignFlag_tb);

    process
    begin
        clk_tb <= '0'; wait for clock_time / 2;
        clk_tb <= '1'; wait for clock_time / 2;
    end process;

    process
        variable inline  : line;
        variable val_A, val_B, val_Op : integer;
        variable temp_Op : std_logic_vector(3 downto 0);
    begin
        reset_tb <= '0'; wait for clock_time;
        reset_tb <= '1';
        en_tb <= '0';
        while not endfile(infile) loop

            readline(infile, inline);
            read(inline, val_A);
            read(inline, val_B);
            read(inline, temp_Op);


            A_tb <= std_logic_vector(to_signed(val_A, Width_tb));
            B_tb <= std_logic_vector(to_signed(val_B, Width_tb));

            Op_tb <= temp_Op;
            
            wait for clock_time;
        end loop;
        wait;
    end process;
end architecture testbench;
