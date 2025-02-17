library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity cpuTB is
end cpuTB;

architecture loadprog of cpuTB is

    component cpu
    Generic (
        WIDTH : integer := 16;
        MEM_SIZE : integer := 16
    );
    Port(
        enable, load : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        external_en : in std_logic;
        external_data  : in std_logic_vector(WIDTH-1 downto 0);
        external_addr  : in std_logic_vector(WIDTH-1 downto 0);
        --external_addr  : in std_logic_vector(MEM_SIZE-1 downto 0);
        external_load : in std_logic  -- '0' = load, '1' = run
    );
    end component;
    constant WIDTH : integer := 16;
    constant MEM_SIZE : integer := 16;
    -- Signals for Simulation
    signal clk_tb           : std_logic := '0';
    signal reset_tb         : std_logic := '0';
    signal enable_tb        : std_logic := '0';
    signal load_tb          : std_logic := '0';
    signal external_data_tb : std_logic_vector(WIDTH-1 downto 0);
    signal external_addr_tb : std_logic_vector(MEM_SIZE-1 downto 0);
    signal external_load_tb : std_logic := '0';
    signal external_en_tb   : std_logic := '1';

    -- Clock Period
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the CPU
    uut: cpu
        generic map(WIDTH,MEM_SIZE)
        port map(
            enable_tb,
            load_tb,
            clk_tb ,
            reset_tb,
            external_en_tb,
            external_data_tb,
            external_addr_tb,
            external_load_tb
        );

    -- Clock Process
    clk_process : process
    begin
        clk_tb <= '0'; wait for clk_period / 2;
        clk_tb <= '1'; wait for clk_period / 2;
    end process;

    -- Test Process
    test_process : process
        file command_file : text open read_mode is "./work/machine_code.txt";
        variable line_var : line;
        variable command  : std_logic_vector(WIDTH-1 downto 0);
        variable addr     : integer := 0;

    begin
    
        -- INITIAL RESET
        reset_tb <= '0'; wait for clk_period;
        reset_tb <= '1'; wait for clk_period;
        report "System RESET complete.";

        enable_tb <= '1';
        wait for clk_period;

        -- ENTER LOAD MODE
        external_load_tb <= '0';
        load_tb <= '0';
        external_en_tb <= '0';
        report "Loading program into RAM...";

        -- READ AND LOAD COMMANDS FROM FILE
        while not endfile(command_file) loop
            readline(command_file, line_var);
            read(line_var, command);
            external_addr_tb <= std_logic_vector(to_unsigned(addr, external_addr_tb'length));
            external_data_tb <= std_logic_vector(command);
            addr := addr + 1;
            wait for clk_period;

            report "Loaded Instruction at Address " & integer'image(addr) & 
                   ": " & to_string(command);
        end loop;

        -- SWITCH TO EXECUTION MODE
        report "Switching to EXECUTION mode...";
        external_en_tb <= '1';
        external_load_tb <= '1';  -- Execution mode
        wait for clk_period;
        load_tb <= '1';          -- CPU executes instructions
        wait;
    end process;

end loadprog;
