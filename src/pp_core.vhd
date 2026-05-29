-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_constants.all;
use work.pp_utilities.all;
use work.pp_csr.all;

--! @brief The Potato Processor is a simple processor core for use in FPGAs.
entity pp_core is
	generic(
		PROCESSOR_ID           : std_logic_vector(31 downto 0) := x"00000000"; --! Processor ID.
		RESET_ADDRESS0          : std_logic_vector(31 downto 0) := x"00000000"; --! Address of the first instruction to execute.
		RESET_ADDRESS1          : std_logic_vector(31 downto 0) := x"00000000"; --! Address of the first instruction to execute.
		MTIME_DIVIDER          : positive := 5;                                --! Divider for the clock driving the MTIME counter
		TIME_DIVIDER           : positive := 5;                                --! Divider for the clock dirivng the TIME counter
		MAIN_TABLE			   : positive := 8;								   --! Length of the ROB's Main Table
		THREAD_TABLE		   : positive := 8								   --! Length of the ROB's THREAD Table
	);
	port(
		-- Control inputs:
		clk       : in std_logic; --! Processor clock
		reset     : in std_logic; --! Reset signal

		-- Instruction memory interface:
		imem_address_0 : out std_logic_vector(31 downto 0); --! Address of the next instruction
		imem_data_in_0 : in  std_logic_vector(31 downto 0); --! Instruction input
		imem_req_0     : out std_logic;
		imem_ack_0     : in  std_logic;

		-- Instruction memory interface:
		imem_address_1 : out std_logic_vector(31 downto 0); --! Address of the next instruction
		imem_data_in_1 : in  std_logic_vector(31 downto 0); --! Instruction input
		imem_req_1     : out std_logic;
		imem_ack_1     : in  std_logic;

		-- Data memory interface:
		dmem_address   : out std_logic_vector(31 downto 0);  --! Data address
		dmem_data_in   : in  std_logic_vector(31 downto 0);  --! Input from the data memory
		dmem_data_out  : out std_logic_vector(31 downto 0);  --! Ouptut to the data memory
		dmem_data_size : out std_logic_vector( 1 downto 0);  --! Size of the data, 1 = 8 bits, 2 = 16 bits, 0 = 32 bits. 
		dmem_read_req  : out std_logic;                      --! Data memory read request
		dmem_read_ack  : in  std_logic;                      --! Data memory read acknowledge
		dmem_write_req : out std_logic;                      --! Data memory write request
		dmem_write_ack : in  std_logic;                      --! Data memory write acknowledge

		-- Test interface:
		test_context_out : out test_context;                 --! Test context output.

		-- External interrupt input:
		irq : in std_logic_vector(7 downto 0) --! IRQ inputs.
	);
end entity pp_core;

