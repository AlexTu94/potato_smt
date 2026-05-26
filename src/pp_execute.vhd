-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;

entity pp_execute is
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
		irq : in std_logic_vector(7 downto 0);
		software_interrupt, timer_interrupt : in std_logic;

		-- Data memory outputs:
		dmem_address   : out std_logic_vector(31 downto 0);
		dmem_data_out  : out std_logic_vector(31 downto 0);
		dmem_data_size : out std_logic_vector( 1 downto 0);
		dmem_read_req  : out std_logic;
		dmem_write_req : out std_logic;

		-- Thread 0 inputs:
		rs1_addr_in_0, rs2_addr_in_0, rd_addr_in_0 : in  register_address;
		rs1_data_in_0, rs2_data_in_0 : in std_logic_vector(31 downto 0);
		shamt_in_0     	: in std_logic_vector(4 downto 0);
		immediate_in_0 	: in std_logic_vector(31 downto 0);
		pc_in_0     	: in  std_logic_vector(31 downto 0);
		-- Thread 0 control signals:
		funct3_in_0 	: in std_logic_vector(2 downto 0);
		alu_op_in_0    	: in  alu_operation;
		alu_x_src_in_0 	: in  alu_operand_source;
		alu_y_src_in_0 	: in  alu_operand_source;
		rd_write_in_0  	: in  std_logic;
		branch_in_0    	: in  branch_type;
		op_num_in_0 	: in  integer range 0 to LENGTH_MAIN;
		mem_op_in_0     : in  memory_operation_type;
		mem_size_in_0   : in  memory_operation_size;
		count_instruction_in_0  : in  std_logic;
		count_instruction_csr_in_0  : in  std_logic;
		
		-- CSR signals Thread 0:
		csr_addr_in_0          : in  csr_address;
		csr_write_in_0         : in  csr_write_mode;
		csr_value_in_0         : in  std_logic_vector(31 downto 0);
		csr_use_immediate_in_0 : in  std_logic; 

		-- Thread 1 inputs:
		rs1_addr_in_1, rs2_addr_in_1, rd_addr_in_1 : in  register_address;
		rs1_data_in_1, rs2_data_in_1 : in std_logic_vector(31 downto 0);
		shamt_in_1     	: in std_logic_vector(4 downto 0);
		immediate_in_1 	: in std_logic_vector(31 downto 0);
		pc_in_1     	: in  std_logic_vector(31 downto 0);
		-- Thread 1 control signals:
		funct3_in_1 	: in std_logic_vector(2 downto 0);
		alu_op_in_1    	: in  alu_operation;
		alu_x_src_in_1 	: in  alu_operand_source;
		alu_y_src_in_1 	: in  alu_operand_source;
		rd_write_in_1  	: in  std_logic;
		branch_in_1    	: in  branch_type;
		op_num_in_1 	: in  integer range 0 to LENGTH_THREAD;
		mem_op_in_1     : in  memory_operation_type;
		mem_size_in_1   : in  memory_operation_size;
		count_instruction_in_1  : in  std_logic;
		count_instruction_csr_in_1  : in  std_logic;

		-- CSR signals Thread 1:
		csr_addr_in_1          : in  csr_address;
		csr_write_in_1         : in  csr_write_mode;
		csr_value_in_1         : in  std_logic_vector(31 downto 0);
		csr_use_immediate_in_1 : in  std_logic; 

		-- Thread 0 outputs:
		rd_addr_out_0 	: out register_address;
		rd_data_out_0   : out std_logic_vector(31 downto 0);
		pc_out_0    	: out std_logic_vector(31 downto 0);
		-- Thread 0 control signals outputs:
		rd_write_out_0 	: out std_logic;
		branch_out_0   	: out branch_type;
		op_num_out_0  	: out integer range 0 to LENGTH_MAIN;
		count_instruction_out_0 : out std_logic;
		count_instruction_csr_out_0 : out std_logic;
		jump_out_0        : out std_logic;
		jump_target_out_0 : out std_logic_vector(31 downto 0);
		mem_op_out_0    : out memory_operation_type;
		mem_size_out_0  : out memory_operation_size;

		-- Thread 1 outputs:
		rd_addr_out_1   : out register_address;
		rd_data_out_1   : out std_logic_vector(31 downto 0);
		pc_out_1    	: out std_logic_vector(31 downto 0);
		-- Thread 1 control signals outputs:
		rd_write_out_1 	: out std_logic;
		branch_out_1   	: out branch_type;
		op_num_out_1  : out integer range 0 to LENGTH_THREAD;
		count_instruction_out_1 : out std_logic;
		count_instruction_csr_out_1 : out std_logic;
		jump_out_1        : out std_logic;
		jump_target_out_1 : out std_logic_vector(31 downto 0);
		mem_op_out_1    : out memory_operation_type;
		mem_size_out_1  : out memory_operation_size;

		-- CSR signals output
		csr_addr_out  : out csr_address;
		csr_write_out : out csr_write_mode;
		csr_value_out : out std_logic_vector(31 downto 0);		

		-- Exception control registers:
		ie_in, ie1_in : in  std_logic;
		mie_in        : in  std_logic_vector(31 downto 0);
		mtvec_in      : in  std_logic_vector(31 downto 0);
		mtvec_out	  : out std_logic_vector(31 downto 0);

		-- Exception signals Thread 0:
		decode_exception_in_0       : in std_logic;
		decode_exception_cause_in_0 : in csr_exception_cause;
		exception_out_0         	: out std_logic;
		exception_context_out_0 	: out csr_exception_context;

		-- Exception signals Thread 1:
		decode_exception_in_1       : in std_logic;
		decode_exception_cause_in_1 : in csr_exception_cause;
		exception_out_1         	: out std_logic;
		exception_context_out_1 	: out csr_exception_context;

		-- Forwarding signals for csr operations:
		-- Inputs to the forwarding logic from the MEM stage:
		mem_rd_addr         : in register_address;
		mem_rd_value        : in std_logic_vector(31 downto 0);
		mem_csr_addr        : in csr_address;
		mem_csr_data		: in std_logic_vector(31 downto 0);
		mem_csr_write       : in csr_write_mode;
		mem_count_instr_csr	: in std_logic;
		-- Inputs to the forwarding logic from the WB stage:
		wb_rd_addr          : in register_address;
		wb_rd_value         : in std_logic_vector(31 downto 0);
		wb_csr_addr         : in csr_address;
		wb_csr_data			: in std_logic_vector(31 downto 0);
		wb_csr_write        : in csr_write_mode;
		wb_count_instr_csr	: in std_logic
	);
