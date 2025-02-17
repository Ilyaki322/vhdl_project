library ieee;
use ieee.std_logic_1164.all;
use work.mux_p;

entity cu_tb is
end cu_tb;

architecture behevioural of cu_tb is
    constant WIDTH : integer := 16;

    signal enable : std_logic := '0';
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';

    signal exec_en : std_logic;
    signal inst_we : std_logic;
    signal inst_re : std_logic;
    signal inst : std_logic_vector(WIDTH-1 downto 0);

    signal reg1_we : std_logic;    
    signal reg1_re : std_logic;
    signal reg2_we : std_logic;    
    signal reg2_re : std_logic;
    signal reg3_we : std_logic;    
    signal reg3_re : std_logic;
    signal reg4_we : std_logic;    
    signal reg4_re : std_logic;

    signal main_mem_re : std_logic;
    signal main_mem_we : std_logic;  
    
    signal main_data_bus_mux_sel : std_logic;

    component control_unit
    Generic (
        WIDTH : integer := 16
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        exec_en : in std_logic;
        inst_we : in std_logic; 
        inst_re : in std_logic;
        inst : in std_logic_vector(WIDTH-1 downto 0);

        reg1_we, reg1_re : out std_logic;
        reg2_we, reg2_re : out std_logic;
        reg3_we, reg3_re : out std_logic;
        reg4_we, reg4_re : out std_logic;
        
        main_mem_re : out std_logic;
        main_mem_we : out std_logic;

        main_data_bus_mux_sel : out std_logic
    );
    end component;

begin
    clk_process : process
    begin
        clk <= '0'; wait for 50 ns;
        clk <= '1'; wait for 50 ns;
    end process;

    UUT : control_unit
        generic map(WIDTH)
        port map(enable, clk, reset, exec_en, inst_we, inst_re, inst,
         reg1_we, reg1_re, reg2_we, reg2_re, reg3_we, reg3_re, reg4_we, reg4_re,
         main_mem_re, main_mem_we, main_data_bus_mux_sel);

    reset <= '0', '1' after 20 ns;

end behevioural;