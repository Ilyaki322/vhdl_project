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
    signal enable_tb        : std_logic := '1';
    signal load_tb          : std_logic := '0';
    signal external_data_tb : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal external_addr_tb : std_logic_vector(MEM_SIZE-1 downto 0) := (others => '0');
    signal external_load_tb : std_logic := '0';
    signal external_en_tb   : std_logic := '1';

    -- Clock Period
    constant clk_period : time := 10 ns;

    signal reg1_test : std_logic_vector(15 downto 0);
    signal reg2_test : std_logic_vector(15 downto 0);
    signal reg3_test : std_logic_vector(15 downto 0);
    signal reg4_test : std_logic_vector(15 downto 0);
    signal mem_test : std_logic_vector(15 downto 0);

    signal reg1_we : std_logic;
    signal reg2_we : std_logic;
    signal reg3_we : std_logic;
    signal reg4_we : std_logic;

    signal reg1_we2 : std_logic;
    signal reg2_we2 : std_logic;
    signal reg3_we2 : std_logic;
    signal reg4_we2 : std_logic;

    signal mem_we : std_logic;

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
        file command_file : text open read_mode is "machine_code.txt";
        variable line_var : line;
        variable command  : std_logic_vector(WIDTH-1 downto 0);
        variable addr     : integer := 0;

    begin

        -- INITIAL RESET
        reset_tb <= '0'; wait for clk_period;
        reset_tb <= '1'; wait for clk_period;
        wait for 2 ns;
        report "System RESET complete.";

        -- ENTER LOAD MODE
        report "Loading program into RAM...";
        --wait for clk_period/2;
        external_en_tb <= '0';
        external_load_tb <= '0';
        -- READ AND LOAD COMMANDS FROM FILE
        while not endfile(command_file) loop
            readline(command_file, line_var);
            read(line_var, command);
            
            addr := addr + 1;

            external_addr_tb <= std_logic_vector(to_unsigned(addr, external_addr_tb'length));
            external_data_tb <= std_logic_vector(command);
            
            wait for clk_period;
        end loop;

        -- SWITCH TO EXECUTION MODE
        report "Switching to EXECUTION mode...";
        enable_tb <= '0';
        external_en_tb <= '1';
        external_load_tb <= '1';  -- Execution mode
        load_tb <= '1';          -- CPU executes instructions
        wait for clk_period;
        wait;
    end process;

    process
        alias reg1 is << signal .cpuTB.uut.reg1.data : std_logic_vector(15 downto 0)>>;
        alias reg2 is << signal .cpuTB.uut.reg2.data : std_logic_vector(15 downto 0)>>;
        alias reg3 is << signal .cpuTB.uut.reg3.data : std_logic_vector(15 downto 0)>>;
        alias reg4 is << signal .cpuTB.uut.reg4.data : std_logic_vector(15 downto 0)>>;
        alias main_mem is << signal .cpuTB.uut.main_mem.data_bus_in : std_logic_vector(15 downto 0)>>;

        alias reg1we is << signal .cpuTB.uut.reg1.we_1 : std_logic>>;
        alias reg2we is << signal .cpuTB.uut.reg2.we_1 : std_logic>>;
        alias reg3we is << signal .cpuTB.uut.reg3.we_1 : std_logic>>;
        alias reg4we is << signal .cpuTB.uut.reg4.we_1 : std_logic>>;

        alias reg1we2 is << signal .cpuTB.uut.reg1.we_2 : std_logic>>;
        alias reg2we2 is << signal .cpuTB.uut.reg2.we_2 : std_logic>>;
        alias reg3we2 is << signal .cpuTB.uut.reg3.we_2 : std_logic>>;
        alias reg4we2 is << signal .cpuTB.uut.reg4.we_2 : std_logic>>;
        alias main_memwe is << signal .cpuTB.uut.main_mem.write_enable : std_logic>>;

    begin
        reg1_test <= reg1;
        reg1_we <= reg1we;
        reg2_test <= reg2;
        reg2_we <= reg2we;
        reg3_test <= reg3;
        reg3_we <= reg3we;
        reg4_test <= reg4;
        reg4_we <= reg4we;

        reg1_we2 <= reg1we2;
        reg2_we2 <= reg2we2;
        reg3_we2 <= reg3we2;
        reg4_we2 <= reg4we2;
        mem_test <= main_mem;
        mem_we <= main_memwe;

        if reg1_we = '0' or reg1_we2 = '0' then
            report "REG1: " & to_hstring(reg1);
        end if;
        if reg2_we = '0' or reg1_we2 = '0' then
            report "REG2: " & to_hstring(reg2);
        end if;
        if reg3_we = '0' or reg1_we2 = '0' then
            report "REG3: " & to_hstring(reg3);
        end if;
        if reg4_we = '0' or reg1_we2 = '0' then
            report "REG4: " & to_hstring(reg4);
        end if;
        if mem_we /= main_memwe then
            report "MAIN_RAM: " & to_hstring(main_mem);
        end if;
        wait for 10 ns;
    end process;

end loadprog;
