library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;

--! Arbiter needed to manage properly the execution of the ROBs. The managing is needed for the limited ALU's resources
entity arbiter is
    generic(
		NUM_INSTRUCTIONS_MAIN   : natural := 8; --! Number of instructions holded in the table
		NUM_INSTRUCTIONS_THREAD : natural := 8 --! Number of instructions holded in the table
	);
	port(
        clk                : in std_logic;
        rst                : in std_logic;
        stall              : in std_logic;

        execution_num_0    : in integer range 0 to NUM_INSTRUCTIONS_MAIN; 
        execution_alu_op_0 : in alu_operation;       
        execution_num_1    : in integer range 0 to NUM_INSTRUCTIONS_THREAD; 
        execution_alu_op_1 : in alu_operation;

        selector_op_0      : out std_logic;
        selector_op_1      : out std_logic
	);
end entity arbiter;

architecture behaviour of arbiter is

	-- Functional Unit classification
	type functional_unit is (FU_NONE, FU_ARITH, FU_LOGIC, FU_SHIFT, FU_COMP);

	function get_fu(op : alu_operation) return functional_unit is
	begin
		case op is
			when ALU_ADD | ALU_SUB => return FU_ARITH;
			when ALU_AND | ALU_OR | ALU_XOR => return FU_LOGIC;
			when ALU_SLL | ALU_SRL | ALU_SRA => return FU_SHIFT;
			when ALU_SLT | ALU_SLTU => return FU_COMP;
			when others => return FU_NONE;
		end case;
	end function;

	-- Signal to toggle priority between threads in case of conflict
	-- '0' means Thread 0 has priority, '1' means Thread 1 has priority
	signal priority_toggle : std_logic := '0';

begin

	-- Priority toggle management
	priority_proc: process(clk)
		variable fu_0, fu_1 : functional_unit;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				priority_toggle <= '0';
			else
				fu_0 := get_fu(execution_alu_op_0);
				fu_1 := get_fu(execution_alu_op_1);

				-- If there is a resource conflict and both instructions are valid (not NOPs)
				if (fu_0 = fu_1 and fu_0 /= FU_NONE) and 
				   (execution_num_0 /= NUM_INSTRUCTIONS_MAIN and execution_num_1 /= NUM_INSTRUCTIONS_THREAD) then
					priority_toggle <= not priority_toggle;
				end if;
			end if;
		end if;
	end process priority_proc;

	-- Arbitration logic
	arbitrate: process(execution_num_0, execution_alu_op_0, execution_num_1, execution_alu_op_1, priority_toggle, stall)
		variable fu_0, fu_1 : functional_unit;
	begin
		if stall = '1' then
			selector_op_0 <= 'Z';
			selector_op_1 <= 'Z';
		else
			fu_0 := get_fu(execution_alu_op_0);
			fu_1 := get_fu(execution_alu_op_1);

			-- Default: assume no wait
			selector_op_0 <= '0';
			selector_op_1 <= '0';

			-- 1. Check for NOPs (NOPs always get selector_op = '1')
			if execution_num_0 = NUM_INSTRUCTIONS_MAIN then
				selector_op_0 <= '1';
			end if;

			if execution_num_1 = NUM_INSTRUCTIONS_THREAD then
				selector_op_1 <= '1';
			end if;

			-- 2. Conflict handling (only if both are NOT NOPs)
			if (execution_num_0 /= NUM_INSTRUCTIONS_MAIN and execution_num_1 /= NUM_INSTRUCTIONS_THREAD) then
				if (fu_0 = fu_1 and fu_0 /= FU_NONE) then
					-- Resource conflict detected
					if priority_toggle = '0' then
						-- Thread 0 has priority
						selector_op_1 <= '1'; -- Thread 1 must wait
					else
						-- Thread 1 has priority
						selector_op_0 <= '1'; -- Thread 0 must wait
					end if;
				end if;
			end if;
		end if;
	end process arbitrate;

end architecture behaviour;
