-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;

--! @brief
--!	Arithmetic Logic Unit (ALU) with SMT support and shared resources.
--!
--! @details
--! 	Performs logic and arithmetic calculations for two threads simultaneously,
--!	provided they do not compete for the same functional unit.
entity pp_alu is
	port(
		-- Thread 0 (Main)
		x_0, y_0      : in  std_logic_vector(31 downto 0); --! Input operands for thread 0.
		operation_0   : in alu_operation;                  --! Operation for thread 0.
		result_0      : out std_logic_vector(31 downto 0); --! Result for thread 0.

		-- Thread 1
		x_1, y_1      : in  std_logic_vector(31 downto 0); --! Input operands for thread 1.
		operation_1   : in alu_operation;                  --! Operation for thread 1.
		result_1      : out std_logic_vector(31 downto 0)  --! Result for thread 1.
	);
end entity pp_alu;

--! @brief Behavioural description of the shared-resource ALU.
architecture behaviour of pp_alu is

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

	-- Shared Functional Unit Inputs
	signal arith_x, arith_y : std_logic_vector(31 downto 0);
	signal arith_op         : alu_operation;
	
	signal logic_x, logic_y : std_logic_vector(31 downto 0);
	signal logic_op         : alu_operation;

	signal shift_x, shift_y : std_logic_vector(31 downto 0);
	signal shift_op         : alu_operation;

	signal comp_x, comp_y   : std_logic_vector(31 downto 0);
	signal comp_op          : alu_operation;

	-- Shared Functional Unit Outputs
	signal arith_result : std_logic_vector(31 downto 0);
	signal logic_result : std_logic_vector(31 downto 0);
	signal shift_result : std_logic_vector(31 downto 0);
	signal comp_result  : std_logic_vector(31 downto 0);

begin

	---------------------------------------------------------------------------
	-- DISPATCH LOGIC: Assign thread operands to the appropriate shared unit --
	---------------------------------------------------------------------------

	dispatch: process(x_0, y_0, operation_0, x_1, y_1, operation_1)
		variable fu_0, fu_1 : functional_unit;
	begin
		fu_0 := get_fu(operation_0);
		fu_1 := get_fu(operation_1);

		-- Default assignments (Unit idle)
		arith_op <= ALU_INVALID;
		logic_op <= ALU_INVALID;
		shift_op <= ALU_INVALID;
		comp_op  <= ALU_INVALID;
		
		arith_x <= (others => '0'); arith_y <= (others => '0');
		logic_x <= (others => '0'); logic_y <= (others => '0');
		shift_x <= (others => '0'); shift_y <= (others => '0');
		comp_x  <= (others => '0'); comp_y  <= (others => '0');

		-- Thread 0 Dispatch (Priority)
		case fu_0 is
			when FU_ARITH => arith_x <= x_0; arith_y <= y_0; arith_op <= operation_0;
			when FU_LOGIC => logic_x <= x_0; logic_y <= y_0; logic_op <= operation_0;
			when FU_SHIFT => shift_x <= x_0; shift_y <= y_0; shift_op <= operation_0;
			when FU_COMP  => comp_x  <= x_0; comp_y  <= y_0; comp_op  <= operation_0;
			when others   => null;
		end case;

		-- Thread 1 Dispatch (only if no conflict with Thread 0)
		if fu_1 /= fu_0 or fu_1 = FU_NONE then
			case fu_1 is
				when FU_ARITH => arith_x <= x_1; arith_y <= y_1; arith_op <= operation_1;
				when FU_LOGIC => logic_x <= x_1; logic_y <= y_1; logic_op <= operation_1;
				when FU_SHIFT => shift_x <= x_1; shift_y <= y_1; shift_op <= operation_1;
				when FU_COMP  => comp_x  <= x_1; comp_y  <= y_1; comp_op  <= operation_1;
				when others   => null;
			end case;
		end if;
	end process dispatch;

	---------------------------------------------------------------------------
	-- SHARED FUNCTIONAL UNITS: Single instances of hardware blocks          --
	---------------------------------------------------------------------------

	-- 1. Shared Arithmetic Unit (Adder/Subtractor)
	arith_unit: process(arith_op, arith_x, arith_y)
	begin
		if arith_op = ALU_SUB then
			arith_result <= std_logic_vector(unsigned(arith_x) - unsigned(arith_y));
		else
			arith_result <= std_logic_vector(unsigned(arith_x) + unsigned(arith_y));
		end if;
	end process arith_unit;

	-- 2. Shared Logic Unit (AND/OR/XOR)
	logic_unit: process(logic_op, logic_x, logic_y)
	begin
		case logic_op is
			when ALU_AND => logic_result <= logic_x and logic_y;
			when ALU_OR  => logic_result <= logic_x or logic_y;
			when ALU_XOR => logic_result <= logic_x xor logic_y;
			when others  => logic_result <= (others => '0');
		end case;
	end process logic_unit;

	-- 3. Shared Shifter Unit (SLL/SRL/SRA)
	shift_unit: process(shift_op, shift_x, shift_y)
	begin
		case shift_op is
			when ALU_SLL => shift_result <= std_logic_vector(shift_left(unsigned(shift_x), to_integer(unsigned(shift_y(4 downto 0)))));
			when ALU_SRL => shift_result <= std_logic_vector(shift_right(unsigned(shift_x), to_integer(unsigned(shift_y(4 downto 0)))));
			when ALU_SRA => shift_result <= std_logic_vector(shift_right(signed(shift_x), to_integer(unsigned(shift_y(4 downto 0)))));
			when others  => shift_result <= (others => '0');
		end case;
	end process shift_unit;

	-- 4. Shared Comparator Unit (SLT/SLTU)
	comp_unit: process(comp_op, comp_x, comp_y)
	begin
		case comp_op is
			when ALU_SLT =>
				if signed(comp_x) < signed(comp_y) then
					comp_result <= (0 => '1', others => '0');
				else
					comp_result <= (others => '0');
				end if;
			when ALU_SLTU =>
				if unsigned(comp_x) < unsigned(comp_y) then
					comp_result <= (0 => '1', others => '0');
				else
					comp_result <= (others => '0');
				end if;
			when others => comp_result <= (others => '0');
		end case;
	end process comp_unit;

	---------------------------------------------------------------------------
	-- OUTPUT SELECTION: Route unit results back to the correct thread      --
	---------------------------------------------------------------------------

	output_routing: process(operation_0, operation_1, arith_result, logic_result, shift_result, comp_result)
		variable fu_0, fu_1 : functional_unit;
	begin
		fu_0 := get_fu(operation_0);
		fu_1 := get_fu(operation_1);

		-- Route result to Thread 0
		case fu_0 is
			when FU_ARITH => result_0 <= arith_result;
			when FU_LOGIC => result_0 <= logic_result;
			when FU_SHIFT => result_0 <= shift_result;
			when FU_COMP  => result_0 <= comp_result;
			when others   => result_0 <= (others => '0');
		end case;

		-- Route result to Thread 1 (only if no conflict with Thread 0)
		if fu_1 /= fu_0 then
			case fu_1 is
				when FU_ARITH => result_1 <= arith_result;
				when FU_LOGIC => result_1 <= logic_result;
				when FU_SHIFT => result_1 <= shift_result;
				when FU_COMP  => result_1 <= comp_result;
				when others   => result_1 <= (others => '0');
			end case;
		else
			result_1 <= (others => '0');
		end if;
	end process output_routing;

end architecture behaviour;
