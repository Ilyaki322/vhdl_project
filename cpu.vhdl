library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.mux_p;

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
        --external_addr  : in std_logic_vector(MEM_SIZE-1 downto 0);
        external_load : in std_logic  -- '0' = load, '1' = run
    );
end cpu;

architecture behavioral of cpu is

    type state is (start, init, fetch, decode, execute, memory);
    signal status : state := start;

    signal data_bus : std_logic_vector(WIDTH-1 downto 0);
    signal main_ram_bus : std_logic_vector(WIDTH-1 downto 0);

    signal reg1_we : std_logic := '1';
    signal reg1_re : std_logic := '1';
    signal reg1_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg2_we : std_logic := '1';
    signal reg2_re : std_logic := '1';
    signal reg2_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg3_we : std_logic := '1';
    signal reg3_re : std_logic := '1';
    signal reg3_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg4_we : std_logic := '1';
    signal reg4_re : std_logic := '1';
    signal reg4_data : std_logic_vector(WIDTH-1 downto 0);

    signal main_memory_re : std_logic := '1';    
    signal main_memory_we : std_logic := '1';
    --signal main_memory_address : std_logic_vector(MEM_SIZE-1 downto 0);
    signal main_memory_address : std_logic_vector(WIDTH-1 downto 0);

    signal instruction_reg_we, instruction_reg_re : std_logic;
    signal instruction_reg_data : std_logic_vector(WIDTH-1 downto 0);
    signal instruction_bus : std_logic_vector(WIDTH-1 downto 0);

    --signal progCounter : std_logic_vector(MEM_SIZE-1 downto 0) := (others => '0');
    signal progCounter : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal progCounterBus : std_logic_vector(WIDTH-1 downto 0);

    signal instruction_stack_re : std_logic := '1';    
    signal instruction_stack_we : std_logic := '1';

    signal exec_en : std_logic := '1';
    signal cu_inst_reg_re : std_logic := '1';    
    signal cu_inst_reg_we : std_logic := '1';

    signal dataMux_en : std_logic;
    signal data_bus_mux_sel : std_logic := '0';
    signal data_bus_mux_sel_nat : natural;

    signal cu_en : std_logic := '1';

    signal loadRun_selector : std_logic := '0';
    signal loadRun_nat : natural;

    signal resized_instruction_data : std_logic_vector(WIDTH-1 downto 0);

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

    component general_register
    Generic (
        WIDTH : integer := 8
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
        data_bus : out std_logic_vector(WIDTH-1 downto 0);
        data_busIn : in std_logic_vector(WIDTH-1 downto 0)
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
    --external_data  : in std_logic_vector(WIDTH-1 downto 0);
       -- external_addr  : in std_logic_vector(MEM_SIZE-1 downto 0);
       -- external_load : in std_logic;  -- '0' = load, '1' = run

    dataMux_en <= not exec_en;
    loadRun_nat <= 0 when loadRun_selector = '0' else 1;
    instruction_addr_mux : mux
    generic map(WIDTH, 2)
    port map(enable => enable, clk => clk, selector => loadRun_nat,
         inputs(0) => external_addr, inputs(1) => progCounter, output => progCounterBus);

    data_bus_mux_sel_nat <= 0 when data_bus_mux_sel = '0' else 1;
    main_mem : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, main_memory_re, main_memory_we, main_memory_address, main_ram_bus, data_bus);

    
    --prog_counter : general_register -- program counter
    --generic map(WIDTH)
    --port map(clk, reset, instruction_reg_we, instruction_reg_re, external_addr, instruction_reg_data);
    

    inst_stack : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, instruction_stack_re, external_en, progCounterBus, instruction_bus, external_data);

    reg1 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg1_we, reg1_re, data_bus, reg1_data);

    reg2 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg2_we, reg2_re, data_bus, reg2_data);

    reg3 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg3_we, reg3_re, data_bus, reg3_data);

    reg4 : general_register
    generic map(WIDTH)
    port map(clk, reset, reg4_we, reg4_re, data_bus, reg4_data);

    cu : control_unit
    generic map(WIDTH)
    port map(cu_en, clk, reset, exec_en, cu_inst_reg_we, cu_inst_reg_re, instruction_reg_data, 
    reg1_we, reg1_re, reg2_we, reg2_re, reg3_we, reg3_re, reg4_we, reg4_re, main_memory_re, main_memory_we, data_bus_mux_sel);

    resized_instruction_data <= std_logic_vector(resize(unsigned(instruction_reg_data(7 downto 0)), WIDTH));

    
    data_bus_mux : mux
    generic map(WIDTH, 2)
    port map(enable => dataMux_en, clk => clk, selector => data_bus_mux_sel_nat,
        inputs(0) => main_ram_bus, inputs(1) => resized_instruction_data, output => data_bus);

    process (clk) begin
        if reset = '0' then
            -- we need this?

        elsif rising_edge(clk) then
            case status is
                when start =>
                    if load = '0' then
                        status <= init;
                    else
                        status <= fetch;
                    end if;
                when init =>
                    if load = '1' then
                        status <= fetch;
                    end if;

                when fetch =>
                exec_en <= '1';
                cu_en <= '1';
                instruction_stack_re <= '0';
                cu_inst_reg_we <= '0';
                status <= decode;

                when decode =>
                instruction_stack_re <= '1';
                cu_inst_reg_we <= '1';
                cu_inst_reg_re <= '0';
                cu_en <= '0';
                status <= execute;
                progCounter <= progCounter+ 1;

                when execute =>
                exec_en <= '0';
                status <= fetch;
                
                when memory =>


                when others =>
                -- reset
                status <= fetch;
            end case;
        end if;
   end process;
end behavioral;