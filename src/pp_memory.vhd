-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;

entity pp_memory is
	generic (
		LENGTH_MAIN   : positive := 8;
		LENGTH_THREAD : positive := 8
	); 
	port(
		clk     : in std_logic;
		reset   : in std_logic;
		stall   : in std_logic;
		flush_0 : in std_logic;
		flush_1 : in std_logic;

		-- Interrupt inputs:
		irq : in std_logic;

		-- Data memory inputs:
		dmem_data_in   : in std_logic_vector(31 downto 0);
		dmem_read_ack  : in std_logic;
		dmem_write_ack : in std_logic;

		-- Instruction 0 (Main Thread):
		rd_addr_in_0        : in  register_address;
		rd_addr_out_0       : out register_address;
		rd_data_in_0        : in  std_logic_vector(31 downto 0);
		rd_data_out_0       : out std_logic_vector(31 downto 0);
		rd_write_in_0       : in  std_logic;
		rd_write_out_0      : out std_logic;
		pc_0                : in std_logic_vector(31 downto 0);
		branch_0            : in  branch_type;
		op_num_in_0         : in  integer range 0 to LENGTH_MAIN;
		op_num_out_0        : out integer range 0 to LENGTH_MAIN;
		count_instr_in_0    : in  std_logic;
		count_instr_out_0   : out std_logic;
		count_instr_csr_in_0  : in  std_logic;
		count_instr_csr_out_0 : out std_logic;
		jump_taken_in_0     : in  std_logic;
		jump_taken_out_0    : out std_logic;
		jump_target_in_0    : in  std_logic_vector(31 downto 0);
		jump_target_out_0   : out std_logic_vector(31 downto 0);
		mem_op_in_0         : in  memory_operation_type;
		mem_op_out_0        : out memory_operation_type;
		mem_size_in_0       : in  memory_operation_size;

		-- Instruction 1 (Second Thread):
		rd_addr_in_1        : in  register_address;
		rd_addr_out_1       : out register_address;
		rd_data_in_1        : in  std_logic_vector(31 downto 0);
		rd_data_out_1       : out std_logic_vector(31 downto 0);
		rd_write_in_1       : in  std_logic;
		rd_write_out_1      : out std_logic;
		pc_1                : in std_logic_vector(31 downto 0);
		branch_1            : in  branch_type;
		op_num_in_1         : in  integer range 0 to LENGTH_THREAD;
		op_num_out_1        : out integer range 0 to LENGTH_THREAD;
		count_instr_in_1    : in  std_logic;
		count_instr_out_1   : out std_logic;
		count_instr_csr_in_1  : in  std_logic;
		count_instr_csr_out_1 : out std_logic;
		jump_taken_in_1     : in  std_logic;
		jump_taken_out_1    : out std_logic;
		jump_target_in_1    : in  std_logic_vector(31 downto 0);
		jump_target_out_1   : out std_logic_vector(31 downto 0);
		mem_op_in_1         : in  memory_operation_type;
		mem_op_out_1        : out memory_operation_type;
		mem_size_in_1       : in  memory_operation_size;
		-- CSR signals:
		csr_addr_in       	: in  csr_address;
		csr_addr_out      	: out csr_address;
		csr_value_in       	: in  std_logic_vector(31 downto 0);
		csr_value_out      	: out std_logic_vector(31 downto 0);
		csr_write_in      	: in  csr_write_mode;
		csr_write_out     	: out csr_write_mode;
		-- Exception signals Thread 0
		exception_in_0          : in  std_logic;
		exception_out_0         : out std_logic;
		exception_context_in_0  : in  csr_exception_context;
		exception_context_out_0 : out csr_exception_context;
		-- Exception signals Thread 1
		exception_in_1          : in  std_logic;
		exception_out_1         : out std_logic;
		exception_context_in_1  : in  csr_exception_context;
		exception_context_out_1 : out csr_exception_context
	);
end entity pp_memory;

architecture behaviour of pp_memory is
	signal mem_op_0, mem_op_1   : memory_operation_type;
	signal mem_size_0, mem_size_1 : memory_operation_size;
	signal rd_data_0, rd_data_1 : std_logic_vector(31 downto 0);