end entity pp_execute;

architecture behaviour of pp_execute is 
	signal alu_op_0, alu_op_1 : alu_operation;
	signal alu_x_src_0, alu_y_src_0 : alu_operand_source;
	signal alu_x_src_1, alu_y_src_1 : alu_operand_source;

	signal alu_x_0, alu_y_0, alu_result_0 : std_logic_vector(31 downto 0);
	signal alu_x_1, alu_y_1, alu_result_1 : std_logic_vector(31 downto 0);
	signal prev_alu_result : std_logic_vector(31 downto 0);

	signal rs1_addr_0, rs2_addr_0 : register_address;
	signal rs1_data_0, rs2_data_0 : std_logic_vector(31 downto 0);

	signal rs1_addr_1, rs2_addr_1 : register_address;
	signal rs1_data_1, rs2_data_1 : std_logic_vector(31 downto 0);

	signal mem_op_0, mem_op_1 : memory_operation_type;
	signal mem_size_0, mem_size_1 : memory_operation_size;
	signal prev_stall : std_logic;

	signal pc_0, pc_1        : std_logic_vector(31 downto 0);
	signal immediate_0, immediate_1 : std_logic_vector(31 downto 0);
	signal shamt_0, shamt_1     : std_logic_vector( 4 downto 0);
	signal funct3_0, funct3_1    : std_logic_vector( 2 downto 0);

	signal rs1_forwarded_0, rs2_forwarded_0 : std_logic_vector(31 downto 0);
	signal rs1_forwarded_1, rs2_forwarded_1 : std_logic_vector(31 downto 0);

	signal branch_0, branch_1 : branch_type;
	signal branch_condition_0, branch_condition_1 : std_logic;	
	signal do_jump_0, do_jump_1 : std_logic;
	signal jump_target_0, jump_target_1 : std_logic_vector(31 downto 0);

	signal mie, mtvec : std_logic_vector(31 downto 0);

	signal csr_write_0, csr_write_1 : csr_write_mode;
	signal csr_addr_0, csr_addr_1  : csr_address;
	signal csr_use_immediate_0, csr_use_immediate_1 : std_logic;

	signal csr_value_0, csr_value_1 : std_logic_vector(31 downto 0);
	signal csr_value_alu : std_logic_vector(31 downto 0);
	signal csr_rs1_alu   : std_logic_vector(31 downto 0);
	signal csr_imm_alu   : register_address;
	signal csr_use_imm_alu : std_logic;
	signal csr_write_alu : csr_write_mode;
	signal csr_result_alu : std_logic_vector(31 downto 0);
	
	signal decode_exception_0, decode_exception_1 : std_logic;
	signal decode_exception_cause_0, decode_exception_cause_1 : csr_exception_cause;

	signal exception_taken_0, exception_taken_1 : std_logic;
	signal exception_cause_0, exception_cause_1 : csr_exception_cause;
	signal exception_addr_0, exception_addr_1  : std_logic_vector(31 downto 0);

	signal data_misaligned_0, data_misaligned_1 : std_logic;
	signal instr_misaligned_0, instr_misaligned_1 : std_logic;

	signal irq_asserted : std_logic;
	signal irq_asserted_num : std_logic_vector(3 downto 0);

	-- Shared memory signals:
	signal mem_op_shared   : memory_operation_type;
	signal mem_size_shared : memory_operation_size;
	signal alu_result_shared : std_logic_vector(31 downto 0);
	signal rs2_forwarded_shared : std_logic_vector(31 downto 0);