architecture behaviour of pp_core is

	-- Flush signals:
	signal flush_if_0, flush_id_0, flush_if_1, flush_id_1 : std_logic;
	signal flush_ex_0, flush_ex_1, flush_mem_0, flush_mem_1, flush_wb_0, flush_wb_1 : std_logic;

	-- Stall signals:
	signal stall_if_0, stall_id_0, stall_if_1, stall_id_1 : std_logic;
	signal stall_ex, stall_mem, stall_wb, id_stall_csr_0, id_stall_csr_1 : std_logic;
	signal stall_rob_0, rob_stall_fetch_decode_0, stall_rob_1, rob_stall_fetch_decode_1 : std_logic;

	-- Signals used to determine if an instruction should be counted by the instret counter:
	signal if_count_instruction_0, id_count_instruction_0, if_count_instruction_1, id_count_instruction_1 : std_logic;
	signal ex_count_instruction_0, ex_count_instruction_1, mem_count_instruction_0, mem_count_instruction_1 : std_logic;
	signal wb_count_instruction_0, wb_count_instruction_1 : std_logic;

	-- Signals used to determine if an instruction is a CSR 
	signal ex_count_instruction_csr_0, ex_count_instruction_csr_1 : std_logic;
	signal mem_count_instruction_csr_0, mem_count_instruction_csr_1 : std_logic;
	signal wb_count_instruction_csr, wb_count_instruction_csr_0, wb_count_instruction_csr_1 : std_logic;

	-- CSR read port signals:
	signal csr_read_data      : std_logic_vector(31 downto 0);
	signal csr_read_address, csr_read_address_p : csr_address;

	-- Status register outputs:
	signal mtvec   : std_logic_vector(31 downto 0);
	signal mie     : std_logic_vector(31 downto 0);
	signal ie, ie1 : std_logic;

	-- Internal interrupt signals:
	signal software_interrupt, timer_interrupt : std_logic;

	-- Branch targets:
	signal exception_target, branch_target_0, branch_target_1 : std_logic_vector(31 downto 0);
	signal branch_taken_0, branch_taken_1, exception_taken_0, exception_taken_1 : std_logic;

	-- Register file read ports:
	signal rf_rs1_data_0, rf_rs2_data_0, rf_rs1_data_1, rf_rs2_data_1 : std_logic_vector(31 downto 0);

	-- Data memory signals:
	signal sg_dmem_address  : std_logic_vector(31 downto 0);
	signal dmem_address_p   : std_logic_vector(31 downto 0);
	signal dmem_data_size_p : std_logic_vector(1 downto 0);
	signal dmem_data_out_p  : std_logic_vector(31 downto 0);
	signal dmem_read_req_p  : std_logic;
	signal dmem_write_req_p : std_logic;
	signal stall_mem_p 		: std_logic;
	signal ack_p		   	: std_logic;

	-- Fetch stage signals:
	signal if_instruction_0, if_pc_0, if_instruction_1, if_pc_1 : std_logic_vector(31 downto 0);
	signal if_instruction_ready_0, if_instruction_ready_1  : std_logic;

	-- Decode stage signals:
	signal id_funct3_0          : std_logic_vector(2 downto 0);
	signal id_rd_address_0      : register_address;
	signal id_rd_write_0        : std_logic;
	signal id_rs1_address_0     : register_address;
	signal id_rs2_address_0     : register_address;
	signal id_csr_address_0     : csr_address;
	signal id_csr_write_0       : csr_write_mode;
	signal id_csr_use_immediate_0 : std_logic;
	signal id_shamt_0           : std_logic_vector(4 downto 0);
	signal id_immediate_0       : std_logic_vector(31 downto 0);
	signal id_branch_0          : branch_type;
	signal id_alu_x_src_0, id_alu_y_src_0 : alu_operand_source;
	signal id_alu_op_0          : alu_operation;
	signal id_mem_op_0          : memory_operation_type;
	signal id_mem_size_0        : memory_operation_size;
	signal id_pc_0              : std_logic_vector(31 downto 0);
	signal id_exception_0       : std_logic;
	signal id_exception_cause_0 : csr_exception_cause;
	signal id_count_instruction_csr_0 : std_logic;

	signal id_funct3_1          : std_logic_vector(2 downto 0);
	signal id_rd_address_1      : register_address;
	signal id_rd_write_1        : std_logic;
	signal id_rs1_address_1     : register_address;
	signal id_rs2_address_1     : register_address;
	signal id_csr_address_1     : csr_address;
	signal id_csr_write_1       : csr_write_mode;
	signal id_csr_use_immediate_1 : std_logic;
	signal id_shamt_1           : std_logic_vector(4 downto 0);
	signal id_immediate_1       : std_logic_vector(31 downto 0);
	signal id_branch_1          : branch_type;
	signal id_alu_x_src_1, id_alu_y_src_1 : alu_operand_source;
	signal id_alu_op_1          : alu_operation;
	signal id_mem_op_1          : memory_operation_type;
	signal id_mem_size_1        : memory_operation_size;
	signal id_pc_1              : std_logic_vector(31 downto 0);
	signal id_exception_1       : std_logic;
	signal id_exception_cause_1 : csr_exception_cause;
	signal id_count_instruction_csr_1 : std_logic;

	-- ROB stage signals:
	signal rob_alu_x_addr_0 	: register_address;
	signal rob_alu_y_addr_0 	: register_address;
	signal rob_rd_addr_0 		: register_address;
	signal rob_rd_write_0 	: std_logic;
	signal rob_result_0 		: std_logic_vector(31 downto 0);
	signal rob_num_0  		: integer range 0 to MAIN_TABLE;
	signal rob_alu_op_0 		: alu_operation;
	signal rob_alu_x_src_0 	: alu_operand_source;
	signal rob_alu_y_src_0 	: alu_operand_source;
	signal rob_immediate_0 	: std_logic_vector(31 downto 0);
	signal rob_shamt_0 		: std_logic_vector(4 downto 0);
	signal rob_mem_op_0		: memory_operation_type;
	signal rob_mem_size_0		: memory_operation_size;
	signal rob_branch_0		: branch_type;
	signal rob_funct3_0		: std_logic_vector(2 downto 0);
	signal rob_pc_0 			: std_logic_vector(31 downto 0);
	signal rob_table_empty_0  : std_logic;

	signal rob_alu_x_addr_1 	: register_address;
	signal rob_alu_y_addr_1 	: register_address;
	signal rob_rd_addr_1 		: register_address;
	signal rob_rd_write_1 	: std_logic;
	signal rob_result_1 		: std_logic_vector(31 downto 0);
	signal rob_num_1  		: integer range 0 to THREAD_TABLE;
	signal rob_alu_op_1 		: alu_operation;
	signal rob_alu_x_src_1 	: alu_operand_source;
	signal rob_alu_y_src_1 	: alu_operand_source;
	signal rob_immediate_1 	: std_logic_vector(31 downto 0);
	signal rob_shamt_1 		: std_logic_vector(4 downto 0);
	signal rob_mem_op_1		: memory_operation_type;
	signal rob_mem_size_1		: memory_operation_size;
	signal rob_branch_1		: branch_type;
	signal rob_funct3_1		: std_logic_vector(2 downto 0);
	signal rob_pc_1 			: std_logic_vector(31 downto 0);
	signal rob_table_empty_1  : std_logic;

	-- Arbiter
	signal arbiter_sel_0, arbiter_sel_1 : std_logic;

	-- Multiplexer for Register File signals:
	signal mux_rf_rs1_addr_0, mux_rf_rs1_addr_1 : register_address;
	signal mux_rf_rs2_addr_0, mux_rf_rs2_addr_1 : register_address;
	signal mux_rf_rd_addr_0, mux_rf_rd_addr_1  : register_address;
	signal mux_rf_rd_data_0, mux_rf_rd_data_1  : std_logic_vector(31 downto 0);
	signal mux_rf_rd_write_0, mux_rf_rd_write_1 : std_logic;

	-- Multiplexer for Execute signals:
	signal mux_exe_rs1_address_0, mux_exe_rs1_address_1  : register_address;
	signal mux_exe_rs2_address_0, mux_exe_rs2_address_1  : register_address;
	signal mux_exe_alu_x_src_0, mux_exe_alu_x_src_1    : alu_operand_source;
	signal mux_exe_alu_y_src_0, mux_exe_alu_y_src_1    : alu_operand_source;
	signal mux_exe_rd_write_0, mux_exe_rd_write_1	    : std_logic;
	signal mux_exe_rd_addr_0, mux_exe_rd_addr_1	    : register_address;
	signal mux_exe_alu_op_0, mux_exe_alu_op_1	    : alu_operation;
	signal mux_exe_branch_0, mux_exe_branch_1         : branch_type;
	signal mux_exe_funct3_0, mux_exe_funct3_1         : std_logic_vector(2 downto 0);
	signal mux_exe_mem_op_0, mux_exe_mem_op_1         : memory_operation_type;
	signal mux_exe_op_num_0                           : integer range 0 to MAIN_TABLE;
	signal mux_exe_op_num_1                           : integer range 0 to THREAD_TABLE;

	-- Execute stage signals:
	signal ex_dmem_address   : std_logic_vector(31 downto 0);
	signal ex_dmem_data_size : std_logic_vector(1 downto 0);
	signal ex_dmem_data_out  : std_logic_vector(31 downto 0);
	signal ex_dmem_read_req  : std_logic;
	signal ex_dmem_write_req : std_logic;

	signal ex_rd_address_0, ex_rd_address_1     : register_address;
	signal ex_rd_data_0, ex_rd_data_1        : std_logic_vector(31 downto 0);
	signal ex_rd_write_0, ex_rd_write_1       : std_logic;
	signal ex_pc_0, ex_pc_1             : std_logic_vector(31 downto 0);
	signal ex_csr_addr 	: csr_address;
	signal ex_csr_write : csr_write_mode;
	signal ex_csr_value : std_logic_vector(31 downto 0);
	signal ex_branch_0, ex_branch_1         : branch_type;
	signal ex_mem_op_0, ex_mem_op_1         : memory_operation_type;
	signal ex_mem_size_0, ex_mem_size_1       : memory_operation_size;
	signal ex_num_0 			 : integer range 0 to MAIN_TABLE;
	signal ex_num_1 			 : integer range 0 to THREAD_TABLE;
	signal ex_jump_taken_0, ex_jump_taken_1	 : std_logic;
	signal ex_jump_target_0, ex_jump_target_1  	 : std_logic_vector(31 downto 0);
	signal ex_exception_context_0, ex_exception_context_1 	: csr_exception_context;
	signal to_exe_count_instruction_0, to_exe_count_instruction_1 : std_logic;
	

	-- Memory stage signals:
	signal mem_rd_write_0, mem_rd_write_1    : std_logic;
	signal mem_rd_address_0, mem_rd_address_1  : register_address;
	signal mem_rd_data_0, mem_rd_data_1     : std_logic_vector(31 downto 0);
	signal mem_csr_addr : csr_address;
	signal mem_csr_write : csr_write_mode;
	signal mem_csr_value : std_logic_vector(31 downto 0);
	signal mem_mem_op_0, mem_mem_op_1      : memory_operation_type;
	signal mem_op_num_0 	   : integer range 0 to MAIN_TABLE;
	signal mem_op_num_1 	   : integer range 0 to THREAD_TABLE;
	signal mem_jump_taken_0, mem_jump_taken_1  : std_logic;
	signal mem_jump_target_0, mem_jump_target_1 : std_logic_vector(31 downto 0);
	signal mem_exception_0, mem_exception_1         : std_logic;
	signal mem_exception_context_0, mem_exception_context_1 : csr_exception_context;

	-- Writeback signals:
	signal wb_rd_address_0, wb_rd_address_1 : register_address;
	signal wb_rd_data_0, wb_rd_data_1       : std_logic_vector(31 downto 0);
	signal wb_rd_write_0, wb_rd_write_1     : std_logic;
	signal wb_csr_address : csr_address;
	signal wb_csr_write   : csr_write_mode;
	signal wb_csr_data    : std_logic_vector(31 downto 0);
	signal wb_exception_0, wb_exception_1 : std_logic;
	signal wb_exception         : std_logic;
	signal wb_exception_context_0, wb_exception_context_1 : csr_exception_context;
	signal wb_exception_context : csr_exception_context;
	signal wb_dmem_address  : std_logic_vector(31 downto 0);
	signal wb_num_0 : integer range 0 to MAIN_TABLE;
	signal wb_num_1 : integer range 0 to THREAD_TABLE;
	signal wb_jump_taken_0, wb_jump_taken_1 : std_logic;
	signal wb_jump_target_0, wb_jump_target_1 : std_logic_vector(31 downto 0);

