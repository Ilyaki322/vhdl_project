library ieee;
use ieee.std_logic_1164.all;
use work.mux_p;

entity cpu is
    Generic (
        WIDTH : integer := 16;
        MEM_SIZE : integer := 8
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic;
    );
end cpu;

architecture behavioral of cpu is

    type state is (fetch, decode, execute, memory);
    signal status : state := fetch;

    signal data_bus : std_logic_vector(WIDTH-1 downto 0);

    signal reg1_we, reg1_re : std_logic;
    signal reg1_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg2_we, reg2_re : std_logic;
    signal reg2_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg3_we, reg3_re : std_logic;
    signal reg3_data : std_logic_vector(WIDTH-1 downto 0);

    signal reg4_we, reg4_re : std_logic;
    signal reg4_data : std_logic_vector(WIDTH-1 downto 0);

    signal main_memory_re : std_logic;    
    signal main_memory_we : std_logic;
    signal main_memory_address : std_logic_vector(MEM_SIZE-1 downto 0);

    signal instruction_reg_we, instruction_reg_re : std_logic;
    signal instruction_reg_data : std_logic_vector(WIDTH-1 downto 0);
    signal instruction_bus : std_logic_vector(WIDTH-1 downto 0);

    signal instruction_stack_re : std_logic;    
    signal instruction_stack_we : std_logic;

    component control_unit
    Generic (
        WIDTH : integer := 16
    );
    Port(
        enable : in std_logic;
        clk : in std_logic;
        reset : in std_logic
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

    main_mem : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, main_memory_re, main_memory_we, main_memory_address, data_bus);

    inst_reg : general_register
    generic map(WIDTH)
    port map(clk, reset, instruction_reg_we, instruction_reg_re, data_bus, instruction_reg_data);

    --STACK
    inst_stack : ram
    generic map(WIDTH, MEM_SIZE)
    port map(clk, reset, instruction_stack_re, instruction_stack_we, instruction_reg_data, instruction_bus);

    --=====================Registers===========================================
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
    --=========================================================================

    process (clk) begin
        if reset = '0' then
            -- we need this?

        elsif rising_edge(clk) then
            case status is
                when fetch =>
                
                    
                when decode =>
                
                    
                when execute =>
                

                when memory =>


                when others =>
                -- reset
                status <= fetch;
            end case;
        end if;
   end process;
end behavioral;