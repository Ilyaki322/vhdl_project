library ieee;
use ieee.std_logic_1164.all;
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

        main_data_bus_mux_sel : out std_logic
    );
end control_unit;

architecture behavioral of control_unit is

    constant DECODER_WIDTH : integer := 2;
    constant REG_DECODER_WIDTH : integer := 4;

    signal inst_data_bus : std_logic_vector(WIDTH-1 downto 0); -- we dont need the data_bus inside the control_unit
    signal inst_reg_we, inst_reg_re : std_logic;
    signal inst_reg_data : std_logic_vector(WIDTH-1 downto 0);

    signal decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0);
    signal reg_address : std_logic_vector((2**REG_DECODER_WIDTH)-1 downto 0);

    --signal reg1_we_sig, reg1_re_sig : std_logic;
    --signal reg2_we_sig, reg2_re_sig : std_logic;
    --signal reg3_we_sig, reg3_re_sig : std_logic;
    --signal reg4_we_sig, reg4_re_sig : std_logic;

    signal ram_address : std_logic_vector(7 downto 0); -- make generic!

    component general_register
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

        selector : in natural range 0 to N - 1;
        inputs : in mux_p.array_t(0 to WIDTH - 1)(N - 1 downto 0);

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

    inst_reg_we <= inst_we;
    inst_reg_re <= inst_re;
    inst_reg_data <= inst;

    main_data_bus_mux_sel <= decoder_bus(3);

    ram_address <= inst_reg_data(7 downto 0); -- make generic?
    main_mem_re <= exec_en and (decoder_bus(1) or decoder_bus(3));
    main_mem_we <= exec_en and decoder_bus(2);

    --reg1_we <= reg1_we_sig;
    --reg1_re <= reg1_re_sig;
    --reg2_we <= reg2_we_sig;
    --reg2_re <= reg2_re_sig;
    --reg3_we <= reg3_we_sig;
    --reg3_re <= reg3_re_sig;
    --reg4_we <= reg4_we_sig;
    --reg4_re <= reg4_re_sig;
    reg1_we <= exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(0);
    reg1_re <= exec_en and decoder_bus(2) and reg_address(0);
    reg2_we <= exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(1);
    reg2_re <= exec_en and decoder_bus(2) and reg_address(1);
    reg3_we <= exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(2);
    reg3_re <= exec_en and decoder_bus(2) and reg_address(2);
    reg4_we <= exec_en and (decoder_bus(1) or decoder_bus(3)) and reg_address(3);
    reg4_re <= exec_en and decoder_bus(2) and reg_address(3);

    inst_reg : general_register
    generic map(WIDTH)
    port map(clk, reset, inst_reg_we, inst_reg_re, inst_reg_data, inst_reg_data);

    inst_decoder : decoder
    generic map(DECODER_WIDTH) -- change this to a const or generic
    port map(enable, clk, reset, inst_reg_data(WIDTH-1 downto WIDTH-DECODER_WIDTH), decoder_bus);

    reg_decoder : decoder
    generic map(REG_DECODER_WIDTH)
    port map(enable, clk, reset, inst_reg_data(WIDTH-5 downto WIDTH-REG_DECODER_WIDTH-4), reg_address);


end behavioral;