begin

	------- Stalls and Flushes -------
	stall_if_0 <= rob_stall_fetch_decode_0 or id_stall_csr_0;
	stall_if_1 <= rob_stall_fetch_decode_1 or id_stall_csr_1;
	stall_id_0 <= rob_stall_fetch_decode_0;
	stall_id_1 <= rob_stall_fetch_decode_1;
	stall_rob_0 <= stall_mem;
	stall_rob_1 <= stall_mem;
	stall_ex <= stall_mem;
	stall_mem <= to_std_logic(memop_is_load(mem_mem_op_0) and dmem_read_ack = '0')
		or to_std_logic(mem_mem_op_0 = MEMOP_TYPE_STORE and dmem_write_ack = '0')
		or to_std_logic(memop_is_load(mem_mem_op_1) and dmem_read_ack = '0')
		or to_std_logic(mem_mem_op_1 = MEMOP_TYPE_STORE and dmem_write_ack = '0');
	stall_wb <= stall_mem;
	
	flush_if_0  <= (branch_taken_0 or exception_taken_0) and not stall_if_0;
	flush_if_1  <= (branch_taken_1 or exception_taken_1) and not stall_if_1;
	flush_id_0  <= (branch_taken_0 or exception_taken_0) and not stall_id_0;
	flush_id_1  <= (branch_taken_1 or exception_taken_1) and not stall_id_1;
	flush_ex_0  <= (branch_taken_0 or exception_taken_0) and not stall_ex; 
	flush_ex_1  <= (branch_taken_1 or exception_taken_1) and not stall_ex; 
	flush_mem_0 <= (branch_taken_0 or exception_taken_0) and not stall_mem;
	flush_mem_1 <= (branch_taken_1 or exception_taken_1) and not stall_mem;
	flush_wb_0  <= (branch_taken_0 or exception_taken_0) and not stall_wb;
	flush_wb_1  <= (branch_taken_1 or exception_taken_1) and not stall_wb;

	------- Control and status module -------
	csr_unit: entity work.pp_csr_unit
			generic map(
				PROCESSOR_ID  => PROCESSOR_ID,
				MTIME_DIVIDER => MTIME_DIVIDER,
				TIME_DIVIDER  => TIME_DIVIDER
			) port map(
				clk 					=> clk,
				reset 					=> reset,
				irq 					=> irq,
				count_instruction_0		=> wb_count_instruction_0,
				count_instruction_1		=> wb_count_instruction_1,
				count_instruction_csr 	=> wb_count_instruction_csr,
				test_context_out 		=> test_context_out,
				read_address 			=> csr_read_address,
				read_data_out 			=> csr_read_data,
				write_address 			=> wb_csr_address,
				write_data_in 			=> wb_csr_data,
				write_mode 				=> wb_csr_write,
				exception_context 		=> wb_exception_context,
				exception_context_write => wb_exception,
				mie_out 				=> mie,
				mtvec_out	 			=> mtvec,
				ie_out 					=> ie,
				ie1_out 				=> ie1,
				software_interrupt_out 	=> software_interrupt,
				timer_interrupt_out 	=> timer_interrupt
			);
	
	wb_count_instruction_csr <= wb_count_instruction_csr_0 or wb_count_instruction_csr_1;
	wb_exception_context <= wb_exception_context_0 when wb_count_instruction_csr_0 = '0' else wb_exception_context_1;
	wb_exception <= wb_exception_0 when wb_count_instruction_csr_0 = '0' else wb_exception_1;
	
	csr_read_address <= csr_read_address_p when stall_ex = '1' else
                    id_csr_address_0   when id_count_instruction_csr_0 = '1' else
                    id_csr_address_1;

	store_previous_csr_addr: process(clk, stall_ex)
	begin
		if rising_edge(clk) and stall_ex = '0' then
			csr_read_address_p <= id_csr_address_0 when id_count_instruction_csr_0 = '1' else id_csr_address_1;
		end if;
	end process store_previous_csr_addr;

	------- Instruction Fetch (IF) Stage -------
	fetch_0: entity work.pp_fetch
		generic map(
			RESET_ADDRESS => RESET_ADDRESS0
		) port map(
			clk 				=> clk,
			reset 				=> reset,
			imem_address 		=> imem_address_0,
			imem_data_in 		=> imem_data_in_0,
			imem_req 			=> imem_req_0,
			imem_ack 			=> imem_ack_0,
			stall 				=> stall_if_0,
			flush 				=> flush_if_0,
			branch 				=> branch_taken_0,
			exception 			=> exception_taken_0,
			branch_target 		=> branch_target_0,
			evec 				=> exception_target,
			instruction_data 	=> if_instruction_0,
			instruction_address => if_pc_0,
			instruction_ready 	=> if_instruction_ready_0
		);

	fetch_1: entity work.pp_fetch
		generic map(
			RESET_ADDRESS => RESET_ADDRESS1
		) port map(
			clk 				=> clk,
			reset 				=> reset,
			imem_address 		=> imem_address_1,
			imem_data_in 		=> imem_data_in_1,
			imem_req 			=> imem_req_1,
			imem_ack 			=> imem_ack_1,
			stall 				=> stall_if_1,
			flush 				=> flush_if_1,
			branch 				=> branch_taken_1,
			exception 			=> exception_taken_1,
			branch_target 		=> branch_target_1,
			evec 				=> exception_target,
			instruction_data 	=> if_instruction_1,
			instruction_address => if_pc_1,
			instruction_ready 	=> if_instruction_ready_1
		);

	if_count_instruction_0 <= if_instruction_ready_0;
	if_count_instruction_1 <= if_instruction_ready_1;

	------- Instruction Decode (ID) Stage -------
	decode_0: entity work.pp_decode
		generic map(
			RESET_ADDRESS => RESET_ADDRESS0,
			PROCESSOR_ID  => PROCESSOR_ID
		) port map(
			clk 					=> clk,
			reset 					=> reset, 
			flush 					=> flush_id_0,
			stall 					=> stall_id_0,
			instruction_data 		=> if_instruction_0,
			instruction_address 	=> if_pc_0,
			instruction_ready 		=> if_instruction_ready_0,
			instruction_count 		=> if_count_instruction_0,
			funct3 					=> id_funct3_0,
			rs1_addr 				=> id_rs1_address_0,
			rs2_addr 				=> id_rs2_address_0,
			rd_addr 				=> id_rd_address_0,
			csr_addr 				=> id_csr_address_0,
			shamt 					=> id_shamt_0,
			immediate 				=> id_immediate_0,
			rd_write 				=> id_rd_write_0,
			branch 					=> id_branch_0,
			alu_x_src 				=> id_alu_x_src_0,
			alu_y_src 				=> id_alu_y_src_0,
			alu_op 					=> id_alu_op_0,
			mem_op 					=> id_mem_op_0,
			mem_size 				=> id_mem_size_0,
			count_instruction	 	=> id_count_instruction_0,
			count_instruction_csr 	=> id_count_instruction_csr_0,
			pc	 					=> id_pc_0,
			csr_write 				=> id_csr_write_0,
			csr_use_imm 			=> id_csr_use_immediate_0,
			stall_csr 				=> id_stall_csr_0,
			rob_table_empty 		=> rob_table_empty_0,
			ext_count_instruction_csr => id_count_instruction_csr_1,
			decode_exception 		=> id_exception_0,
			decode_exception_cause 	=> id_exception_cause_0
		);

	decode_1: entity work.pp_decode
		generic map(
			RESET_ADDRESS => RESET_ADDRESS1,
			PROCESSOR_ID  => PROCESSOR_ID
		) port map(
			clk 					  => clk,
			reset 					  => reset, 
			flush 					  => flush_id_1,
			stall 					  => stall_id_1,
			instruction_data 		  => if_instruction_1,
			instruction_address 	  => if_pc_1,
			instruction_ready 		  => if_instruction_ready_1,
			instruction_count 		  => if_count_instruction_1,
			funct3 					  => id_funct3_1,
			rs1_addr 				  => id_rs1_address_1,
			rs2_addr 				  => id_rs2_address_1,
			rd_addr 				  => id_rd_address_1,
			csr_addr 				  => id_csr_address_1,
			shamt 					  => id_shamt_1,
			immediate 				  => id_immediate_1,
			rd_write 				  => id_rd_write_1,
			branch 					  => id_branch_1,
			alu_x_src 				  => id_alu_x_src_1,
			alu_y_src 				  => id_alu_y_src_1,
			alu_op 					  => id_alu_op_1,
			mem_op 					  => id_mem_op_1,
			mem_size 				  => id_mem_size_1,
			count_instruction	 	  => id_count_instruction_1,
			count_instruction_csr 	  => id_count_instruction_csr_1,
			pc	 					  => id_pc_1,
			csr_write 				  => id_csr_write_1,
			csr_use_imm 			  => id_csr_use_immediate_1,
			stall_csr 				  => id_stall_csr_1,
			rob_table_empty 		  => rob_table_empty_1,
			ext_count_instruction_csr => id_count_instruction_csr_0,
			decode_exception 		  => id_exception_1,
			decode_exception_cause 	  => id_exception_cause_1
		);

		------- Register file -------
	regfile_0: entity work.pp_register_file
		port map(
			clk  	 => clk,
			rs1_addr => mux_rf_rs1_addr_0,
			rs2_addr => mux_rf_rs2_addr_0,
			rs1_data => rf_rs1_data_0,
			rs2_data => rf_rs2_data_0,
			rd_addr  => mux_rf_rd_addr_0,
			rd_data  => mux_rf_rd_data_0,
			rd_write => mux_rf_rd_write_0
		);

	regfile_1: entity work.pp_register_file
		port map(
			clk  	 => clk,
			rs1_addr => mux_rf_rs1_addr_1,
			rs2_addr => mux_rf_rs2_addr_1,
			rs1_data => rf_rs1_data_1,
			rs2_data => rf_rs2_data_1,
			rd_addr  => mux_rf_rd_addr_1,
			rd_data  => mux_rf_rd_data_1,
			rd_write => mux_rf_rd_write_1
		);
		
	mux_rf_rs1_addr_0 <= rob_alu_x_addr_0 when id_count_instruction_csr_0 = '0' else id_rs1_address_0;
	mux_rf_rs2_addr_0 <= rob_alu_y_addr_0 when id_count_instruction_csr_0 = '0' else id_rs2_address_0;
	mux_rf_rd_addr_0  <= rob_rd_addr_0    when wb_count_instruction_csr_0 = '0' else wb_rd_address_0;
	mux_rf_rd_data_0  <= rob_result_0     when wb_count_instruction_csr_0 = '0' else wb_rd_data_0;
	mux_rf_rd_write_0 <= rob_rd_write_0   when wb_count_instruction_csr_0 = '0' else wb_rd_write_0;	

	mux_rf_rs1_addr_1 <= rob_alu_x_addr_1 when id_count_instruction_csr_1 = '0' else id_rs1_address_1;
	mux_rf_rs2_addr_1 <= rob_alu_y_addr_1 when id_count_instruction_csr_1 = '0' else id_rs2_address_1;
	mux_rf_rd_addr_1  <= rob_rd_addr_1    when wb_count_instruction_csr_1 = '0' else wb_rd_address_1;
	mux_rf_rd_data_1  <= rob_result_1     when wb_count_instruction_csr_1 = '0' else wb_rd_data_1;
	mux_rf_rd_write_1 <= rob_rd_write_1   when wb_count_instruction_csr_1 = '0' else wb_rd_write_1;	

	------- Reorder Buffer (ROB) Stage -------

	--! Reorder Buffer Declaration
	reorder_buffer_0: entity work.rob 
        generic map(
	    	NUM_INSTRUCTIONS => MAIN_TABLE
	    ) port map (
            clk             		=> clk,
            reset             		=> reset,
			stall					=> stall_rob_0,
			count_instruction		=> id_count_instruction_0,
			pc_in					=> id_pc_0,
            alu_op_in        		=> id_alu_op_0,
			alu_x_src_in			=> id_alu_x_src_0,
			alu_x_addr_in			=> id_rs1_address_0,
			alu_y_src_in			=> id_alu_y_src_0,
			alu_y_addr_in			=> id_rs2_address_0,
			rd_addr_in				=> id_rd_address_0,
			rd_write_in				=> id_rd_write_0,
			immediate_in			=> id_immediate_0,
			shamt_in				=> id_shamt_0,
			mem_op_in  				=> id_mem_op_0,
			mem_size_in				=> id_mem_size_0,
			branch_in 				=> id_branch_0,
			funct3_in 				=> id_funct3_0,
            execution_num  			=> rob_num_0,
			execution_alu_op 		=> rob_alu_op_0,
			execution_alu_x_src 	=> rob_alu_x_src_0,
			execution_alu_x_addr 	=> rob_alu_x_addr_0,
			execution_alu_y_src 	=> rob_alu_y_src_0,
			execution_alu_y_addr 	=> rob_alu_y_addr_0,
			execution_immediate 	=> rob_immediate_0,
			execution_shamt 		=> rob_shamt_0,
        	execution_mem_op        => rob_mem_op_0,
        	execution_mem_size      => rob_mem_size_0,
			execution_pc 			=> rob_pc_0,
			execution_branch 		=> rob_branch_0,
			execution_funct3 		=> rob_funct3_0,
			execution_valid        	=> arbiter_sel_0,
			completed_count_instr 	=> wb_count_instruction_0,
            completed_num  			=> wb_num_0,
			completed_res			=> wb_rd_data_0,
			completed_jump_taken 	=> wb_jump_taken_0,
			completed_jump_target 	=> wb_jump_target_0,
			commit_rd_addr 			=> rob_rd_addr_0,
			commit_rd_write 		=> rob_rd_write_0,
			commit_res 				=> rob_result_0,
			commit_jump_target 		=> branch_target_0,
			commit_jump_taken 		=> branch_taken_0,
			commit_num 				=> open, -- Testing signals
			commit_op				=> open, -- Testing signals 
			commit_x_src 			=> open, -- Testing signals
        	commit_y_src 			=> open, -- Testing signals
			commit_mem_op			=> open, -- Testing signals
			commit_mem_size			=> open, -- Testing signals		
			fetch_enable			=> rob_stall_fetch_decode_0,
			rob_empty 				=> rob_table_empty_0
	    );

	reorder_buffer_1: entity work.rob 
        generic map(
	    	NUM_INSTRUCTIONS => THREAD_TABLE
	    ) port map (
            clk             		=> clk,
            reset             		=> reset,
			stall					=> stall_rob_1,
			count_instruction		=> id_count_instruction_1,
			pc_in					=> id_pc_1,
            alu_op_in        		=> id_alu_op_1,
			alu_x_src_in			=> id_alu_x_src_1,
			alu_x_addr_in			=> id_rs1_address_1,
			alu_y_src_in			=> id_alu_y_src_1,
			alu_y_addr_in			=> id_rs2_address_1,
			rd_addr_in				=> id_rd_address_1,
			rd_write_in				=> id_rd_write_1,
			immediate_in			=> id_immediate_1,
			shamt_in				=> id_shamt_1,
			mem_op_in  				=> id_mem_op_1,
			mem_size_in				=> id_mem_size_1,
			branch_in 				=> id_branch_1,
			funct3_in 				=> id_funct3_1,
            execution_num  			=> rob_num_1,
			execution_alu_op 		=> rob_alu_op_1,
			execution_alu_x_src 	=> rob_alu_x_src_1,
			execution_alu_x_addr 	=> rob_alu_x_addr_1,
			execution_alu_y_src 	=> rob_alu_y_src_1,
			execution_alu_y_addr 	=> rob_alu_y_addr_1,
			execution_immediate 	=> rob_immediate_1,
			execution_shamt 		=> rob_shamt_1,
        	execution_mem_op        => rob_mem_op_1,
        	execution_mem_size      => rob_mem_size_1,
			execution_pc 			=> rob_pc_1,
			execution_branch 		=> rob_branch_1,
			execution_funct3 		=> rob_funct3_1,
			execution_valid        	=> arbiter_sel_1,
			completed_count_instr 	=> wb_count_instruction_1,
            completed_num  			=> wb_num_1,
			completed_res			=> wb_rd_data_1,
			completed_jump_taken 	=> wb_jump_taken_1,
			completed_jump_target 	=> wb_jump_target_1,
			commit_rd_addr 			=> rob_rd_addr_1,
			commit_rd_write 		=> rob_rd_write_1,
			commit_res 				=> rob_result_1,
			commit_jump_target 		=> branch_target_1,
			commit_jump_taken 		=> branch_taken_1,
			commit_num 				=> open, -- Testing signals
			commit_op				=> open, -- Testing signals 
			commit_x_src 			=> open, -- Testing signals
        	commit_y_src 			=> open, -- Testing signals
			commit_mem_op			=> open, -- Testing signals
			commit_mem_size			=> open, -- Testing signals		
			fetch_enable			=> rob_stall_fetch_decode_1,
			rob_empty 				=> rob_table_empty_1
	    );

	-- Arbiter to manage the SMT and to avoid resources conflicts
	arbiter: entity work.pp_arbiter
		generic map(
			NUM_INSTRUCTIONS_MAIN 	=> MAIN_TABLE,
			NUM_INSTRUCTIONS_THREAD => THREAD_TABLE
		) port map (
        	clk                => clk,
        	rst                => reset,
			stall 			   => '0',
        	execution_num_0    => rob_num_0, 
        	execution_alu_op_0 => rob_alu_op_0,       
        	execution_num_1    => rob_num_1, 
        	execution_alu_op_1 => rob_alu_op_1,
        	selector_op_0      => arbiter_sel_0,
        	selector_op_1      => arbiter_sel_1		
		);

	-- Multiplexers needed to select the instruction to execute without conflicts
	-- Thread 0
	mux_exe_rs1_address_0 <= id_rs1_address_0 when id_count_instruction_csr_0 = '1' else (others => '0') when arbiter_sel_0 = '1' else rob_alu_x_addr_0;
	mux_exe_rs2_address_0 <= id_rs2_address_0 when id_count_instruction_csr_0 = '1' else (others => '0') when arbiter_sel_0 = '1' else rob_alu_y_addr_0;
	mux_exe_rd_addr_0 	  <= id_rd_address_0  when id_count_instruction_csr_0 = '1' else (others => '0') when arbiter_sel_0 = '1' else (others => '0');
	mux_exe_alu_op_0 	  <= id_alu_op_0 	  when id_count_instruction_csr_0 = '1' else ALU_NOP 		 when arbiter_sel_0 = '1' else rob_alu_op_0;
	mux_exe_alu_x_src_0   <= id_alu_x_src_0   when id_count_instruction_csr_0 = '1' else ALU_SRC_NULL 	 when arbiter_sel_0 = '1' else rob_alu_x_src_0;
	mux_exe_alu_y_src_0   <= id_alu_y_src_0   when id_count_instruction_csr_0 = '1' else ALU_SRC_NULL 	 when arbiter_sel_0 = '1' else rob_alu_y_src_0;
	mux_exe_rd_write_0    <= id_rd_write_0    when id_count_instruction_csr_0 = '1' else '0';
	mux_exe_branch_0   	  <= id_branch_0   	  when id_count_instruction_csr_0 = '1' else BRANCH_NONE 	 when arbiter_sel_0 = '1' else rob_branch_0;
	mux_exe_funct3_0   	  <= id_funct3_0   	  when id_count_instruction_csr_0 = '1' else (others => '0') when arbiter_sel_0 = '1' else rob_funct3_0;
	mux_exe_mem_op_0   	  <= id_mem_op_0   	  when id_count_instruction_csr_0 = '1' else MEMOP_TYPE_NONE when arbiter_sel_0 = '1' else rob_mem_op_0;
	mux_exe_op_num_0   	  <= MAIN_TABLE   	  when id_count_instruction_csr_0 = '1' else MAIN_TABLE 	 when arbiter_sel_0 = '1' else rob_num_0;
	-- Thread 1
	mux_exe_rs1_address_1 <= id_rs1_address_1 when id_count_instruction_csr_1 = '1' else (others => '0') when arbiter_sel_1 = '1' else rob_alu_x_addr_1;
	mux_exe_rs2_address_1 <= id_rs2_address_1 when id_count_instruction_csr_1 = '1' else (others => '0') when arbiter_sel_1 = '1' else rob_alu_y_addr_1;
	mux_exe_rd_addr_1 	  <= id_rd_address_1  when id_count_instruction_csr_1 = '1' else (others => '0') when arbiter_sel_1 = '1' else (others => '0');
	mux_exe_alu_op_1 	  <= id_alu_op_1 	  when id_count_instruction_csr_1 = '1' else ALU_NOP 		 when arbiter_sel_1 = '1' else rob_alu_op_1;
	mux_exe_alu_x_src_1   <= id_alu_x_src_1   when id_count_instruction_csr_1 = '1' else ALU_SRC_NULL 	 when arbiter_sel_1 = '1' else rob_alu_x_src_1;
	mux_exe_alu_y_src_1   <= id_alu_y_src_1   when id_count_instruction_csr_1 = '1' else ALU_SRC_NULL 	 when arbiter_sel_1 = '1' else rob_alu_y_src_1;
	mux_exe_rd_write_1 	  <= id_rd_write_1    when id_count_instruction_csr_1 = '1' else '0';
	mux_exe_branch_1   	  <= id_branch_1   	  when id_count_instruction_csr_1 = '1' else BRANCH_NONE 	 when arbiter_sel_1 = '1' else rob_branch_1;
	mux_exe_funct3_1   	  <= id_funct3_1   	  when id_count_instruction_csr_1 = '1' else (others => '0') when arbiter_sel_1 = '1' else rob_funct3_1;
	mux_exe_mem_op_1   	  <= id_mem_op_1   	  when id_count_instruction_csr_1 = '1' else MEMOP_TYPE_NONE when arbiter_sel_1 = '1' else rob_mem_op_1;
	mux_exe_op_num_1   	  <= MAIN_TABLE   	  when id_count_instruction_csr_1 = '1' else MAIN_TABLE 	 when arbiter_sel_1 = '1' else rob_num_1;

	to_exe_count_instruction_0 <= '1' when (rob_num_0 /= MAIN_TABLE and arbiter_sel_0 = '0') or id_count_instruction_csr_0 = '1' else '0';
	to_exe_count_instruction_1 <= '1' when (rob_num_1 /= THREAD_TABLE and arbiter_sel_0 = '0') or id_count_instruction_csr_1 = '1' else '0';

	------- Execute (EX) Stage -------

	execute: entity work.pp_execute
		generic map(
	    	LENGTH_MAIN => MAIN_TABLE,
			LENGTH_THREAD => THREAD_TABLE
		) port map(
			clk 						=> clk,
			reset 						=> reset,
			stall 						=> stall_ex,
			flush_0						=> flush_ex_0,
			flush_1						=> flush_ex_1,
			-- Interrupt inputs
			irq 						=> irq,
			software_interrupt 			=> software_interrupt,
			timer_interrupt 			=> timer_interrupt,
			-- Data memory output
			dmem_address 				=> ex_dmem_address,
			dmem_data_size	 			=> ex_dmem_data_size,
			dmem_data_out 				=> ex_dmem_data_out,
			dmem_read_req 				=> ex_dmem_read_req,
			dmem_write_req 				=> ex_dmem_write_req,
			-- Thread 0 inputs
			rs1_addr_in_0 				=> mux_exe_rs1_address_0,
			rs2_addr_in_0 				=> mux_exe_rs2_address_0,
			rd_addr_in_0 				=> mux_exe_rd_addr_0,
			rs1_data_in_0 				=> rf_rs1_data_0,
			rs2_data_in_0 				=> rf_rs2_data_0,
			shamt_in_0 					=> rob_shamt_0,
			immediate_in_0 				=> rob_immediate_0,
			pc_in_0 					=> rob_pc_0,
			-- Thread 0 control signals:
			funct3_in_0 				=> mux_exe_funct3_0,
			alu_op_in_0 				=> mux_exe_alu_op_0,
			alu_x_src_in_0 				=> mux_exe_alu_x_src_0,
			alu_y_src_in_0 				=> mux_exe_alu_y_src_0,
			rd_write_in_0 				=> mux_exe_rd_write_0,
			branch_in_0 				=> mux_exe_branch_0,
			op_num_in_0					=> mux_exe_op_num_0, 
			mem_op_in_0					=> mux_exe_mem_op_0, 
			mem_size_in_0				=> rob_mem_size_0,
			count_instruction_in_0 		=> to_exe_count_instruction_0,
			count_instruction_csr_in_0 	=> id_count_instruction_csr_0,
			-- CSR signals Thread 0
			csr_addr_in_0 				=> id_csr_address_0,
			csr_write_in_0 				=> id_csr_write_0,
			csr_value_in_0 				=> csr_read_data,
			csr_use_immediate_in_0 		=> id_csr_use_immediate_0,
			-- Thread 1 inputs
			rs1_addr_in_1 				=> mux_exe_rs1_address_1,
			rs2_addr_in_1 				=> mux_exe_rs2_address_1,
			rd_addr_in_1 				=> mux_exe_rd_addr_1,
			rs1_data_in_1 				=> rf_rs1_data_1,
			rs2_data_in_1 				=> rf_rs2_data_1,
			shamt_in_1 					=> rob_shamt_1,
			immediate_in_1 				=> rob_immediate_1,
			pc_in_1 					=> rob_pc_1,
			-- Thread 1 control signals:
			funct3_in_1 				=> mux_exe_funct3_1,
			alu_op_in_1 				=> mux_exe_alu_op_1,
			alu_x_src_in_1 				=> mux_exe_alu_x_src_1,
			alu_y_src_in_1 				=> mux_exe_alu_y_src_1,
			rd_write_in_1 				=> mux_exe_rd_write_1,
			branch_in_1 				=> mux_exe_branch_1,
			op_num_in_1					=> mux_exe_op_num_1,
			mem_op_in_1					=> mux_exe_mem_op_1,
			mem_size_in_1				=> rob_mem_size_1,
			count_instruction_in_1 		=> to_exe_count_instruction_1,
			count_instruction_csr_in_1 	=> id_count_instruction_csr_1,
			-- CSR signals Thread 1
			csr_addr_in_1 				=> id_csr_address_1,
			csr_write_in_1 				=> id_csr_write_1,
			csr_value_in_1 				=> csr_read_data,
			csr_use_immediate_in_1 		=> id_csr_use_immediate_1,
			-- Thread 0 Output
			rd_addr_out_0 				=> ex_rd_address_0,
			rd_data_out_0 				=> ex_rd_data_0,
			pc_out_0 					=> ex_pc_0,
			-- Thread 0 control signals outputs:
			rd_write_out_0 				=> ex_rd_write_0,
			branch_out_0		 		=> ex_branch_0,
			op_num_out_0				=> ex_num_0,
			count_instruction_out_0 	=> ex_count_instruction_0,
			count_instruction_csr_out_0 => ex_count_instruction_csr_0,
			jump_out_0 					=> ex_jump_taken_0,
			jump_target_out_0 			=> ex_jump_target_0,
			mem_op_out_0 				=> ex_mem_op_0,
			mem_size_out_0 				=> ex_mem_size_0,
			-- Thread 1 Outputs
			rd_addr_out_1 				=> ex_rd_address_1,
			rd_data_out_1 				=> ex_rd_data_1,
			pc_out_1 					=> ex_pc_1,
			-- Thread 1 control signals outputs:
			rd_write_out_1 				=> ex_rd_write_1,
			branch_out_1		 		=> ex_branch_1,
			op_num_out_1				=> ex_num_1,
			count_instruction_out_1 	=> ex_count_instruction_1,
			count_instruction_csr_out_1 => ex_count_instruction_csr_1,
			jump_out_1 					=> ex_jump_taken_1,
			jump_target_out_1 			=> ex_jump_target_1,
			mem_op_out_1 				=> ex_mem_op_1,
			mem_size_out_1 				=> ex_mem_size_1,
			-- CSR signals output
			csr_addr_out 				=> ex_csr_addr,
			csr_write_out 				=> ex_csr_write,
			csr_value_out 				=> ex_csr_value,
			-- Exception control registers
			ie_in 						=> ie,
			ie1_in 						=> ie1,
			mie_in 						=> mie,
			mtvec_in 					=> mtvec,
			mtvec_out					=> exception_target, 
			-- Exeception signals Thread 0
			decode_exception_in_0 		=> id_exception_0,
			decode_exception_cause_in_0 => id_exception_cause_0,
			exception_out_0 			=> exception_taken_0,
			exception_context_out_0 	=> ex_exception_context_0,
			-- Exeception signals Thread 1
			decode_exception_in_1 		=> id_exception_1,
			decode_exception_cause_in_1 => id_exception_cause_1,
			exception_out_1 			=> exception_taken_1,
			exception_context_out_1 	=> ex_exception_context_1,
			-- Forwarding inputs for csr operations
			mem_rd_addr 				=> mem_rd_address_0,
			mem_rd_value 				=> mem_rd_data_0,
			mem_csr_addr 				=> mem_csr_addr,
			mem_csr_data				=> mem_csr_value,
			mem_csr_write 				=> mem_csr_write,
			mem_count_instr_csr			=> mem_count_instruction_csr_0,
			wb_rd_addr 					=> wb_rd_address_0,
			wb_rd_value 				=> wb_rd_data_0,
			wb_csr_addr 				=> wb_csr_address,
			wb_csr_data 				=> wb_csr_data,
			wb_csr_write 				=> wb_csr_write,
			wb_count_instr_csr			=> wb_count_instruction_csr
		);


	dmem_address 	<= dmem_address_p   when (stall_mem = '0' and stall_mem_p = '1') or stall_mem = '1' else ex_dmem_address;
	sg_dmem_address <= dmem_address_p   when (stall_mem = '0' and stall_mem_p = '1') or stall_mem = '1' else ex_dmem_address;
	dmem_data_size 	<= dmem_data_size_p when (stall_mem = '0' and stall_mem_p = '1') or stall_mem = '1' else ex_dmem_data_size;
	dmem_data_out 	<= dmem_data_out_p  when (stall_mem = '0' and stall_mem_p = '1') or stall_mem = '1' else ex_dmem_data_out;
	dmem_read_req 	<= dmem_read_req_p  when (stall_mem = '0' and stall_mem_p = '1') or stall_mem = '1' else ex_dmem_read_req;
	dmem_write_req	<= dmem_write_req_p when (stall_mem = '0' and stall_mem_p = '1') or stall_mem = '1' else ex_dmem_write_req;

	store_previous_stall_mem: process(clk, stall_mem)
	begin
		if rising_edge(clk) then
			stall_mem_p <= stall_mem;
			ack_p <= dmem_read_ack;
		end if;
	end process store_previous_stall_mem;

	store_previous_dmem_address: process(clk, stall_mem)
	begin
		if rising_edge(clk) and stall_mem = '0' then
			dmem_address_p   <= ex_dmem_address;
			dmem_data_size_p <= ex_dmem_data_size;
			dmem_data_out_p  <= ex_dmem_data_out;
			dmem_read_req_p  <= ex_dmem_read_req;
			dmem_write_req_p <= ex_dmem_write_req;
		end if;
	end process store_previous_dmem_address;

	
	------- Memory (MEM) Stage -------
	memory: entity work.pp_memory
		generic map(
	    	LENGTH_MAIN   => MAIN_TABLE,
			LENGTH_THREAD => THREAD_TABLE
		) port map(
			clk 					=> clk,
			reset 					=> reset,
			flush_0					=> flush_mem_0,
			flush_1					=> flush_mem_1,
			stall 					=> stall_mem,
			-- Data memory inputs:
			dmem_data_in 			=> dmem_data_in,
			dmem_read_ack 			=> dmem_read_ack,
			dmem_write_ack 			=> dmem_write_ack,
			-- Thread 0 (Main)
			rd_addr_in_0 			=> ex_rd_address_0,
			rd_addr_out_0 			=> mem_rd_address_0,
			rd_data_in_0 			=> ex_rd_data_0,
			rd_data_out_0 			=> mem_rd_data_0,
			rd_write_in_0 			=> ex_rd_write_0,
			rd_write_out_0 			=> mem_rd_write_0,
			pc_0 					=> ex_pc_0,
			branch_0 				=> ex_branch_0,
			op_num_in_0 			=> ex_num_0,
			op_num_out_0 			=> mem_op_num_0,
			count_instr_in_0  		=> ex_count_instruction_0,
			count_instr_out_0 		=> mem_count_instruction_0,
			count_instr_csr_in_0  	=> ex_count_instruction_csr_0,
			count_instr_csr_out_0 	=> mem_count_instruction_csr_0,
			jump_taken_in_0			=> ex_jump_taken_0, 
			jump_target_in_0		=> ex_jump_target_0,
			jump_taken_out_0		=> mem_jump_taken_0, 
			jump_target_out_0		=> mem_jump_target_0,
			mem_op_in_0 			=> ex_mem_op_0,
			mem_op_out_0 			=> mem_mem_op_0,
			mem_size_in_0 			=> ex_mem_size_0,
			-- Thread 1
			rd_addr_in_1 			=> ex_rd_address_1,
			rd_addr_out_1 			=> mem_rd_address_1,
			rd_data_in_1 			=> ex_rd_data_1,
			rd_data_out_1 			=> mem_rd_data_1,
			rd_write_in_1 			=> ex_rd_write_1,
			rd_write_out_1 			=> mem_rd_write_1,
			pc_1 					=> ex_pc_1,
			branch_1 				=> ex_branch_1,
			op_num_in_1 			=> ex_num_1,
			op_num_out_1 			=> mem_op_num_1,
			count_instr_in_1  		=> ex_count_instruction_1,
			count_instr_out_1 		=> mem_count_instruction_1,
			count_instr_csr_in_1  	=> ex_count_instruction_csr_1,
			count_instr_csr_out_1 	=> mem_count_instruction_csr_1,
			jump_taken_in_1			=> ex_jump_taken_1, 
			jump_target_in_1		=> ex_jump_target_1,
			jump_taken_out_1		=> mem_jump_taken_1, 
			jump_target_out_1		=> mem_jump_target_1,
			mem_op_in_1 			=> ex_mem_op_1,
			mem_op_out_1 			=> mem_mem_op_1,
			mem_size_in_1 			=> ex_mem_size_1,
			-- CSR signals
			csr_addr_in				=> ex_csr_addr,
			csr_addr_out 			=> mem_csr_addr,
			csr_value_in 			=> ex_csr_value,
			csr_value_out 			=> mem_csr_value,
			csr_write_in 			=> ex_csr_write,
			csr_write_out 			=> mem_csr_write,
			-- Exception signals Thread 0
			exception_in_0 			=> exception_taken_0,
			exception_out_0 		=> mem_exception_0, 
			exception_context_in_0 	=> ex_exception_context_0,
			exception_context_out_0 => mem_exception_context_0,
			-- Exception signals Thread 1
			exception_in_1 			=> exception_taken_1,
			exception_out_1 		=> mem_exception_1, 
			exception_context_in_1 	=> ex_exception_context_1,
			exception_context_out_1 => mem_exception_context_1
		);

	------- Writeback (WB) Stage -------
	writeback: entity work.pp_writeback
		generic map(
	    	LENGTH_MAIN => MAIN_TABLE,
	    	LENGTH_THREAD => THREAD_TABLE
		) port map (
			clk 				=> clk,
			reset	 			=> reset,
			flush_0				=> flush_wb_0,
			flush_1				=> flush_wb_1,
			stall 				=> stall_wb,
			-- Data memory
			dmem_addr_in		=> sg_dmem_address,
			dmem_addr_out 		=> wb_dmem_address,
			-- Thread 0
			rd_addr_in_0   		=> mem_rd_address_0,
			rd_addr_out_0  		=> wb_rd_address_0,
			rd_write_in_0  		=> mem_rd_write_0,
			rd_write_out_0 		=> wb_rd_write_0,
			rd_data_in_0  		=> mem_rd_data_0,
			rd_data_out_0 		=> wb_rd_data_0,
			op_num_in_0   		=> mem_op_num_0,
			op_num_out_0  		=> wb_num_0,
			count_instr_in_0 	=> mem_count_instruction_0,
			count_instr_out_0 	=> wb_count_instruction_0,
			count_instr_csr_in_0  => mem_count_instruction_csr_0,
			count_instr_csr_out_0 => wb_count_instruction_csr_0,
			jump_taken_in_0		=> mem_jump_taken_0, 
			jump_target_in_0	=> mem_jump_target_0,
			jump_taken_out_0	=> wb_jump_taken_0, 
			jump_target_out_0	=> wb_jump_target_0,
			-- Thread 1
			rd_addr_in_1   		=> mem_rd_address_1,
			rd_addr_out_1  		=> wb_rd_address_1,
			rd_write_in_1  		=> mem_rd_write_1,
			rd_write_out_1 		=> wb_rd_write_1,
			rd_data_in_1  		=> mem_rd_data_1,
			rd_data_out_1 		=> wb_rd_data_1,
			op_num_in_1   		=> mem_op_num_1,
			op_num_out_1  		=> wb_num_1,
			count_instr_in_1 	=> mem_count_instruction_1,
			count_instr_out_1 	=> wb_count_instruction_1,
			count_instr_csr_in_1  => mem_count_instruction_csr_1,
			count_instr_csr_out_1 => wb_count_instruction_csr_1,
			jump_taken_in_1		=> mem_jump_taken_1, 
			jump_target_in_1	=> mem_jump_target_1,
			jump_taken_out_1	=> wb_jump_taken_1, 
			jump_target_out_1	=> wb_jump_target_1,
			-- CSR instruction
			csr_write_in  		=> mem_csr_write,
			csr_write_out 		=> wb_csr_write,
			csr_data_in  		=> mem_csr_value,
			csr_data_out 		=> wb_csr_data,
			csr_addr_in  		=> mem_csr_addr,
			csr_addr_out 		=> wb_csr_address,

			-- Exception signals Thread 0
			exception_in_0  		=> mem_exception_0,
			exception_out_0 		=> wb_exception_0,
			exception_context_in_0 	=> mem_exception_context_0,
			exception_context_out_0 => wb_exception_context_0,
			-- Exception signals Thread 1
			exception_in_1  		=> mem_exception_1,
			exception_out_1 		=> wb_exception_1,
			exception_context_in_1 	=> mem_exception_context_1,
			exception_context_out_1 => wb_exception_context_1
		);

end architecture behaviour;
 