begin

	mem_op_out_0 <= mem_op_0;
	mem_op_out_1 <= mem_op_1;
	mem_size_out_0 <= mem_size_0;
	mem_size_out_1 <= mem_size_1;

	pipeline_register: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' or flush = '1' then
				-- Thread 0
				rd_write_out_0 <= '0';
				csr_write_out_0 <= CSR_WRITE_NONE;
				count_instr_out_0 <= '0';
				count_instr_csr_out_0 <= '0';
				mem_op_0 <= MEMOP_TYPE_NONE;
				op_num_out_0 <= LENGTH_MAIN;
				jump_taken_out_0 <= '0';
				jump_target_out_0 <= (others => '0');

				-- Thread 1
				rd_write_out_1 <= '0';
				csr_write_out_1 <= CSR_WRITE_NONE;
				count_instr_out_1 <= '0';
				count_instr_csr_out_1 <= '0';
				mem_op_1 <= MEMOP_TYPE_NONE;
				op_num_out_1 <= LENGTH_THREAD;
				jump_taken_out_1 <= '0';
				jump_target_out_1 <= (others => '0');
				
			elsif stall = '0' then
				-- Thread 0
				mem_size_0 <= mem_size_in_0;
				rd_data_0 <= rd_data_in_0;
				rd_addr_out_0 <= rd_addr_in_0;
				op_num_out_0 <= op_num_in_0;
				jump_taken_out_0 <= jump_taken_in_0;
				jump_target_out_0 <= jump_target_in_0;

				-- Thread 1
				mem_size_1 <= mem_size_in_1;
				rd_data_1 <= rd_data_in_1;
				rd_addr_out_1 <= rd_addr_in_1;
				op_num_out_1 <= op_num_in_1;
				jump_taken_out_1 <= jump_taken_in_1;
				jump_target_out_1 <= jump_target_in_1;

				if exception_in_0 = '1' then
					-- Exception for thread 0
					mem_op_0 <= MEMOP_TYPE_NONE;
					rd_write_out_0 <= '0';
					count_instr_out_0 <= '0';
					count_instr_csr_out_0 <= '0';
					csr_write_out <= CSR_WRITE_REPLACE;
					csr_addr_out <= CSR_MEPC;
					csr_data_out <= pc_0;
					-- Normal execution for thread 1
					mem_op_1 <= mem_op_in_1;
					rd_write_out_1 <= rd_write_in_1;
					count_instr_out_1 <= count_instr_in_1;
					count_instr_csr_out_1 <= count_instr_csr_in_1;
				elsif exception_in_1 = '1' then
					-- Normal execution for thread 0
					mem_op_0 <= mem_op_in_0;
					rd_write_out_0 <= rd_write_in_0;
					count_instr_out_0 <= count_instr_in_0;
					count_instr_csr_out_0 <= count_instr_csr_in_0;
					-- Exception for thread 1
					mem_op_1 <= MEMOP_TYPE_NONE;
					rd_write_out_1 <= '0';
					count_instr_out_1 <= '0';
					count_instr_csr_out_1 <= '0';
					csr_write_out <= CSR_WRITE_REPLACE;
					csr_addr_out <= CSR_MEPC;
					csr_data_out <= pc_1;
				else
					-- Normal execution for both threads
					mem_op_0 <= mem_op_in_0;
					rd_write_out_0 <= rd_write_in_0;
					count_instr_out_0 <= count_instr_in_0;
					count_instr_csr_out_0 <= count_instr_csr_in_0;
					mem_op_1 <= mem_op_in_1;
					rd_write_out_1 <= rd_write_in_1;
					count_instr_out_1 <= count_instr_in_1;
					count_instr_csr_out_1 <= count_instr_csr_in_1;
					csr_write_out <= csr_write_in;
					csr_addr_out <= csr_addr_in;
					csr_value_out <= csr_value_in;
				end if;
			end if;
		end if;
	end process pipeline_register;

	update_exception_context_0: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				exception_out_0 <= '0';
			else
				exception_out_0 <= exception_in_0 or to_std_logic(branch_0 = BRANCH_SRET);
				if exception_in_0 = '1' then
					exception_context_out_0.ie <= '0';
					exception_context_out_0.ie1 <= exception_context_in_0.ie;
					exception_context_out_0.cause <= exception_context_in_0.cause;
					exception_context_out_0.badaddr <= exception_context_in_0.badaddr;
				elsif branch_0 = BRANCH_SRET then
					exception_context_out_0.ie <= exception_context_in_0.ie1;
					exception_context_out_0.ie1 <= exception_context_in_0.ie;
					exception_context_out_0.cause <= CSR_CAUSE_NONE;
					exception_context_out_0.badaddr <= (others => '0');
				else
					exception_context_out_0.ie <= exception_context_in_0.ie;
					exception_context_out_0.ie1 <= exception_context_in_0.ie1;
					exception_context_out_0.cause <= CSR_CAUSE_NONE;
					exception_context_out_0.badaddr <= (others => '0');
				end if;
			end if;
		end if;
	end process update_exception_context_0;

	update_exception_context_1: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				exception_out_1 <= '0';
			else
				exception_out_1 <= exception_in_1 or to_std_logic(branch_1 = BRANCH_SRET);
				if exception_in_1 = '1' then
					exception_context_out_1.ie <= '0';
					exception_context_out_1.ie1 <= exception_context_in_1.ie;
					exception_context_out_1.cause <= exception_context_in_1.cause;
					exception_context_out_1.badaddr <= exception_context_in_1.badaddr;
				elsif branch_1 = BRANCH_SRET then
					exception_context_out_1.ie <= exception_context_in_1.ie1;
					exception_context_out_1.ie1 <= exception_context_in_1.ie;
					exception_context_out_1.cause <= CSR_CAUSE_NONE;
					exception_context_out_1.badaddr <= (others => '0');
				else
					exception_context_out_1.ie <= exception_context_in_1.ie;
					exception_context_out_1.ie1 <= exception_context_in_1.ie1;
					exception_context_out_1.cause <= CSR_CAUSE_NONE;
					exception_context_out_1.badaddr <= (others => '0');
				end if;
			end if;
		end if;
	end process update_exception_context_1;

	rd_data_mux_0: process(rd_data_0, dmem_data_in, mem_op_0, mem_size_0)
	begin
		if mem_op_0 = MEMOP_TYPE_LOAD or mem_op_0 = MEMOP_TYPE_LOAD_UNSIGNED then
			case mem_size_0 is
				when MEMOP_SIZE_BYTE =>
					if mem_op_0 = MEMOP_TYPE_LOAD_UNSIGNED then
						rd_data_out_0 <= std_logic_vector(resize(unsigned(dmem_data_in(7 downto 0)), rd_data_out_0'length));
					else
						rd_data_out_0 <= std_logic_vector(resize(signed(dmem_data_in(7 downto 0)), rd_data_out_0'length));
					end if;
				when MEMOP_SIZE_HALFWORD =>
					if mem_op_0 = MEMOP_TYPE_LOAD_UNSIGNED then
						rd_data_out_0 <= std_logic_vector(resize(unsigned(dmem_data_in(15 downto 0)), rd_data_out_0'length));
					else
						rd_data_out_0 <= std_logic_vector(resize(signed(dmem_data_in(15 downto 0)), rd_data_out_0'length));
					end if;
				when MEMOP_SIZE_WORD =>
					rd_data_out_0 <= dmem_data_in;
			end case;
		else
			rd_data_out_0 <= rd_data_0;
		end if;
	end process rd_data_mux_0;

	rd_data_mux_1: process(rd_data_1, dmem_data_in, mem_op_1, mem_size_1)
	begin
		if mem_op_1 = MEMOP_TYPE_LOAD or mem_op_1 = MEMOP_TYPE_LOAD_UNSIGNED then
			case mem_size_1 is
				when MEMOP_SIZE_BYTE =>
					if mem_op_1 = MEMOP_TYPE_LOAD_UNSIGNED then
						rd_data_out_1 <= std_logic_vector(resize(unsigned(dmem_data_in(7 downto 0)), rd_data_out_1'length));
					else
						rd_data_out_1 <= std_logic_vector(resize(signed(dmem_data_in(7 downto 0)), rd_data_out_1'length));
					end if;
				when MEMOP_SIZE_HALFWORD =>
					if mem_op_1 = MEMOP_TYPE_LOAD_UNSIGNED then
						rd_data_out_1 <= std_logic_vector(resize(unsigned(dmem_data_in(15 downto 0)), rd_data_out_1'length));
					else
						rd_data_out_1 <= std_logic_vector(resize(signed(dmem_data_in(15 downto 0)), rd_data_out_1'length));
					end if;
				when MEMOP_SIZE_WORD =>
					rd_data_out_1 <= dmem_data_in;
			end case;
		else
			rd_data_out_1 <= rd_data_1;
		end if;
	end process rd_data_mux_1;

end architecture behaviour;
