library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.mux_p;
use work.CPU_Types.all;
entity cpu is
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
        external_load : in std_logic  -- '0' = load, '1' = run
    );
end cpu;

architecture behavioral of cpu is

    type state is (start, init);
    signal status : state := start;

    ----- ALU_1 SIGNALS -----
    signal alu_out : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal op : std_logic_vector(3 downto 0);
    signal alu_en : std_logic := '1';
    signal zero_flag : std_logic := '0';
    signal sign_flag : std_logic := '0';
    -----------------------

    ----- ALU_1 SIGNALS -----
    signal alu_out_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal op_2 : std_logic_vector(3 downto 0);
    signal alu_en_2 : std_logic := '1';
    signal zero_flag_2 : std_logic := '0';
    signal sign_flag_2 : std_logic := '0';
    -----------------------

    ----- FIRST ALU REGISTERS-----
    signal reg_bus_1 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal reg_bus_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');  
    signal reg_selector_1 : natural := 0;
    signal reg_selector_2 : natural := 0;
    ------------------------------
    
    ----- SECOND ALU REGISTERS-----
    signal reg_bus_3 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');  
    signal reg_bus_4 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');  
    signal reg_selector_3 : natural := 0;
    signal reg_selector_4 : natural := 0;
    -------------------------------

    -----REGISTER_1-----
    signal reg1_we : std_logic := '1';
    signal reg1_we2 : std_logic := '1';
    signal reg1_re : std_logic := '1';
    signal reg1_re2 : std_logic := '1';
    signal reg1_data : std_logic_vector(WIDTH-1 downto 0);
    --------------------

    -----REGISTER_2-----
    signal reg2_we : std_logic := '1';
    signal reg2_we2 : std_logic := '1';
    signal reg2_re : std_logic := '1';
    signal reg2_re2 : std_logic := '1';
    signal reg2_data : std_logic_vector(WIDTH-1 downto 0);
    --------------------

    -----REGISTER_3-----
    signal reg3_we : std_logic := '1';
    signal reg3_we2 : std_logic := '1';
    signal reg3_re : std_logic := '1';
    signal reg3_re2 : std_logic := '1';
    signal reg3_data : std_logic_vector(WIDTH-1 downto 0);
    --------------------

    -----REGISTER_4-----
    signal reg4_we : std_logic := '1';
    signal reg4_we2 : std_logic := '1';
    signal reg4_re : std_logic := '1';
    signal reg4_re2 : std_logic := '1';
    signal reg4_data : std_logic_vector(WIDTH-1 downto 0);
    --------------------

    -----MAIM_RAM-----
    signal main_memory_re : std_logic := '1';    
    signal main_memory_we : std_logic := '1';
    signal main_memory_address : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal main_ram_bus : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    signal main_memory_re_2 : std_logic := '1';    
    signal main_memory_we_2 : std_logic := '1';
    signal main_memory_address_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal main_ram_bus_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    ------------------

    -----DATA_BUS-----
    signal data_bus : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal data_bus_mux_sel : std_logic := '0';
    signal data_bus_mux_sel_nat : natural := 0;

    signal data_bus_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal data_bus_mux_sel_2 : std_logic := '0';
    signal data_bus_mux_sel_nat_2 : natural := 0;
    ------------------

    -----CU_1-----
    signal cu_inst_reg_re : std_logic := '1';    
    signal cu_inst_reg_we : std_logic := '1';
    signal cu_en : std_logic := '1';
    --------------

    -----CU_2-----
    signal cu2_inst_reg_re : std_logic := '1';    
    signal cu2_inst_reg_we : std_logic := '1';
    signal cu2_en : std_logic := '1';
    --------------

    signal reg_out_bus : std_logic_vector(WIDTH-1 downto 0) := (others => '0'); -- to mem
    signal reg_out_mux_sel : natural := 0;

    signal reg_out_bus_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0'); -- to mem
    signal reg_out_mux_sel_2 : natural := 0;

    signal instruction_bus : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal instruction_stack_re : std_logic := '1';    

    signal progCounter : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal progCounterBus : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    signal loadRun_nat : natural := 0;

    signal input_data : std_logic_vector(WIDTH - 1 downto 0) := (others => '0');
    signal input_data_2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal resized_instruction_data : std_logic_vector(WIDTH-1 downto 0);

    signal hazard_out_inst : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal hazard_out_inst2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    component control_unit_v2
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
    end component;

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

    component ram
    Generic(
        WIDTH : integer := 16;
        SIZE : integer := 8
    );
    Port(
        clk : in std_logic;
        reset : in std_logic;

        read_enable : in std_logic;
        write_enable : in std_logic;
        address : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_in : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_out : out std_logic_vector(WIDTH-1 downto 0);

        read_enable_2 : in std_logic;
        write_enable_2 : in std_logic;
        address_2 : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_in_2 : in std_logic_vector(WIDTH-1 downto 0);
        data_bus_out_2 : out std_logic_vector(WIDTH-1 downto 0)
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

    component alu
    generic ( WIDTH : integer := 8 );
    port (
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;

        arg_a : in  std_logic_vector(WIDTH-1 downto 0);
        arg_b : in  std_logic_vector(WIDTH-1 downto 0);
        op  : in  std_logic_vector(3 downto 0);

        result : out std_logic_vector((WIDTH*2)-1 downto 0);

        zero_flag : out std_logic;
        sign_flag : out std_logic        
    );
    end component;

    component HazardUnit
        Port (
            clk, reset, enable : in std_logic;
            zero_flag, zero_flag2 : in std_logic;
            instr_in      : in  Instruction;
            instr_out   : out std_logic_vector(15 downto 0);
            instr_parallel : out std_logic_vector(15 downto 0);
            prog_counter : out std_logic_vector(15 downto 0) := (others => '0')
        );
        end component;
begin

    alu_1 : alu
    generic map(WIDTH/2)
    port map(enable, clk, reset, reg_bus_1(7 downto 0), reg_bus_2(7 downto 0), op, alu_out, zero_flag, sign_flag);

    alu_2 : alu
    generic map(WIDTH/2)
    port map(enable, clk, reset, reg_bus_3(7 downto 0), reg_bus_4(7 downto 0), op_2, alu_out_2, zero_flag_2, sign_flag_2);

    reg_sel_1 : mux
    generic map(WIDTH, 5)
    port map(reset => reset, enable => enable, clk => clk, selector => reg_selector_1, inputs(0) => (others => '0'),
        inputs(1) => reg1_data, inputs(2) => reg2_data, inputs(3) => reg3_data, inputs(4) => reg4_data, output => reg_bus_1);

    reg_sel_2 : mux
    generic map(WIDTH, 5)
    port map(reset => reset, enable => enable, clk => clk, selector => reg_selector_2, inputs(0) => (others => '0'),
        inputs(1) => reg1_data, inputs(2) => reg2_data, inputs(3) => reg3_data, inputs(4) => reg4_data, output => reg_bus_2);

    reg_sel_3 : mux
    generic map(WIDTH, 5)
    port map(reset => reset, enable => enable, clk => clk, selector => reg_selector_3, inputs(0) => (others => '0'),
        inputs(1) => reg1_data, inputs(2) => reg2_data, inputs(3) => reg3_data, inputs(4) => reg4_data, output => reg_bus_3);
    
    reg_sel_4 : mux
    generic map(WIDTH, 5)
    port map(reset => reset, enable => enable, clk => clk, selector => reg_selector_4, inputs(0) => (others => '0'),
        inputs(1) => reg1_data, inputs(2) => reg2_data, inputs(3) => reg3_data, inputs(4) => reg4_data, output => reg_bus_4);

    data_bus_mux : mux
    generic map(WIDTH, 3)
    port map(reset => reset, enable => enable, clk => clk, selector => data_bus_mux_sel_nat,
        inputs(0) => main_ram_bus, inputs(1) => input_data, inputs(2) => alu_out, output => data_bus);

    data_bus_mux_2 : mux
    generic map(WIDTH, 3)
    port map(reset => reset, enable => enable, clk => clk, selector => data_bus_mux_sel_nat_2,
        inputs(0) => main_ram_bus_2, inputs(1) => input_data_2, inputs(2) => alu_out_2, output => data_bus_2);

    reg_data_mux : mux
    generic map(WIDTH, 5)
    port map(reset => reset, enable => enable, clk => clk, selector => reg_out_mux_sel, inputs(0) => (others => '0'),
        inputs(1) => reg1_data, inputs(2) => reg2_data, inputs(3) => reg3_data, inputs(4) => reg4_data, output => reg_out_bus);

    reg_data_mux_2 : mux
    generic map(WIDTH, 5)
    port map(reset => reset, enable => enable, clk => clk, selector => reg_out_mux_sel_2, inputs(0) => (others => '0'),
        inputs(1) => reg1_data, inputs(2) => reg2_data, inputs(3) => reg3_data, inputs(4) => reg4_data, output => reg_out_bus_2);

    instruction_addr_mux : mux
    generic map(WIDTH, 2)
    port map(reset => reset, enable => external_en and enable, clk => clk, selector => loadRun_nat,
        inputs(0) => external_addr, inputs(1) => progCounter, output => progCounterBus);

    main_mem : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, main_memory_re, main_memory_we, main_memory_address, reg_out_bus, main_ram_bus,
            main_memory_re_2, main_memory_we_2, main_memory_address_2, reg_out_bus_2, main_ram_bus_2);

    inst_stack : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, instruction_stack_re, external_en, progCounterBus, external_data, instruction_bus, 
            '1', '1', (others => '0'), (others => '0'));

    reg1 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg1_we, reg1_we2, reg1_re, reg1_re2, data_bus, data_bus_2, reg1_data);

    reg2 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg2_we, reg2_we2, reg2_re, reg2_re2, data_bus, data_bus_2, reg2_data);

    reg3 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg3_we, reg3_we2, reg3_re, reg3_re2, data_bus, data_bus_2, reg3_data);

    reg4 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg4_we, reg4_we2, reg4_re, reg4_re2, data_bus, data_bus_2, reg4_data);

    cu : control_unit_v2
    generic map(WIDTH)
    port map(cu_en, clk, reset, cu_inst_reg_we, cu_inst_reg_re, hazard_out_inst, 
    reg1_we, reg1_re, reg2_we, reg2_re, reg3_we, reg3_re, reg4_we, reg4_re,
     main_memory_re, main_memory_we, main_memory_address, input_data, op, alu_en,
    reg_out_mux_sel, reg_selector_1, reg_selector_2, data_bus_mux_sel_nat);

    cu_2 : control_unit_v2
    generic map(WIDTH)
    port map(cu2_en, clk, reset, cu2_inst_reg_we, cu2_inst_reg_re, hazard_out_inst2, 
    reg1_we2, reg1_re2, reg2_we2, reg2_re2, reg3_we2, reg3_re2, reg4_we2, reg4_re2,
    main_memory_re_2, main_memory_we_2, main_memory_address_2, input_data_2, op_2, alu_en_2,
    reg_out_mux_sel_2, reg_selector_3, reg_selector_4, data_bus_mux_sel_nat_2);

    hazard_u : HazardUnit
    port map(clk => clk, reset => reset, enable => enable, zero_flag => zero_flag, zero_flag2 => zero_flag_2, instr_in.opcode => instruction_bus(15 downto 12),
                                 instr_in.dest => instruction_bus(11 downto 8),
                                 instr_in.src1 => instruction_bus(7 downto 4),
                                 instr_in.src2 => instruction_bus(3 downto 0),instr_out => hazard_out_inst,instr_parallel => hazard_out_inst2, prog_counter => progCounter);

    loadRun_nat <= 0 when external_load = '0' else 1;
    resized_instruction_data <= std_logic_vector(resize(unsigned(instruction_bus(7 downto 0)), WIDTH));

    
    process (clk) begin
        if reset = '0' then
            -- reset

        elsif rising_edge(clk) then
            case status is
                when start =>
                if load = '1' then
                    instruction_stack_re <= '0';
                    cu_en <= '0';
                    cu2_en <= '0';
                    status <= init;
                end if;
                    
                when init =>
                cu_inst_reg_we <= '0';
                cu2_inst_reg_we <= '0';
                cu_inst_reg_re <= '0';
                cu2_inst_reg_re <= '0';

                when others =>
                -- reset
                status <= start;
            end case;
        end if;
   end process;
end behavioral;