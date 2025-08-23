library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mux_p;

-------------------------------------------------------------------------------
-- File: control_unit_v2.vhdl
-- Description: this component manages the instruction pipeline.
-- contains several shift registers to make sure that each part of the pipeline
-- works and recieves needed data on time.
-- it recieves a 16bit instuction, and 'delays' parts of it to activate it
-- in the correct phase of the pipeline
-- for example, the target of the instuction is only used at the last writeback stage
-- so we shift it for 4 clocks.
-------------------------------------------------------------------------------

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

        input_data : out std_logic_vector(WIDTH-1 downto 0);

        opc : out std_logic_vector(3 downto 0);
        alu_en : out std_logic;

        reg_sel : out natural;
        op1 : out natural;
        op2 : out natural;
        main_data_bus_mux_sel : out natural
    );
end control_unit_v2;

architecture behavioral of control_unit_v2 is

    type natural_shift_array is array (0 to 2) of natural;

    -------------------------------------------------CONSTANTS-----------------------------------------------
    constant DECODER_WIDTH : integer := 4;
    constant REG_DECODER_WIDTH : integer := 4;
    ---------------------------------------------------------------------------------------------------------

    ----------------------------------------------in/out signals---------------------------------------------
    signal op1_sig : natural := 0;
    signal op2_sig : natural := 0;

    signal is_alu_op : std_logic_vector(1 downto 0) := (others => '0');

    signal inst_reg_data_out : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0) := (others => '0');

    signal write_back_decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0) := (others => '0');
    signal exec_decoder_bus : std_logic_vector((2**DECODER_WIDTH)-1 downto 0) := (others => '0');

    signal exec_selector : std_logic_vector(DECODER_WIDTH-1 downto 0) := (others => '0');

    signal load_from : std_logic_vector(7 downto 0) := (others => '0');

    signal target : std_logic_vector(REG_DECODER_WIDTH-1 downto 0) := (others => '0');
    signal store_target : std_logic_vector(3 downto 0) := (others => '0');

    signal data_sel : natural := 0;
    ---------------------------------------------------------------------------------------------------------
    
    ---------------------------------------Shift Registers for delay-----------------------------------------
    signal opc_delay_shift : std_logic_vector(3*4-1 downto 0) := (others => '0');
    signal target_delay_shift : std_logic_vector(4*REG_DECODER_WIDTH-1 downto 0) := (others => '0');
    signal addr_delay_shift : std_logic_vector(4*WIDTH-1 downto 0) := (others => '0');

    signal addr_delay_1 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal addr_delay_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal addr_delay_3 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    signal opc_delay_1 : std_logic_vector(3 downto 0) := (others => '0');
    signal opc_delay_2 : std_logic_vector(3 downto 0) := (others => '0');

    signal data_sel_delay : natural := 0;

    signal target_delay_1 : std_logic_vector(REG_DECODER_WIDTH-1 downto 0) := (others => '0');
    signal target_delay_2 : std_logic_vector(REG_DECODER_WIDTH-1 downto 0) := (others => '0');

    signal data_sel_shift : natural_shift_array := (others => 0);
    signal op1_shift : natural_shift_array := (others => 0);
    signal op2_shift : natural_shift_array := (others => 0);
    ---------------------------------------------------------------------------------------------------------

    ---------------------------------------component declerations--------------------------------------------
    component general_register
    Generic (
        WIDTH : integer := 16
    );
    Port(
        clk : in std_logic;
        reset : in std_logic;

        we_1 : in std_logic;
        we_2 : in std_logic;
        re_1 : in std_logic;
        re_2 : in std_logic;

        data_bus_1 : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_2 : in std_logic_vector(WIDTH-1 downto 0);
        register_data : out std_logic_vector(WIDTH-1 downto 0)
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
    ---------------------------------------------------------------------------------------------------------

begin
    -------------------------------------component instantinations-------------------------------------------
    inst_reg : general_register
    generic map(WIDTH)
    port map(clk, reset, inst_we, '1', inst_re, '1', inst, (others => '0'), inst_reg_data_out);

    inst_decoder : decoder
    generic map(DECODER_WIDTH)
    port map(enable, clk, reset, inst_reg_data_out(WIDTH-1 downto WIDTH-DECODER_WIDTH), decoder_bus);
    ---------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------
    -- fetch stage

    target_delay_1 <= inst_reg_data_out(WIDTH-5 downto WIDTH-REG_DECODER_WIDTH-4);
    addr_delay_1 <= (WIDTH-9 downto 0 => '0') & inst_reg_data_out(7 downto 0);
    opc_delay_1 <= inst_reg_data_out(WIDTH-1 downto WIDTH-DECODER_WIDTH);

    ---------------------------------------------------------------------------------------------------------
    -- decode + memory stages

    op1_sig <= op1_shift(0);
    op2_sig <= op2_shift(0);
    op1 <= op1_shift(1);
    op2 <= op2_shift(1);

    reg1_re <= not (((not decoder_bus(0) and not decoder_bus(1) and not decoder_bus(2) and not decoder_bus(3)) and to_stdlogic(op1_sig = 1 or op2_sig = 1))
     or (to_stdlogic(to_integer(unsigned(store_target)) = 1)));
    reg2_re <= not (((not decoder_bus(0) and not decoder_bus(1) and not decoder_bus(2) and not decoder_bus(3)) and to_stdlogic(op1_sig = 2 or op2_sig = 2))
     or (to_stdlogic(to_integer(unsigned(store_target)) = 2)));
    reg3_re <= not (((not decoder_bus(0) and not decoder_bus(1) and not decoder_bus(2) and not decoder_bus(3)) and to_stdlogic(op1_sig = 3 or op2_sig = 3))
     or (to_stdlogic(to_integer(unsigned(store_target)) = 3)));
    reg4_re <= not (((not decoder_bus(0) and not decoder_bus(1) and not decoder_bus(2) and not decoder_bus(3)) and to_stdlogic(op1_sig = 4 or op2_sig = 4))
     or (to_stdlogic(to_integer(unsigned(store_target)) = 4)));

    exec_selector <= "0001" when (not decoder_bus(0) and not decoder_bus(1) and not decoder_bus(2)) else
                     "0010" when (decoder_bus(1)) else
                     "0000";

    data_sel <= 0 when decoder_bus(1) = '1' else
                1 when decoder_bus(3) = '1' else
                2;
    

    ---------------------------------------------------------------------------------------------------------
    -- execute stage
    -- 0 none, 1 alu, 2 ram, 

    exec_decodes : decoder 
    generic map(DECODER_WIDTH)
    port map(enable, clk, reset, exec_selector , exec_decoder_bus);

    alu_en <= not exec_decoder_bus(1);
    main_mem_re <= not decoder_bus(1);

    addr_delay_2 <= addr_delay_shift(4*WIDTH-1 downto 3*WIDTH);
    addr_delay_3 <= addr_delay_shift(3*WIDTH-1 downto 2*WIDTH);

    input_data <= addr_delay_shift(3*WIDTH-1 downto 2*WIDTH);

    opc <= opc_delay_shift(3*4-1 downto 2*4);

    target_delay_2 <= target_delay_shift(3*REG_DECODER_WIDTH-1 downto 2*REG_DECODER_WIDTH);

    data_sel_delay <= data_sel_shift(1);

    ---------------------------------------------------------------------------------------------------------
    -- writeback stage
    -- 0 none, 1 reg_1, 2 reg_2, 3 reg_3, 4 reg_4, 5 ram

    write_back_decoder : decoder 
    generic map(DECODER_WIDTH)
    port map(enable, clk, reset, target_delay_2 , write_back_decoder_bus);

    reg1_we <= not write_back_decoder_bus(1);
    reg2_we <= not write_back_decoder_bus(2);
    reg3_we <= not write_back_decoder_bus(3);
    reg4_we <= not write_back_decoder_bus(4);

    main_mem_we <= not write_back_decoder_bus(5);
    main_mem_addr <= addr_delay_shift(WIDTH-1 downto 0) when decoder_bus(1) else addr_delay_2;

    main_data_bus_mux_sel <= data_sel_delay;
    reg_sel <= to_integer(unsigned(store_target));
    
    -------------------------------------------------------------------------------------------------------------

    -- this process shifts the shfit registers each clock
    process(clk)
    begin
        if rising_edge(clk) then
            addr_delay_shift(WIDTH-1 downto 0) <= addr_delay_1;
            addr_delay_shift(2*WIDTH-1 downto WIDTH) <= addr_delay_shift(WIDTH-1 downto 0);
            addr_delay_shift(3*WIDTH-1 downto 2*WIDTH) <= addr_delay_shift(2*WIDTH-1 downto WIDTH);
            addr_delay_shift(4*WIDTH-1 downto 3*WIDTH) <= addr_delay_shift(3*WIDTH-1 downto 2*WIDTH);

            opc_delay_shift(1*4-1 downto 0) <= opc_delay_1;
            opc_delay_shift(2*4-1 downto 1*4) <= opc_delay_shift(1*4-1 downto 0);
            opc_delay_shift(3*4-1 downto 2*4) <= opc_delay_shift(2*4-1 downto 1*4);
    
            target_delay_shift(REG_DECODER_WIDTH-1 downto 0) <= target_delay_1;
            target_delay_shift(2*REG_DECODER_WIDTH-1 downto REG_DECODER_WIDTH) <= "0101" when decoder_bus(2) else target_delay_shift(REG_DECODER_WIDTH-1 downto 0);
            target_delay_shift(3*REG_DECODER_WIDTH-1 downto 2*REG_DECODER_WIDTH) <= target_delay_shift(2*REG_DECODER_WIDTH-1 downto REG_DECODER_WIDTH);

            data_sel_shift(0) <= data_sel;
            data_sel_shift(1) <= data_sel_shift(0);

            op1_shift(0) <= to_integer(unsigned(inst_reg_data_out(7 downto 4)));
            op2_shift(0) <= to_integer(unsigned(inst_reg_data_out(3 downto 0)));
            op1_shift(1) <= op1_shift(0);
            op2_shift(1) <= op2_shift(0);
            op1_shift(2) <= op1_shift(1);
            op2_shift(2) <= op2_shift(1);

            is_alu_op(0) <= decoder_bus(4);
            is_alu_op(1) <= is_alu_op(0);

            store_target <= target_delay_shift(REG_DECODER_WIDTH-1 downto 0) when decoder_bus(2) else
                "0000" when write_back_decoder_bus(5); 

        end if;
    end process;
end behavioral;