begin

	-- Register values should not be latched in by a clocked process,
	-- this is already done in the register files.
	rd_data_out_0 <= alu_result_0;
	rd_data_out_1 <= alu_result_1;

	branch_out_0 <= branch_0;
	branch_out_1 <= branch_1;

	mem_op_out_0 <= mem_op_0;
	mem_size_out_0 <= mem_size_0;
	mem_op_out_1 <= mem_op_1;
	mem_size_out_1 <= mem_size_1;

	csr_write_out <= csr_write_0 when csr_write_0 /= CSR_WRITE_NONE else csr_write_1 when csr_write_1 /= CSR_WRITE_NONE;
	csr_addr_out  <= csr_addr_0	 when csr_write_0 /= CSR_WRITE_NONE else csr_addr_1  when csr_write_1 /= CSR_WRITE_NONE;
	csr_value_out <= csr_result_alu; 

	rs2_forwarded_0 <= rs2_data_0;
	rs2_forwarded_1 <= rs2_data_1;

	pc_out_0 <= pc_0;
	pc_out_1 <= pc_1;
	
	exception_out_0 <= exception_taken_0;
	exception_context_out_0 <= (
				ie => ie_in,
				ie1 => ie1_in,
				cause => exception_cause_0,
				badaddr => exception_addr_0);

	exception_out_1 <= exception_taken_1;
	exception_context_out_1 <= (
				ie => ie_in,
				ie1 => ie1_in,
				cause => exception_cause_1,
				badaddr => exception_addr_1);

	do_jump_0 <= (to_std_logic(branch_0 = BRANCH_JUMP or branch_0 = BRANCH_JUMP_INDIRECT)
		or (to_std_logic(branch_0 = BRANCH_CONDITIONAL) and branch_condition_0)
		or to_std_logic(branch_0 = BRANCH_SRET)) and not stall;
	jump_out_0 <= do_jump_0;
	jump_target_out_0 <= jump_target_0;

	do_jump_1 <= (to_std_logic(branch_1 = BRANCH_JUMP or branch_1 = BRANCH_JUMP_INDIRECT)
		or (to_std_logic(branch_1 = BRANCH_CONDITIONAL) and branch_condition_1)
		or to_std_logic(branch_1 = BRANCH_SRET)) and not stall;
	jump_out_1 <= do_jump_1;
	jump_target_out_1 <= jump_target_1;

	mtvec_out <= std_logic_vector(unsigned(mtvec));

	exception_taken_0 <= not stall and (decode_exception_0 or to_std_logic(exception_cause_0 /= CSR_CAUSE_NONE)); 
	exception_taken_1 <= not stall and (decode_exception_1 or to_std_logic(exception_cause_1 /= CSR_CAUSE_NONE)); 

	irq_asserted <= to_std_logic(ie_in = '1' and (irq and mie(31 downto 24)) /= x"00");

	rs1_data_0 <= rs1_data_0 when stall = '1' or prev_stall = '1' else rs1_data_in_0;
	rs2_data_0 <= rs2_data_0 when stall = '1' or prev_stall = '1' else rs2_data_in_0;

	rs1_data_1 <= rs1_data_1 when stall = '1' or prev_stall = '1' else rs1_data_in_1;
	rs2_data_1 <= rs2_data_1 when stall = '1' or prev_stall = '1' else rs2_data_in_1;

	mem_op_shared <= mem_op_0 when mem_op_0 /= MEMOP_TYPE_NONE else mem_op_1;
	mem_size_shared <= mem_size_0 when mem_op_0 /= MEMOP_TYPE_NONE else mem_size_1;
	alu_result_shared <= alu_result_0 when mem_op_0 /= MEMOP_TYPE_NONE else alu_result_1;
	rs2_forwarded_shared <= rs2_forwarded_0 when mem_op_0 /= MEMOP_TYPE_NONE else rs2_forwarded_1;

	dmem_address <= prev_alu_result when (mem_op_shared /= MEMOP_TYPE_NONE and mem_op_shared /= MEMOP_TYPE_INVALID) and (exception_taken_0 = '0' and exception_taken_1 = '0')
		else (others => '0');
	dmem_data_out <= rs2_forwarded_shared;
	dmem_write_req <= '1' when mem_op_shared = MEMOP_TYPE_STORE and (exception_taken_0 = '0' and exception_taken_1 = '0') else '0';
	dmem_read_req <= '1' when memop_is_load(mem_op_shared) and (exception_taken_0 = '0' and exception_taken_1 = '0') else '0';
	prev_alu_result <= alu_result_shared when ((stall = '0' and prev_stall = '0') or (stall='1' and prev_stall='0')) else prev_alu_result;

	process(clk) 
	begin
		if rising_edge(clk) then
			if reset = '1' or flush = '1' then
				prev_stall <= '0';
			else 
				prev_stall <= stall;
			end if;
		end if;
	end process;

	pipeline_register: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then 
				rd_write_out_0 <= '0';
				rd_write_out_1 <= '0';
				branch_0 <= BRANCH_NONE;
				branch_1 <= BRANCH_NONE;
				csr_write_0 <= CSR_WRITE_NONE;
				csr_write_1 <= CSR_WRITE_NONE;
				mem_op_0 <= MEMOP_TYPE_NONE;
				mem_op_1 <= MEMOP_TYPE_NONE;
				decode_exception_0 <= '0';
				decode_exception_1 <= '0';
				count_instruction_out_0 <= '0';
				count_instruction_csr_out_0 <= '0';
				count_instruction_out_1 <= '0';
				count_instruction_csr_out_1 <= '0';
				op_num_out_0 <= LENGTH_MAIN; 
				op_num_out_1 <= LENGTH_THREAD; 
			elsif stall = '1' then
				csr_write_0 <= CSR_WRITE_NONE;
				csr_write_1 <= CSR_WRITE_NONE;
			elsif stall = '0' then

				-- Thread 0 output
				if flush_0 = '0' then
					rd_write_out_0 <= rd_write_in_0;
					branch_0 <= branch_in_0;
					csr_write_0 <= csr_write_in_0;
					mem_op_0 <= mem_op_in_0;
					decode_exception_0 <= decode_exception_in_0;
					count_instruction_out_0 <= count_instruction_in_0;
					count_instruction_csr_out_0 <= count_instruction_csr_in_0;
					op_num_out_0 <= op_num_in_0;  
				else
					rd_write_out_0 <= '0';
					branch_0 <= BRANCH_NONE;
					csr_write_0 <= CSR_WRITE_NONE;
					mem_op_0 <= MEMOP_TYPE_NONE;
					decode_exception_0 <= '0';
					count_instruction_out_0 <= '0';
					count_instruction_csr_out_0 <= '0';
					op_num_out_0 <= LENGTH_MAIN; 
				end if;

				-- Thread 1 output
				if flush_1 = '0' then
					rd_write_out_1 <= rd_write_in_1;
					branch_1 <= branch_in_1;
					csr_write_1 <= csr_write_in_1;
					mem_op_1 <= mem_op_in_1;
					decode_exception_1 <= decode_exception_in_1;
					count_instruction_out_1 <= count_instruction_in_1;
					count_instruction_csr_out_1 <= count_instruction_csr_in_1;
					op_num_out_1 <= op_num_in_1;  
				else
					rd_write_out_1 <= '0';
					branch_1 <= BRANCH_NONE;
					csr_write_1 <= CSR_WRITE_NONE;
					mem_op_1 <= MEMOP_TYPE_NONE;
					decode_exception_1 <= '0';
					count_instruction_out_1 <= '0';
					count_instruction_csr_out_1 <= '0';
					op_num_out_1 <= LENGTH_MAIN; 
				end if;

				pc_0 <= pc_in_0;
				pc_1 <= pc_in_1;
				
				-- Register signals Thread 0:
				rd_addr_out_0 <= rd_addr_in_0;
				rs1_addr_0 <= rs1_addr_in_0;
				rs2_addr_0 <= rs2_addr_in_0;

				-- Register signals Thread 1:
				rd_addr_out_1 <= rd_addr_in_1;
				rs1_addr_1 <= rs1_addr_in_1;
				rs2_addr_1 <= rs2_addr_in_1;

				-- ALU signals Thread 0:
				alu_op_0 <= alu_op_in_0;
				alu_x_src_0 <= alu_x_src_in_0;
				alu_y_src_0 <= alu_y_src_in_0;

				-- ALU signals Thread 1:
				alu_op_1 <= alu_op_in_1;
				alu_x_src_1 <= alu_x_src_in_1;
				alu_y_src_1 <= alu_y_src_in_1;

				-- Control signals:
				mem_size_0 <= mem_size_in_0;
				mem_size_1 <= mem_size_in_1;

				-- Constant values Thread 0:
				immediate_0 <= immediate_in_0;
				shamt_0 <= shamt_in_0;
				funct3_0 <= funct3_in_0;

				-- Constant values Thread 1:
				immediate_1 <= immediate_in_1;
				shamt_1 <= shamt_in_1;
				funct3_1 <= funct3_in_1;

				-- CSR signals Thread 0:
				csr_addr_0 <= csr_addr_in_0;
				csr_use_immediate_0 <= csr_use_immediate_in_0;

				-- CSR signals Thread 1:
				csr_addr_1 <= csr_addr_in_1;
				csr_use_immediate_1 <= csr_use_immediate_in_1;

				-- Exception vector base:
				mtvec <= mtvec_in;
				mie <= mie_in;

				-- Instruction decoder exceptions:
				decode_exception_cause_0 <= decode_exception_cause_in_0;
				decode_exception_cause_1 <= decode_exception_cause_in_1;
			end if;
		end if;
	end process pipeline_register;

	set_data_size: process(mem_size_shared)
	begin
		case mem_size_shared is
			when MEMOP_SIZE_BYTE =>
				dmem_data_size <= b"01";
			when MEMOP_SIZE_HALFWORD =>
				dmem_data_size <= b"10";
			when MEMOP_SIZE_WORD =>
				dmem_data_size <= b"00";
			when others =>
				dmem_data_size <= b"11";
		end case;
	end process set_data_size;

	get_irq_num: process(irq, mie)
		variable temp : std_logic_vector(3 downto 0);
	begin
		temp := (others => '0');
		for i in 0 to 7 loop
			if irq(i) = '1' and mie(24 + i) = '1' then
				temp := std_logic_vector(to_unsigned(i, temp'length));
				exit;
			end if;
		end loop;
		irq_asserted_num <= temp;
	end process get_irq_num;

	-- THIS PART SHOULD BE ADAPTED WHEN MEM OPERATIONS IMPLEMENTED
	data_misalign_check: process(mem_size_0, mem_size_1, alu_result_0, alu_result_1)
	begin
		-- Thread 0
		case mem_size_0 is
			when MEMOP_SIZE_HALFWORD =>
				if alu_result_0(0) /= '0' then
					data_misaligned_0 <= '1';
				else
					data_misaligned_0 <= '0';
				end if;
			when MEMOP_SIZE_WORD =>
				if alu_result_0(1 downto 0) /= b"00" then
					data_misaligned_0 <= '1';
				else
					data_misaligned_0 <= '0';
				end if;
			when others =>
				data_misaligned_0 <= '0';
		end case;
		-- Thread 1
		case mem_size_1 is
			when MEMOP_SIZE_HALFWORD =>
				if alu_result_1(0) /= '0' then
					data_misaligned_1 <= '1';
				else
					data_misaligned_1 <= '0';
				end if;
			when MEMOP_SIZE_WORD =>
				if alu_result_1(1 downto 0) /= b"00" then
					data_misaligned_1 <= '1';
				else
					data_misaligned_1 <= '0';
				end if;
			when others =>
				data_misaligned_1 <= '0';
		end case;
	end process data_misalign_check;

	instr_misalign_check: process(jump_target_0, branch_0, branch_condition_0, do_jump_0,
                                  jump_target_1, branch_1, branch_condition_1, do_jump_1)
	begin
		if jump_target_0(1 downto 0) /= b"00" and do_jump_0 = '1' then
			instr_misaligned_0 <= '1';
		else
			instr_misaligned_0 <= '0';
		end if;
		if jump_target_1(1 downto 0) /= b"00" and do_jump_1 = '1' then
			instr_misaligned_1 <= '1';
		else
			instr_misaligned_1 <= '0';
		end if;
	end process instr_misalign_check;

	find_exception_cause_0: process(decode_exception_0, decode_exception_cause_0, mem_op_0,
		data_misaligned_0, instr_misaligned_0, irq_asserted, irq_asserted_num, mie,
		software_interrupt, timer_interrupt, ie_in)
	begin
		if irq_asserted = '1' then
			exception_cause_0 <= std_logic_vector(unsigned(CSR_CAUSE_IRQ_BASE) + unsigned(irq_asserted_num));
		elsif software_interrupt = '1' and mie(CSR_MIE_MSIE) = '1' and ie_in = '1' then
			exception_cause_0 <= CSR_CAUSE_SOFTWARE_INT;
		elsif timer_interrupt = '1' and mie(CSR_MIE_MTIE) = '1' and ie_in = '1' then
			exception_cause_0 <= CSR_CAUSE_TIMER_INT;
		elsif decode_exception_0 = '1' then
			exception_cause_0 <= decode_exception_cause_0;
		elsif mem_op_0 = MEMOP_TYPE_INVALID then
			exception_cause_0 <= CSR_CAUSE_INVALID_INSTR;
		elsif instr_misaligned_0 = '1' then
			exception_cause_0 <= CSR_CAUSE_INSTR_MISALIGN;
		elsif data_misaligned_0 = '1' and mem_op_0 = MEMOP_TYPE_STORE then
			exception_cause_0 <= CSR_CAUSE_STORE_MISALIGN;
		elsif data_misaligned_0 = '1' and memop_is_load(mem_op_0) then
			exception_cause_0 <= CSR_CAUSE_LOAD_MISALIGN;
		else
			exception_cause_0 <= CSR_CAUSE_NONE;
		end if;
	end process find_exception_cause_0;

	find_exception_cause_1: process(decode_exception_1, decode_exception_cause_1, mem_op_1, 
                                    data_misaligned_1, instr_misaligned_1)
	begin
		if decode_exception_1 = '1' then
			exception_cause_1 <= decode_exception_cause_1;
		elsif mem_op_1 = MEMOP_TYPE_INVALID then
			exception_cause_1 <= CSR_CAUSE_INVALID_INSTR;
		elsif instr_misaligned_1 = '1' then
			exception_cause_1 <= CSR_CAUSE_INSTR_MISALIGN;
		elsif data_misaligned_1 = '1' and mem_op_1 = MEMOP_TYPE_STORE then
			exception_cause_1 <= CSR_CAUSE_STORE_MISALIGN;
		elsif data_misaligned_1 = '1' and memop_is_load(mem_op_1) then
			exception_cause_1 <= CSR_CAUSE_LOAD_MISALIGN;
		else
			exception_cause_1 <= CSR_CAUSE_NONE;
		end if;
	end process find_exception_cause_1;

	find_exception_addr_0: process(instr_misaligned_0, data_misaligned_0, jump_target_0, alu_result_0)
	begin
		if instr_misaligned_0 = '1' then
			exception_addr_0 <= jump_target_0;
		elsif data_misaligned_0 = '1' then
			exception_addr_0 <= alu_result_0;
		else
			exception_addr_0 <= (others => '0');
		end if;
	end process find_exception_addr_0;

	find_exception_addr_1: process(instr_misaligned_1, data_misaligned_1, jump_target_1, alu_result_1)
	begin
		if instr_misaligned_1 = '1' then
			exception_addr_1 <= jump_target_1;
		elsif data_misaligned_1 = '1' then
			exception_addr_1 <= alu_result_1;
		else
			exception_addr_1 <= (others => '0');
		end if;
	end process find_exception_addr_1;

	calc_jump_tgt_0: process(branch_0, pc_0, rs1_forwarded_0, immediate_0, csr_value_0)
	begin
		case branch_0 is
			when BRANCH_JUMP | BRANCH_CONDITIONAL =>
				jump_target_0 <= std_logic_vector(unsigned(pc_0) + unsigned(immediate_0));
			when BRANCH_JUMP_INDIRECT =>
				jump_target_0 <= std_logic_vector(unsigned(rs1_forwarded_0) + unsigned(immediate_0));
			when BRANCH_SRET =>
				jump_target_0 <= csr_value_0;
			when others =>
				jump_target_0 <= (others => '0');
		end case;
	end process calc_jump_tgt_0;

	calc_jump_tgt_1: process(branch_1, pc_1, rs1_forwarded_1, immediate_1, csr_value_1)
	begin
		case branch_1 is
			when BRANCH_JUMP | BRANCH_CONDITIONAL =>
				jump_target_1 <= std_logic_vector(unsigned(pc_1) + unsigned(immediate_1));
			when BRANCH_JUMP_INDIRECT =>
				jump_target_1 <= std_logic_vector(unsigned(rs1_forwarded_1) + unsigned(immediate_1));
			when BRANCH_SRET =>
				jump_target_1 <= csr_value_1;
			when others =>
				jump_target_1 <= (others => '0');
		end case;
	end process calc_jump_tgt_1;

	alu_x_0_mux: entity work.pp_alu_mux
		port map(
			source => alu_x_src_0,
			register_value => rs1_forwarded_0,
			immediate_value => immediate_0,
			shamt_value => shamt_0,
			pc_value => pc_0,
			csr_value => csr_value_0,
			output => alu_x_0
		);

	alu_y_0_mux: entity work.pp_alu_mux
		port map(
			source => alu_y_src_0,
			register_value => rs2_forwarded_0,
			immediate_value => immediate_0,
			shamt_value => shamt_0,
			pc_value => pc_0,
			csr_value => csr_value_0,
			output => alu_y_0
		);

	alu_x_1_mux: entity work.pp_alu_mux
		port map(
			source => alu_x_src_1,
			register_value => rs1_forwarded_1,
			immediate_value => immediate_1,
			shamt_value => shamt_1,
			pc_value => pc_1,
			csr_value => csr_value_1,
			output => alu_x_1
		);

	alu_y_1_mux: entity work.pp_alu_mux
		port map(
			source => alu_y_src_1,
			register_value => rs2_forwarded_1,
			immediate_value => immediate_1,
			shamt_value => shamt_1,
			pc_value => pc_1,
			csr_value => csr_value_1,
			output => alu_y_1
		);

	rs1_csr_forward_0: process(csr_write_0, rs1_addr_0, rs1_data_0, 
		mem_csr_write, mem_rd_addr, mem_count_instr_csr, mem_rd_value,
		wb_csr_write, wb_rd_addr, wb_count_instr_csr, wb_rd_value)
	begin
		if csr_write_0 /= CSR_WRITE_NONE and mem_csr_write /= CSR_WRITE_NONE and mem_rd_addr = rs1_addr_0 and mem_count_instr_csr = '1' then 
			rs1_forwarded_0 <= mem_rd_value;
		elsif csr_write_0 /= CSR_WRITE_NONE and wb_csr_write /= CSR_WRITE_NONE and wb_rd_addr = rs1_addr_0 and wb_count_instr_csr = '1' then 
			rs1_forwarded_0 <= wb_rd_value;
		else
			rs1_forwarded_0 <= rs1_data_0;
		end if;
	end process rs1_csr_forward_0;

	rs1_csr_forward_1: process(csr_write_1, rs1_addr_1, rs1_data_1, 
		mem_csr_write, mem_rd_addr, mem_count_instr_csr, mem_rd_value,
		wb_csr_write, wb_rd_addr, wb_count_instr_csr, wb_rd_value)
	begin
		if csr_write_1 /= CSR_WRITE_NONE and mem_csr_write /= CSR_WRITE_NONE and mem_rd_addr = rs1_addr_1 and mem_count_instr_csr = '1' then 
			rs1_forwarded_1 <= mem_rd_value;
		elsif csr_write_1 /= CSR_WRITE_NONE and wb_csr_write /= CSR_WRITE_NONE and wb_rd_addr = rs1_addr_1 and wb_count_instr_csr = '1' then 
			rs1_forwarded_1 <= wb_rd_value;
		else
			rs1_forwarded_1 <= rs1_data_1;
		end if;
	end process rs1_csr_forward_1;
	
	csr_value_forward_0: process(csr_write_0, csr_addr_0, csr_value_in_0, 
		mem_csr_write, mem_csr_addr, mem_count_instr_csr, mem_csr_data,
		wb_csr_write, wb_csr_addr, wb_count_instr_csr, wb_csr_data)
	begin
		if csr_write_0 /= CSR_WRITE_NONE and mem_csr_write /= CSR_WRITE_NONE and mem_csr_addr = csr_addr_0 and mem_count_instr_csr = '1' then 
			csr_value_0 <= mem_csr_data;
		elsif csr_write_0 /= CSR_WRITE_NONE and wb_csr_write /= CSR_WRITE_NONE and wb_csr_addr = csr_addr_0 and wb_count_instr_csr = '1' then 
			csr_value_0 <= wb_csr_data;
		else
			csr_value_0 <= csr_value_in_0;
		end if;
	end process csr_value_forward_0;

	csr_value_forward_1: process(csr_write_1, csr_addr_1, csr_value_in_1, 
		mem_csr_write, mem_csr_addr, mem_count_instr_csr, mem_csr_data,
		wb_csr_write, wb_csr_addr, wb_count_instr_csr, wb_csr_data)
	begin
		if csr_write_1 /= CSR_WRITE_NONE and mem_csr_write /= CSR_WRITE_NONE and mem_csr_addr = csr_addr_1 and mem_count_instr_csr = '1' then 
			csr_value_1 <= mem_csr_data;
		elsif csr_write_1 /= CSR_WRITE_NONE and wb_csr_write /= CSR_WRITE_NONE and wb_csr_addr = csr_addr_1 and wb_count_instr_csr = '1' then 
			csr_value_1 <= wb_csr_data;
		else
			csr_value_1 <= csr_value_in_1;
		end if;
	end process csr_value_forward_1;

	-- Mux CSR ALU inputs based on which thread is executing a CSR instruction
	csr_value_alu   <= csr_value_0 			when csr_write_0 /= CSR_WRITE_NONE else csr_value_1			when csr_write_1 /= CSR_WRITE_NONE;
	csr_rs1_alu     <= rs1_forwarded_0		when csr_write_0 /= CSR_WRITE_NONE else rs1_forwarded_1		when csr_write_1 /= CSR_WRITE_NONE;
	csr_imm_alu     <= rs1_addr_0 			when csr_write_0 /= CSR_WRITE_NONE else rs1_addr_1  		when csr_write_1 /= CSR_WRITE_NONE;
	csr_use_imm_alu <= csr_use_immediate_0 	when csr_write_0 /= CSR_WRITE_NONE else csr_use_immediate_1	when csr_write_1 /= CSR_WRITE_NONE;
	csr_write_alu   <= csr_write_0 			when csr_write_0 /= CSR_WRITE_NONE else csr_write_1			when csr_write_1 /= CSR_WRITE_NONE;

	csr_alu_instance: entity work.pp_csr_alu
		port map(
			x => csr_value_alu,	
			y => csr_rs1_alu,	
			result => csr_result_alu,	
			immediate => csr_imm_alu,	
			use_immediate => csr_use_imm_alu, 
			write_mode => csr_write_alu	
		);


end architecture behaviour;
