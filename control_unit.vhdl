library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mux_p;

entity control_unit is
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
        main_mem_addr : out std_logic_vector(WIDTH-1 downto 0);

        reg_sel : out natural;

        main_data_bus_mux_sel : out std_logic
    );
end control_unit;

architecture behavioral of control_unit is

    constant DECODER_WIDTH : integer := 4;
    constant REG_DECODER_WIDTH : integer := 4;

    --signal inst_data_bus : std_logic_vector(WIDTH-1 downto 0); -- we dont need the data_bus inside the control_unit
    --signal inst_reg_we, inst_reg_re : std_logic;
    --signal inst_reg_data_in : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal inst_reg_data_out : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    --signal reg_add_test : std_logic_vector(WIDTH-5 downto WIDTH-REG_DECODER_WIDTH-4); -- test

    signal decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0);
    signal reg_address : std_logic_vector((2**REG_DECODER_WIDTH)-1 downto 0);

    component general_register
    Generic (
        WIDTH : integer := 16
    );
    Port(
        clk : in std_logic;
        reset : in std_logic;

        we : in std_logic;
        re : in std_logic;

        data_bus : in std_logic_vector(WIDTH-1 downto 0);
        register_data : out std_logic_vector(WIDTH-1 downto 0)
    );
    end component;

    component ram
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
        data_bus : inout std_logic_vector(WIDTH-1 downto 0)
    );
    end component;

    component mux
    Generic (
        WIDTH : integer := 16;
        N : integer := 4 -- number of input ports
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        selector : in natural range 0 to N - 1;
        inputs : in mux_p.array_t(0 to N - 1)(WIDTH-1 downto 0);

        output : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    component decoder
    Generic (
        WIDTH : integer := 3
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        input : in std_logic_vector(WIDTH-1 downto 0);
        output : out std_logic_vector((2**WIDTH)-1 downto 0)
    );
    end component;

begin

    --inst_reg_we <= inst_we;
    --inst_reg_re <= inst_re;
    --inst_reg_data_in <= inst;

    main_data_bus_mux_sel <= decoder_bus(3);

    --reg_add_test <= inst_reg_data_out(WIDTH-5 downto WIDTH-REG_DECODER_WIDTH-4);
    --reg_sel <= to_integer(unsigned(reg_add_test));
    reg_sel <= to_integer(unsigned(inst_reg_data_out(WIDTH-5 downto WIDTH-REG_DECODER_WIDTH-4)));

    main_mem_addr <= (WIDTH-9 downto 0 => '0') & inst_reg_data_out(7 downto 0); -- make generic?
    main_mem_re <= not (not exec_en and decoder_bus(1));
    main_mem_we <= not (exec_en and decoder_bus(2));

    reg1_we <= not ( exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(1));
    reg1_re <= not ( not exec_en and decoder_bus(2) and reg_address(1));
    reg2_we <= not ( exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(2));
    reg2_re <= not ( not exec_en and decoder_bus(2) and reg_address(2));
    reg3_we <= not ( exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(3));
    reg3_re <= not ( not exec_en and decoder_bus(2) and reg_address(3));
    reg4_we <= not ( exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(4));
    reg4_re <= not ( not exec_en and decoder_bus(2) and reg_address(4));

    inst_reg : general_register
    generic map(WIDTH)
    port map(clk, reset, inst_we, inst_re, inst, inst_reg_data_out);

    inst_decoder : decoder
    generic map(DECODER_WIDTH)
    port map(enable, clk, reset, inst_reg_data_out(WIDTH-1 downto WIDTH-DECODER_WIDTH), decoder_bus);

    reg_decoder : decoder
    generic map(REG_DECODER_WIDTH)
    port map(enable, clk, reset, inst_reg_data_out(WIDTH-5 downto WIDTH-REG_DECODER_WIDTH-4), reg_address);

    --process
    --begin
        --report "en = " & to_string(exec_en);
        --wait for 10 ns;
    --end process;


end behavioral;