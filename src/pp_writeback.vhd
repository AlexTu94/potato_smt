-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_csr.all;

entity pp_writeback is
	generic (
		LENGTH_MAIN : positive := 8;
		LENGTH_THREAD : positive := 8
	); 
	port(
		clk      : in std_logic;
		reset    : in std_logic;
		stall    : in std_logic;
		flush_0  : in std_logic;
		flush_1  : in std_logic;

		-- Data memory
		dmem_addr_in : in std_logic_vector(31 downto 0);
		dmem_addr_out : out std_logic_vector(31 downto 0);

		-- Thread 0
		rd_addr_in_0   : in  register_address;
		rd_addr_out_0  : out register_address;
		rd_write_in_0  : in  std_logic;
		rd_write_out_0 : out std_logic;
		rd_data_in_0   : in  std_logic_vector(31 downto 0);
		rd_data_out_0  : out std_logic_vector(31 downto 0);
		op_num_in_0    	: in integer range 0 to LENGTH_MAIN;
		op_num_out_0   	: out integer range 0 to LENGTH_MAIN;
		jump_taken_in_0  	: in std_logic;
		jump_taken_out_0 	: out std_logic;
		jump_target_in_0 	: in std_logic_vector(31 downto 0);
		jump_target_out_0 : out std_logic_vector(31 downto 0);

		-- Count instruction Thread 0:
		count_instr_in_0  : in std_logic;
		count_instr_out_0 : out std_logic;
		count_instr_csr_in_0  : in std_logic;
		count_instr_csr_out_0 : out std_logic;

		-- Exception signals Thread 0:
		exception_context_in_0  : in  csr_exception_context;
		exception_in_0      : in  std_logic;
		exception_context_out_0 : out csr_exception_context;
		exception_out_0     : out std_logic;

		-- Thread 1
		rd_addr_in_1   : in  register_address;
		rd_addr_out_1  : out register_address;
		rd_write_in_1  : in  std_logic;
		rd_write_out_1 : out std_logic;
		rd_data_in_1   : in  std_logic_vector(31 downto 0);
		rd_data_out_1  : out std_logic_vector(31 downto 0);
		op_num_in_1    	: in integer range 0 to LENGTH_THREAD;
		op_num_out_1   	: out integer range 0 to LENGTH_THREAD;
		jump_taken_in_1  	: in std_logic;
		jump_taken_out_1 	: out std_logic;
		jump_target_in_1 	: in std_logic_vector(31 downto 0);
		jump_target_out_1 : out std_logic_vector(31 downto 0);

		-- Count instruction Thread 1:
		count_instr_in_1  : in std_logic;
		count_instr_out_1 : out std_logic;
		count_instr_csr_in_1  : in std_logic;
		count_instr_csr_out_1 : out std_logic;

		-- Exception signals Thread 1:
		exception_context_in_1  : in  csr_exception_context;
		exception_in_1      : in  std_logic;
		exception_context_out_1 : out csr_exception_context;
		exception_out_1     : out std_logic;

		-- CSR signals:
		csr_write_in  : in  csr_write_mode;
		csr_write_out : out csr_write_mode;
		csr_data_in   : in  std_logic_vector(31 downto 0);
		csr_data_out  : out std_logic_vector(31 downto 0);
		csr_addr_in   : in  csr_address;
		csr_addr_out  : out csr_address
	);
end entity pp_writeback;

architecture behaviour of pp_writeback is
begin

	pipeline_register: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' or flush = '1' then
				rd_write_out_0 <= '0';
				count_instr_out_0 <= '0';
				count_instr_csr_out_0 <= '0';
				op_num_out_0 <= LENGTH_MAIN;
				jump_taken_out_0 <= '0';
				jump_target_out_0 <= (others => '0');
				
				rd_write_out_1 <= '0';
				count_instr_out_1 <= '0';
				count_instr_csr_out_1 <= '0';
				op_num_out_1 <= LENGTH_THREAD;
				jump_taken_out_1 <= '0';
				jump_target_out_1 <= (others => '0');
				
				exception_out_0 <= '0';
				exception_out_1 <= '0';
				dmem_addr_out <= (others => '0');
			elsif stall = '0' then
				-- Thread 0
				if flush_0='0' then
					rd_write_out_0 <= rd_write_in_0;
					count_instr_out_0 <= count_instr_in_0;
					count_instr_csr_out_0 <= count_instr_csr_in_0;
					op_num_out_0 <= op_num_in_0;
					jump_taken_out_0 <= jump_taken_in_0;
					jump_target_out_0 <= jump_target_in_0;
					exception_out_0 <= exception_in_0;
				else
					rd_write_out_0 <= '0';
					count_instr_out_0 <= '0';
					count_instr_csr_out_0 <= '0';
					op_num_out_0 <= LENGTH_MAIN;
					jump_taken_out_0 <= '0';
					jump_target_out_0 <= (others => '0');
					exception_out_0 <= '0';
				end if;
				rd_data_out_0 <= rd_data_in_0;
				rd_addr_out_0 <= rd_addr_in_0;
				exception_context_out_0 <= exception_context_in_0;
				-- Thread 1
				if flush_1='0' then
					rd_write_out_1 <= rd_write_in_1;
					count_instr_out_1 <= count_instr_in_1;
					count_instr_csr_out_1 <= count_instr_csr_in_1;
					op_num_out_1 <= op_num_in_1;
					jump_taken_out_1 <= jump_taken_in_1;
					jump_target_out_1 <= jump_target_in_1;
					exception_out_1 <= exception_in_1;
				else
					rd_write_out_1 <= '0';
					count_instr_out_1 <= '0';
					count_instr_csr_out_1 <= '0';
					op_num_out_1 <= LENGTH_THREAD;
					jump_taken_out_1 <= '0';
					jump_target_out_1 <= (others => '0');
					exception_out_1 <= '0';
				end if;
				rd_data_out_1 <= rd_data_in_1;
				rd_addr_out_1 <= rd_addr_in_1;
				exception_context_out_1 <= exception_context_in_1;
				-- CSR and MEM
				csr_write_out <= csr_write_in;
				csr_data_out <= csr_data_in;
				csr_addr_out <= csr_addr_in;
				dmem_addr_out <= dmem_addr_in;
			end if;
		end if;
	end process pipeline_register;

end architecture behaviour;
