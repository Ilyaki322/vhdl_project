library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mux_p;
use work.CPU_Types.all;

entity cpu is
    Generic (
        WIDTH : integer := 16;
        MEM_SIZE : integer := 8
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic
    );
end cpu;

architecture behavioral of cpu is

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    type state is (fetch, decode, execute, memory);
    signal status : state := fetch;
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    type state is (start, init);
    signal status : state := start;
>>>>>>> Stashed changes

    signal data_bus : std_logic_vector(WIDTH-1 downto 0);
    signal main_ram_bus : std_logic_vector(WIDTH-1 downto 0);

    signal reg1_we, reg1_re : std_logic;
    signal reg1_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg2_we, reg2_re : std_logic;
    signal reg2_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg3_we, reg3_re : std_logic;
    signal reg3_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg4_we, reg4_re : std_logic;
    signal reg4_data : std_logic_vector(WIDTH-1 downto 0);

    signal main_memory_re : std_logic := '1';    
    signal main_memory_we : std_logic := '1';
    signal main_memory_address : std_logic_vector(MEM_SIZE-1 downto 0);

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    signal instruction_reg_we, instruction_reg_re : std_logic;
    signal instruction_reg_data : std_logic_vector(WIDTH-1 downto 0);
    signal instruction_bus : std_logic_vector(WIDTH-1 downto 0);
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    signal instruction_bus : std_logic_vector(WIDTH-1 downto 0);--:= (others => '0');
    signal hazard_out_inst : std_logic_vector(WIDTH-1 downto 0);

    --signal progCounter : std_logic_vector(MEM_SIZE-1 downto 0) := (others => '0');
    signal progCounter : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal progCounterBus : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
>>>>>>> Stashed changes

    signal instruction_stack_re : std_logic := '1';    
    --signal instruction_stack_we : std_logic := '1'; ?

    signal cu_inst_reg_re : std_logic := '1';    
    signal cu_inst_reg_we : std_logic := '1';

    signal data_bus_mux_sel : std_logic := '0';
    signal data_bus_mux_sel_nat : natural;

    signal cu_en : std_logic := '1';

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    component control_unit
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    signal loadRun_nat : natural := 0;

    signal resized_instruction_data : std_logic_vector(WIDTH-1 downto 0);

    component control_unit_v2
>>>>>>> Stashed changes
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

    component HazardUnit
        Port (
            clk, reset, enable : in std_logic;
            instr_in      : in  Instruction;
            instr_out   : out std_logic_vector(15 downto 0);
            prog_counter : out std_logic_vector(15 downto 0) := (others => '0')
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
        data_bus : inout std_logic_vector(WIDTH-1 downto 0)
    );
    end component;

    component mux
    Generic (
        WIDTH : integer := 8;
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

    data_bus_mux_sel_nat <= 0 when data_bus_mux_sel = '0' else 1;
    main_mem : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, main_memory_re, main_memory_we, main_memory_address, main_ram_bus);

    inst_reg : general_register -- program counter
    generic map(WIDTH)
    port map(clk, reset, instruction_reg_we, instruction_reg_re, data_bus, instruction_reg_data);

    inst_stack : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, instruction_stack_re, instruction_stack_we, instruction_reg_data, instruction_bus);

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
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    port map(cu_en, clk, reset, exec_en, cu_inst_reg_we, cu_inst_reg_re, instruction_reg_data, 
    reg1_we, reg1_re, reg2_we, reg2_re, reg3_we, reg3_re, reg4_we, reg4_re, main_memory_re, main_memory_we, data_bus_mux_sel);

    data_bus_mux : mux
    generic map(WIDTH, 2)
    port map(enable => enable, clk => clk, selector => data_bus_mux_sel_nat,
         inputs(0) => main_ram_bus, inputs(1) => instruction_reg_data(7 downto 0), output => data_bus);


=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    port map(cu_en, clk, reset, cu_inst_reg_we, cu_inst_reg_re, hazard_out_inst, 
    reg1_we, reg1_re, reg2_we, reg2_re, reg3_we, reg3_re, reg4_we, reg4_re,
     main_memory_re, main_memory_we, main_memory_address, input_data, op, alu_en,
    reg_out_mux_sel, reg_selector_1, reg_selector_2, data_bus_mux_sel_nat);

    hazard_u : HazardUnit
        port map(clk => clk, reset => reset, enable => enable, instr_in.opcode => instruction_bus(15 downto 12),
                                     instr_in.dest => instruction_bus(11 downto 8),
                                     instr_in.src1 => instruction_bus(7 downto 4),
                                     instr_in.src2 => instruction_bus(3 downto 0),instr_out => hazard_out_inst, prog_counter => progCounter);
    
>>>>>>> Stashed changes
    process (clk) begin
        if reset = '0' then
            -- we need this?

        elsif rising_edge(clk) then
            case status is
<<<<<<< Updated upstream
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
                    
                when execute =>
                exec_en <= '0';
                status <= fetch;
                
                when memory =>


=======
                when start =>
                if load = '1' then
                    instruction_stack_re <= '0';
                    cu_en <= '0';
                    status <= init;
                    end if;
                    
                when init =>
                cu_inst_reg_we <= '0';
                cu_inst_reg_re <= '0';
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
                when others =>
                status <= init;
            end case;
        end if;
   end process;
end behavioral;