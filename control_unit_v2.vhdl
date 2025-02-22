library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mux_p;

entity control_unit_v2 is
    Generic (
        WIDTH : integer := 16
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

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

        opc : out std_logic_vector(3 downto 0);
        alu_en : out std_logic;

        reg_sel : out natural;
        op1 : out natural;
        op2 : out natural;
        main_data_bus_mux_sel : out natural
    );
end control_unit_v2;

architecture behavioral of control_unit_v2 is

    constant DECODER_WIDTH : integer := 4;
    constant REG_DECODER_WIDTH : integer := 4;

    signal inst_reg_data_out : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0) := (others => '0');

    signal write_back_decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0) := (others => '0');
    signal exec_decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0) := (others => '0');

    signal exec_selector : std_logic_vector(DECODER_WIDTH-1 downto 0) := (others => '0');

    signal target_delay_1 : std_logic_vector(REG_DECODER_WIDTH-1 downto 0) := (others => '0');
    signal target_delay_2 : std_logic_vector(REG_DECODER_WIDTH-1 downto 0) := (others => '0');
    signal target : std_logic_vector(REG_DECODER_WIDTH-1 downto 0) := (others => '0');

    signal addr_delay_1 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal addr_delay_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal addr_delay_3 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    signal opc_delay_1 : std_logic_vector(3 downto 0) := (others => '0');
    signal opc_delay_2 : std_logic_vector(3 downto 0) := (others => '0');
    --signal opc_delay_3 : std_logic_vector(3 downto 0) := (others => '0');

    signal data_sel : natural := 0;
    signal data_sel_delay : natural := 0;

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
        N : integer := 4
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        selector : in natural;
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

    function to_stdlogic(b : boolean) return std_logic is
        begin
            if b then
                return '1';
            else
                return '0';
            end if;
    end function;

begin

    inst_reg : general_register
    generic map(WIDTH)
    port map(clk, reset, inst_we, inst_re, inst, inst_reg_data_out);

    inst_decoder : decoder
    generic map(DECODER_WIDTH)
    port map(enable, clk, reset, inst_reg_data_out(WIDTH-1 downto WIDTH-DECODER_WIDTH), decoder_bus);

    ---------------------------------------------------------------------------------------------------------

    target <= inst_reg_data_out(WIDTH-5 downto WIDTH-REG_DECODER_WIDTH-4);
    addr_delay_1 <= (WIDTH-9 downto 0 => '0') & inst_reg_data_out(7 downto 0);
    opc_delay_1 <= inst_reg_data_out(WIDTH-1 downto WIDTH-DECODER_WIDTH);

    ---------------------------------------------------------------------------------------------------------

    op1 <= to_integer(unsigned(inst_reg_data_out(7 downto 4)));
    op2 <= to_integer(unsigned(inst_reg_data_out(3 downto 0))); 
    
    target_delay_1 <= "0101" when (decoder_bus(2)) else
                      target; -- else prog counter;

    addr_delay_2 <= addr_delay_1;
    opc_delay_2 <= opc_delay_1;

    reg1_re <= not (decoder_bus(4) and to_stdlogic(op1 = 1 or op2 = 1));
    reg2_re <= not (decoder_bus(4) and to_stdlogic(op1 = 2 or op2 = 2));
    reg3_re <= not (decoder_bus(4) and to_stdlogic(op1 = 3 or op2 = 3));
    reg4_re <= not (decoder_bus(4) and to_stdlogic(op1 = 4 or op2 = 4));

    exec_selector <= "0001" when (not decoder_bus(0) or not decoder_bus(1) or not decoder_bus(2)) else
                     "0010" when (decoder_bus(1)) else
                     "0000";

    data_sel <= 0 when decoder_bus(1) = '1' or decoder_bus(2) = '1' else
                1 when decoder_bus(3) = '1' else
                2;
    

    ---------------------------------------------------------------------------------------------------------

    -- 0 none, 1 alu, 2 ram, 
    exec_decodes : decoder 
    generic map(DECODER_WIDTH)
    port map(enable, clk, reset, exec_selector , exec_decoder_bus);

    alu_en <= not exec_decoder_bus(1);
    main_mem_re <= not exec_decoder_bus(2);

    --write_back_selector <= ;

    target_delay_2 <= target_delay_1;
    addr_delay_3 <= addr_delay_2;
    opc <= opc_delay_2;
    data_sel_delay <= data_sel;


    ---------------------------------------------------------------------------------------------------------

    -- 0 none, 1 reg_1, 2 reg_2, 3 reg_3, 4 reg_4, 5 ram, 6 prog counter
    write_back_decoder : decoder 
    generic map(DECODER_WIDTH)
    port map(enable, clk, reset, target_delay_2 , write_back_decoder_bus);

    reg1_we <= not write_back_decoder_bus(1);
    reg2_we <= not write_back_decoder_bus(2);
    reg3_we <= not write_back_decoder_bus(3);
    reg4_we <= not write_back_decoder_bus(4);
    main_mem_we <= not write_back_decoder_bus(5);
    main_mem_addr <= addr_delay_3;
    main_data_bus_mux_sel <= data_sel_delay;
    reg_sel <= to_integer(unsigned(target_delay_2));
    
    -- PROG COUNTER <= write_back_decoder_bus(6);
    -------------------------------------------------------------------------------------------------------------


    process
    begin
        report "target = " & to_string(addr_delay_1);
        report "target1 = " & to_string(addr_delay_2);
        report "target2 = " & to_string(addr_delay_3);
        wait for 10 ns;
    end process;


end behavioral;