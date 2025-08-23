library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- type for an instruction
package CPU_Types is
    type Instruction is record
        opcode      : std_logic_vector(3 downto 0);
        dest        : std_logic_vector(3 downto 0);
        src1        : std_logic_vector(3 downto 0);
        src2        : std_logic_vector(3 downto 0);
    end record;

    constant NOP : Instruction := (
        opcode => "0000", -- define as per your ISA
        src1   => (others => '0'),
        src2   => (others => '0'),
        dest   => (others => '0')
    );
end package CPU_Types;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.CPU_Types.all;

entity HazardUnit is
    Port (
        clk, reset, enable : in std_logic;
        zero_flag, zero_flag2 : in std_logic;
        instr_in      : in  Instruction;
        instr_out   : out std_logic_vector(15 downto 0);
        instr_parallel : out std_logic_vector(15 downto 0);
        prog_counter : out std_logic_vector(15 downto 0) := (others => '0')
    );
end HazardUnit;

architecture Behavioral of HazardUnit is
    type InstrArray is array (0 to 2) of Instruction;
    signal instr_buffer : InstrArray := (others => NOP);
    signal pointer      : unsigned(1 downto 0) := "00";

    ----------------------------------------------------------------------------
    -- State Machine Declaration
    ----------------------------------------------------------------------------
    type state_type is (START_STATE, RUN_STATE, STALL_STATE, COND_JUMP_STATE);
    signal current_state : state_type := START_STATE;
    signal load_count    : integer range 0 to 2 := 0;  -- count loaded instructions (0 to 2)
    signal jump_delay    : integer range 0 to 6 := 0;
    ----------------------------------------------------------------------------
    --Functions
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- Function to get next pointer mod 3
    function next_pointer(p : unsigned(1 downto 0)) return unsigned is
    begin
        if p = "10" then  -- 2 in binary (assuming 0 to 2)
            return "00";
        else
            return p + 1;
        end if;
    end function;
    ----------------------------------------------------------------------------
    --function check register dependency
    ----------------------------------------------------------------------------
    function register_dependency(inst_src1, inst_src2 : std_logic_vector(3 downto 0)) return boolean is
        begin
            if inst_src1 = inst_src2 then
                return true;
            end if;
            return false;
    end function;

    ----------------------------------------------------------------------------
    --function check memory dependency
    ----------------------------------------------------------------------------
    function memory_dependency(mem_src1, mem_src2 : std_logic_vector(7 downto 0)) return boolean is
        begin
            if mem_src1 = mem_src2 then
                return true;
            end if;
            return false;
    end function;

    ----------------------------------------------------------------------------
    --ALU range
    ----------------------------------------------------------------------------
    function isALUOp(op : std_logic_vector(3 downto 0)) return boolean is
        begin
            return (unsigned(op) >= to_unsigned(4, op'length)) and
                   (unsigned(op) <= to_unsigned(13, op'length));
    end function;
    ----------------------------------------------------------------------------
    function check_dependency(current_inst, next_inst : Instruction) return boolean is
    begin
        if current_inst.opcode = "0000" or next_inst.opcode = "1110" or next_inst.opcode = "1111" then
            return false;
        end if;

        --LOAD OR LOADI next is STORE
        if (current_inst.opcode = "0001" or current_inst.opcode = "0011") and next_inst.opcode = "0010" then
            return register_dependency(current_inst.dest, next_inst.dest);

        --LOAD OR LOADI next is ALU
        elsif (current_inst.opcode = "0001" or current_inst.opcode = "0011") and isALUOp(next_inst.opcode) then
            return (register_dependency(current_inst.dest, next_inst.src1) or register_dependency(current_inst.dest, next_inst.src2));
        
        --STORE next is LOAD
        elsif current_inst.opcode ="0010" and next_inst.opcode = "0001" then
            return memory_dependency((current_inst.src1 & current_inst.src2),(next_inst.src1 & next_inst.src2));

        --ALU next is ALU
        elsif isALUOp(current_inst.opcode) and isALUOp(next_inst.opcode) then
            return (register_dependency(current_inst.dest, next_inst.src1) or register_dependency(current_inst.dest, next_inst.src2));

        --ALU next is STORE
        elsif isALUOp(current_inst.opcode) and next_inst.opcode = "0010" then
            return register_dependency(current_inst.dest, next_inst.dest);
        end if;
        return false;
    end function;

    ----------------------------------------------------------------------------
    function Instruction_to_slv(instr : Instruction) return std_logic_vector is
        begin
            return instr.opcode & instr.dest & instr.src1 & instr.src2;
        end function;
        
    ----------------------------------------------------------------------------
    --Process
    ----------------------------------------------------------------------------

begin
        process(clk, reset)
            variable idx0, idx1, idx2 : unsigned(1 downto 0);
            variable dep_stage0, jump_on_cond, parallel_on : boolean;
            variable stall_counter : integer := 0;
            variable cond_counter : integer := 0;
            variable counter : integer := 0;
        begin
            if reset = '0' then
                instr_buffer   <= (others => NOP);
                pointer        <= "00";
                load_count     <= 0;
                stall_counter  := 0;
                current_state  <= START_STATE;
                prog_counter   <= (others => '0');
                instr_out      <= (others => '0');
                instr_parallel   <= (others => '0');
                counter        := 0;
                jump_delay     <= 0;
                jump_on_cond   := false;
            elsif rising_edge(clk) and enable = '0' then
                idx0 := pointer;                           -- stage0 (current)
                idx1 := next_pointer(pointer);             -- stage1 (second)
                idx2 := next_pointer(next_pointer(pointer)); -- stage2 (third)

                case current_state is
                    when START_STATE =>

                        instr_buffer(load_count) <= instr_in;
                        if load_count = 2 then
                            pointer <= "00";
                            current_state <= RUN_STATE;
                            load_count <= 0;
                        else
                            load_count <= load_count + 1;
                        end if;
                        instr_out <= (others => '0');
                        counter := counter + 1;

                    when RUN_STATE =>
                        instr_parallel <= Instruction_to_slv(NOP);
                        if instr_buffer(to_integer(idx0)).opcode = "1111" then

                            current_state <= COND_JUMP_STATE;
                            cond_counter := to_integer(unsigned(instr_buffer(to_integer(idx0)).src1 & instr_buffer(to_integer(idx0)).src2));
                            pointer <= next_pointer(pointer);
                            instr_buffer(to_integer(idx0)) <= instr_in;
                            dep_stage0 := false;
                            instr_out <= (others => '0');
                            counter := counter - 1;
                            jump_delay <= 0;

                        elsif instr_buffer(to_integer(idx0)).opcode = "1110" then
                            instr_out <= (others => '0');
                            counter := to_integer(unsigned(instr_buffer(to_integer(idx0)).src1 & instr_buffer(to_integer(idx0)).src2));
                            instr_buffer <= (others => NOP);
                            current_state <= START_STATE;

                        else
                            if instr_buffer(to_integer(idx0)) = NOP then
                                parallel_on := false;
                            elsif check_dependency(instr_buffer(to_integer(idx0)), instr_buffer(to_integer(idx1))) then
                                dep_stage0 := true;
                                parallel_on := false;
                            elsif check_dependency(instr_buffer(to_integer(idx0)), instr_buffer(to_integer(idx2))) then
                                dep_stage0 := true;
                                parallel_on := false;
                            elsif (not check_dependency(instr_buffer(to_integer(idx0)), instr_buffer(to_integer(idx1)))) and
                             not (instr_buffer(to_integer(idx1)).opcode = "1111" or instr_buffer(to_integer(idx1)).opcode = "1110") then
                                if check_dependency(instr_buffer(to_integer(idx1)), instr_buffer(to_integer(idx2))) or
                                    check_dependency(instr_buffer(to_integer(idx1)), instr_in) then
                                    dep_stage0 := true;
                                    parallel_on := true;
                                end if;
                                instr_parallel <= Instruction_to_slv(instr_buffer(to_integer(idx1)));
                                instr_buffer(to_integer(idx1)) <= NOP;
                                pointer <= next_pointer(pointer);
                            end if;
                                    
                            instr_out <= Instruction_to_slv(instr_buffer(to_integer(idx0)));

                            if dep_stage0 then
                                current_state <= STALL_STATE;
                                dep_stage0 := false;
                                counter := counter - 2;
                            end if;

                            instr_buffer(to_integer(idx0)) <= instr_in;
                            pointer <= next_pointer(pointer);
                            counter := counter + 1;
                        end if;

                    when STALL_STATE =>
                                
                        if stall_counter = 1 then
                            counter := counter + 1;
                        end if;

                        if stall_counter = 2 then
                            current_state <= RUN_STATE;
                            stall_counter := 0;
                            counter := counter + 1;
                        else
                            stall_counter := stall_counter + 1;
                        end if;
                        instr_out <= NOP.opcode & NOP.dest & NOP.src1 & NOP.src2;
                        instr_parallel <= NOP.opcode & NOP.dest & NOP.src1 & NOP.src2;

                    when COND_JUMP_STATE =>
                        if jump_delay = 5 then
                            if zero_flag2 = '1' and parallel_on then
                                    jump_on_cond := true;
                                    parallel_on := false;
                            elsif zero_flag = '1' and (not parallel_on) then
                                jump_on_cond := true;
                            else
                                counter := counter + 1;
                                jump_on_cond := false;
                            end if;
                        end if;

                        if jump_delay = 6 and jump_on_cond then
                            instr_buffer <= (others => NOP);
                            current_state <= START_STATE;
                            counter := cond_counter;
                        elsif jump_delay = 6 then
                            counter := counter + 1;
                            current_state <= RUN_STATE;
                        else
                            jump_delay <= jump_delay + 1;
                        end if;
                        instr_out <= (others => '0');
                        instr_parallel <= NOP.opcode & NOP.dest & NOP.src1 & NOP.src2;
                    end case;
                end if;
            prog_counter <= std_logic_vector(to_unsigned(counter, prog_counter'length));
        end process;
    end Behavioral;