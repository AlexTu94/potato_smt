gtkwave::/Edit/Highlight_All
gtkwave::/Edit/Delete
gtkwave::/Edit/UnHighlight_All


set sg_generic [list]
lappend sg_generic "tb_processor.clk"
lappend sg_generic "tb_processor.reset"
gtkwave::addSignalsFromList $sg_generic
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Stalls"
set sg_stalls [list]
lappend sg_stalls "tb_processor.uut.stall_if_0"
lappend sg_stalls "tb_processor.uut.stall_id_0"
lappend sg_stalls "tb_processor.uut.stall_rob_0"
lappend sg_stalls "tb_processor.uut.stall_if_1"
lappend sg_stalls "tb_processor.uut.stall_id_1"
lappend sg_stalls "tb_processor.uut.stall_rob_1"
lappend sg_stalls "tb_processor.uut.stall_csr"
lappend sg_stalls "tb_processor.uut.stall_ex"
lappend sg_stalls "tb_processor.uut.stall_mem"
lappend sg_stalls "tb_processor.uut.stall_wb"
gtkwave::addSignalsFromList $sg_stalls 
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Fetch_Out_0"
set sg_fetch_0 [list]
lappend sg_fetch_0 "tb_processor.uut.fetch_0.imem_address"
lappend sg_fetch_0 "tb_processor.uut.fetch_0.imem_req"
lappend sg_fetch_0 "tb_processor.uut.fetch_0.instruction_data"
lappend sg_fetch_0 "tb_processor.uut.fetch_0.instruction_address"
lappend sg_fetch_0 "tb_processor.uut.fetch_0.instruction_ready"
gtkwave::addSignalsFromList $sg_fetch_0
gtkwave::/Edit/Data_Format/Hex
gtkwave::/Edit/UnHighlight_All

gtkwave::addCommentTracesFromList "Fetch_Out_1"
set sg_fetch_1 [list]
lappend sg_fetch_1 "tb_processor.uut.fetch_1.imem_address"
lappend sg_fetch_1 "tb_processor.uut.fetch_1.imem_req"
lappend sg_fetch_1 "tb_processor.uut.fetch_1.instruction_data"
lappend sg_fetch_1 "tb_processor.uut.fetch_1.instruction_address"
lappend sg_fetch_1 "tb_processor.uut.fetch_1.instruction_ready"
gtkwave::addSignalsFromList $sg_fetch_1
gtkwave::/Edit/Data_Format/Hex
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Decoder_0_OUT" 
set sg_dec_out_0 [list]
lappend sg_dec_out_0 "tb_processor.uut.decode_0.pc"
lappend sg_dec_out_0 "tb_processor.uut.decode_0.rd_addr"
lappend sg_dec_out_0 "tb_processor.uut.decode_0.rs1_addr"
lappend sg_dec_out_0 "tb_processor.uut.decode_0.rs2_addr"
lappend sg_dec_out_0 "tb_processor.uut.decode_0.rd_write"
lappend sg_dec_out_0 "tb_processor.uut.decode_0.alu_op"
lappend sg_dec_out_0 "tb_processor.uut.decode_0.mem_op"
lappend sg_dec_out_0 "tb_processor.uut.decode_0.branch"
gtkwave::addSignalsFromList $sg_dec_out_0
gtkwave::/Edit/Data_Format/Hex
gtkwave::/Edit/UnHighlight_All

gtkwave::addCommentTracesFromList "Decoder_1_OUT" 
set sg_dec_out_1 [list]
lappend sg_dec_out_1 "tb_processor.uut.decode_1.pc"
lappend sg_dec_out_1 "tb_processor.uut.decode_1.rd_addr"
lappend sg_dec_out_1 "tb_processor.uut.decode_1.rs1_addr"
lappend sg_dec_out_1 "tb_processor.uut.decode_1.rs2_addr"
lappend sg_dec_out_1 "tb_processor.uut.decode_1.rd_write"
lappend sg_dec_out_1 "tb_processor.uut.decode_1.alu_op"
lappend sg_dec_out_1 "tb_processor.uut.decode_1.mem_op"
lappend sg_dec_out_1 "tb_processor.uut.decode_1.branch"
gtkwave::addSignalsFromList $sg_dec_out_1
gtkwave::/Edit/Data_Format/Hex
gtkwave::/Edit/UnHighlight_All



gtkwave::addCommentTracesFromList "CSR_In"
set sg_csr [list]
lappend sg_csr "tb_processor.uut.csr_unit.count_instruction"
lappend sg_csr "tb_processor.uut.csr_unit.count_instruction_csr"
lappend sg_csr "tb_processor.uut.csr_unit.read_address"
lappend sg_csr "tb_processor.uut.csr_unit.write_address"
lappend sg_csr "tb_processor.uut.csr_unit.write_data_in"
lappend sg_csr "tb_processor.uut.csr_unit.write_mode"
lappend sg_csr "tb_processor.uut.csr_unit.exception_context"
lappend sg_csr "tb_processor.uut.csr_unit.exception_context_write"
gtkwave::addSignalsFromList $sg_csr
gtkwave::/Edit/UnHighlight_All


#gtkwave::addCommentTracesFromList "CSR_Out"
#set sg_csr [list]
#lappend sg_csr "tb_processor.uut.csr_unit.test_context_out"
#lappend sg_csr "tb_processor.uut.csr_unit.read_data_out"
#lappend sg_csr "tb_processor.uut.csr_unit.software_interrupt_out"
#lappend sg_csr "tb_processor.uut.csr_unit.timer_interrupt_out"
#lappend sg_csr "tb_processor.uut.csr_unit.mie_out"
#lappend sg_csr "tb_processor.uut.csr_unit.mtvec_out"
#lappend sg_csr "tb_processor.uut.csr_unit.ie_out"
#lappend sg_csr "tb_processor.uut.csr_unit.ie1_out"
#gtkwave::addSignalsFromList $sg_csr
#gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "ROB_0_Generic"
set sg_rob_0_generic [list]
lappend sg_rob_0_generic "tb_processor.uut.reorder_buffer_0.stall"
lappend sg_rob_0_generic "tb_processor.uut.reorder_buffer_0.count_instruction"
lappend sg_rob_0_generic "tb_processor.uut.reorder_buffer_0.fetch_enable"
lappend sg_rob_0_generic "tb_processor.uut.reorder_buffer_0.rob_empty"
lappend sg_rob_0_generic "tb_processor.uut.reorder_buffer_0.pntr_start"
lappend sg_rob_0_generic "tb_processor.uut.reorder_buffer_0.pntr_exec"
lappend sg_rob_0_generic "tb_processor.uut.reorder_buffer_0.pntr_end"
gtkwave::addSignalsFromList $sg_rob_0_generic
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All

gtkwave::addCommentTracesFromList "ROB_1_Generic"
set sg_rob_1_generic [list]
lappend sg_rob_1_generic "tb_processor.uut.reorder_buffer_1.stall"
lappend sg_rob_1_generic "tb_processor.uut.reorder_buffer_1.count_instruction"
lappend sg_rob_1_generic "tb_processor.uut.reorder_buffer_1.fetch_enable"
lappend sg_rob_1_generic "tb_processor.uut.reorder_buffer_1.rob_empty"
lappend sg_rob_1_generic "tb_processor.uut.reorder_buffer_1.pntr_start"
lappend sg_rob_1_generic "tb_processor.uut.reorder_buffer_1.pntr_exec"
lappend sg_rob_1_generic "tb_processor.uut.reorder_buffer_1.pntr_end"
gtkwave::addSignalsFromList $sg_rob_1_generic
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All

gtkwave::addCommentTracesFromList "Arbiter"
set sg_arbiter [list]
lappend sg_arbiter "tb_processor.uut.arbiter.execution_num_0"
lappend sg_arbiter "tb_processor.uut.arbiter.execution_alu_op_0"
lappend sg_arbiter "tb_processor.uut.arbiter.execution_num_1"
lappend sg_arbiter "tb_processor.uut.arbiter.execution_alu_op_1"
lappend sg_arbiter "tb_processor.uut.arbiter.selector_op_0"
lappend sg_arbiter "tb_processor.uut.arbiter.selector_op_1"
lappend sg_arbiter "tb_processor.uut.arbiter.priority_toggle"
gtkwave::addSignalsFromList $sg_arbiter
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All

gtkwave::addCommentTracesFromList "Execute_In"
set sg_execute [list]
lappend sg_execute "tb_processor.uut.execute.stall"
lappend sg_execute "tb_processor.uut.execute.flush"
lappend sg_execute "tb_processor.uut.execute.rob_op_num_in_0"
lappend sg_execute "tb_processor.uut.execute.alu_op_in_0"
lappend sg_execute "tb_processor.uut.execute.rd_write_in_0"
lappend sg_execute "tb_processor.uut.execute.rob_op_num_in_1"
lappend sg_execute "tb_processor.uut.execute.alu_op_in_1"
lappend sg_execute "tb_processor.uut.execute.rd_write_in_1"
gtkwave::addSignalsFromList $sg_execute
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Execute_Out"
set sg_execute_out [list]
lappend sg_execute_out "tb_processor.uut.execute.rd_addr_out_0"
lappend sg_execute_out "tb_processor.uut.execute.rd_data_out_0"
lappend sg_execute_out "tb_processor.uut.execute.rd_write_out_0"
lappend sg_execute_out "tb_processor.uut.execute.exe_op_num_out_0"
lappend sg_execute_out "tb_processor.uut.execute.count_instruction_out_0"
gtkwave::addSignalsFromList $sg_execute_out
gtkwave::/Edit/Data_Format/Hex
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Reg_File_0"
set sg_reg_file_0 [list]
lappend sg_reg_file_0 "tb_processor.uut.regfile_0.rd_write"
lappend sg_reg_file_0 "tb_processor.uut.regfile_0.rd_addr"
lappend sg_reg_file_0 "tb_processor.uut.regfile_0.rd_data"
lappend sg_reg_file_0 "tb_processor.uut.regfile_0.rs1_addr"
lappend sg_reg_file_0 "tb_processor.uut.regfile_0.rs1_data"
lappend sg_reg_file_0 "tb_processor.uut.regfile_0.rs2_addr"
lappend sg_reg_file_0 "tb_processor.uut.regfile_0.rs2_data"
gtkwave::addSignalsFromList $sg_reg_file_0
gtkwave::/Edit/Data_Format/Hex
gtkwave::/Edit/UnHighlight_All

gtkwave::addCommentTracesFromList "Reg_File_1"
set sg_reg_file_1 [list]
lappend sg_reg_file_1 "tb_processor.uut.regfile_1.rd_write"
lappend sg_reg_file_1 "tb_processor.uut.regfile_1.rd_addr"
lappend sg_reg_file_1 "tb_processor.uut.regfile_1.rd_data"
lappend sg_reg_file_1 "tb_processor.uut.regfile_1.rs1_addr"
lappend sg_reg_file_1 "tb_processor.uut.regfile_1.rs1_data"
lappend sg_reg_file_1 "tb_processor.uut.regfile_1.rs2_addr"
lappend sg_reg_file_1 "tb_processor.uut.regfile_1.rs2_data"
gtkwave::addSignalsFromList $sg_reg_file_1
gtkwave::/Edit/Data_Format/Hex
gtkwave::/Edit/UnHighlight_All



#gtkwave::addCommentTracesFromList "Execute_forwarding"
#set sg_execute [list]
#set sg_execute_dec [list]
#lappend sg_execute "tb_processor.uut.execute.csr_write"
#lappend sg_execute "tb_processor.uut.execute.csr_addr"
#lappend sg_execute "tb_processor.uut.execute.csr_value_in"
#lappend sg_execute "tb_processor.uut.execute.mem_count_instr"
#lappend sg_execute "tb_processor.uut.execute.mem_csr_write"
#lappend sg_execute "tb_processor.uut.execute.mem_csr_addr"
#lappend sg_execute "tb_processor.uut.execute.mem_csr_data"
#lappend sg_execute "tb_processor.uut.execute.wb_count_instr"
#lappend sg_execute "tb_processor.uut.execute.wb_csr_write"
#lappend sg_execute "tb_processor.uut.execute.wb_csr_addr"
#lappend sg_execute "tb_processor.uut.execute.wb_csr_data"
#lappend sg_execute "tb_processor.uut.execute.csr_value"
#gtkwave::addSignalsFromList $sg_execute
#gtkwave::highlightSignalsFromList $sg_execute
#gtkwave::/Edit/UnHighlight_All
#gtkwave::addSignalsFromList $sg_execute_dec
#gtkwave::/Edit/Data_Format/Decimal
#gtkwave::highlightSignalsFromList $sg_execute_dec
#gtkwave::/Edit/UnHighlight_All

#gtkwave::addCommentTracesFromList "ALU"
#set sg_alu_dec [list]
#lappend sg_alu_dec "tb_processor.uut.execute.alu_instance.operation"
#lappend sg_alu_dec "tb_processor.uut.execute.alu_instance.x"
#lappend sg_alu_dec "tb_processor.uut.execute.alu_instance.y"
#lappend sg_alu_dec "tb_processor.uut.execute.alu_instance.result"
#gtkwave::addSignalsFromList $sg_alu_dec
#gtkwave::/Edit/Data_Format/Decimal
#gtkwave::highlightSignalsFromList $sg_alu_dec
#gtkwave::/Edit/UnHighlight_All

#gtkwave::addCommentTracesFromList "CSR_ALU"
#set sg_csr_alu_dec [list]
#lappend sg_csr_alu_dec "tb_processor.uut.execute.csr_alu_instance.x"
#lappend sg_csr_alu_dec "tb_processor.uut.execute.csr_alu_instance.y"
#lappend sg_csr_alu_dec "tb_processor.uut.execute.csr_alu_instance.result"
#lappend sg_csr_alu_dec "tb_processor.uut.execute.csr_alu_instance.immediate"
#lappend sg_csr_alu_dec "tb_processor.uut.execute.csr_alu_instance.use_immediate"
#lappend sg_csr_alu_dec "tb_processor.uut.execute.csr_alu_instance.write_mode"
#gtkwave::addSignalsFromList $sg_csr_alu_dec
#gtkwave::/Edit/Data_Format/Decimal
#gtkwave::highlightSignalsFromList $sg_csr_alu_dec
#gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Execute_Out"
set sg_execute [list]
set sg_execute_dec [list]
lappend sg_execute "tb_processor.uut.execute.count_instruction_out"
lappend sg_execute "tb_processor.uut.execute.exe_op_num_out"
lappend sg_execute "tb_processor.uut.execute.alu_op_out"
lappend sg_execute "tb_processor.uut.execute.rd_write_out"
lappend sg_execute "tb_processor.uut.execute.rd_addr_out"
lappend sg_execute "tb_processor.uut.execute.rd_data_out"
lappend sg_execute "tb_processor.uut.execute.mem_op_out"
lappend sg_execute "tb_processor.uut.execute.mem_size_out"
lappend sg_execute "tb_processor.uut.execute.dmem_address"
lappend sg_execute "tb_processor.uut.execute.dmem_data_out"
lappend sg_execute "tb_processor.uut.execute.dmem_data_size"
lappend sg_execute "tb_processor.uut.execute.dmem_read_req"
lappend sg_execute "tb_processor.uut.execute.dmem_write_req"
lappend sg_execute "tb_processor.uut.execute.prev_dmem_address"
lappend sg_execute "tb_processor.uut.execute.branch_out"
lappend sg_execute "tb_processor.uut.execute.jump_out"
lappend sg_execute "tb_processor.uut.execute.jump_target_out"
lappend sg_execute "tb_processor.uut.execute.pc_out"
#lappend sg_execute "tb_processor.uut.execute.csr_addr_out"
#lappend sg_execute "tb_processor.uut.execute.csr_write_out"
#lappend sg_execute "tb_processor.uut.execute.csr_value_out"
#lappend sg_execute "tb_processor.uut.execute.mtvec_out"
#lappend sg_execute "tb_processor.uut.execute.exception_out"
#lappend sg_execute "tb_processor.uut.execute.exception_context_out"
#lappend sg_execute "tb_processor.uut.execute.hazard_detected"
gtkwave::addSignalsFromList $sg_execute
gtkwave::highlightSignalsFromList $sg_execute
gtkwave::/Edit/UnHighlight_All
gtkwave::addSignalsFromList $sg_execute_dec
gtkwave::/Edit/Data_Format/Decimal
gtkwave::highlightSignalsFromList $sg_execute_dec
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Memory_In"
set sg_mem_stage [list]
set sg_mem_stage_dec [list]
lappend sg_mem_stage "tb_processor.uut.memory.stall"
lappend sg_mem_stage "tb_processor.uut.memory.count_instr_in"
lappend sg_mem_stage "tb_processor.uut.memory.mem_op_num"
lappend sg_mem_stage "tb_processor.uut.memory.mem_op_in"
lappend sg_mem_stage "tb_processor.uut.memory.mem_size_in"
lappend sg_mem_stage "tb_processor.uut.memory.dmem_read_ack"
lappend sg_mem_stage "tb_processor.uut.memory.dmem_write_ack"
lappend sg_mem_stage "tb_processor.uut.memory.dmem_data_in"
lappend sg_mem_stage "tb_processor.uut.memory.rd_data_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.pc"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.rd_write_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.rd_addr_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.branch"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.alu_op_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.jump_taken_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.jump_target_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.exception_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.exception_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.csr_addr_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.csr_write_in"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.csr_data_in"
gtkwave::addSignalsFromList $sg_mem_stage
gtkwave::highlightSignalsFromList $sg_mem_stage
gtkwave::/Edit/UnHighlight_All
gtkwave::addSignalsFromList $sg_mem_stage_dec
gtkwave::/Edit/Data_Format/Decimal
gtkwave::highlightSignalsFromList $sg_mem_stage_dec
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Memory_Ext"
set sg_mem_ext [list]
lappend sg_mem_ext "tb_processor.dmem_address"
lappend sg_mem_ext "tb_processor.dmem_data_in"
lappend sg_mem_ext "tb_processor.dmem_data_out"
lappend sg_mem_ext "tb_processor.dmem_data_size"
lappend sg_mem_ext "tb_processor.dmem_read_req"
lappend sg_mem_ext "tb_processor.dmem_read_ack"
lappend sg_mem_ext "tb_processor.dmem_write_req"
lappend sg_mem_ext "tb_processor.dmem_write_ack"
gtkwave::addSignalsFromList $sg_mem_ext
gtkwave::highlightSignalsFromList $sg_mem_ext
gtkwave::/Edit/UnHighlight_All

gtkwave::addCommentTracesFromList "Memory_Out"
set sg_mem_stage [list]
set sg_mem_stage_dec [list]
lappend sg_mem_stage "tb_processor.uut.memory.count_instr_out"
lappend sg_mem_stage "tb_processor.uut.memory.mem_op_out"
lappend sg_mem_stage "tb_processor.uut.memory.rd_write_out"
lappend sg_mem_stage "tb_processor.uut.memory.rd_addr_out"
lappend sg_mem_stage "tb_processor.uut.memory.rd_data_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.wb_op_num"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.alu_op_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.jump_taken_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.jump_target_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.exception_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.exception_context_out"
#lappend sg_mem_stage "tb_processor.uut.memory.csr_addr_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.csr_write_out"
#lappend sg_mem_stage_dec "tb_processor.uut.memory.csr_data_out"
gtkwave::addSignalsFromList $sg_mem_stage
gtkwave::highlightSignalsFromList $sg_mem_stage
gtkwave::/Edit/UnHighlight_All
gtkwave::addSignalsFromList $sg_mem_stage_dec
gtkwave::/Edit/Data_Format/Decimal
gtkwave::highlightSignalsFromList $sg_mem_stage_dec
gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "Writeback_Out"
set sg_writeback [list]
set sg_writeback_dec [list]
lappend sg_writeback "tb_processor.uut.writeback.count_instr_out"
lappend sg_writeback "tb_processor.uut.writeback.op_num_out"
lappend sg_writeback "tb_processor.uut.writeback.alu_op_out"
lappend sg_writeback "tb_processor.uut.writeback.rd_write_out"
lappend sg_writeback "tb_processor.uut.writeback.rd_addr_out"
lappend sg_writeback "tb_processor.uut.writeback.rd_data_out"
#lappend sg_writeback "tb_processor.uut.writeback.jump_taken_out"
#lappend sg_writeback "tb_processor.uut.writeback.jump_target_out"
#lappend sg_writeback "tb_processor.uut.writeback.exception_ctx_out"
#lappend sg_writeback "tb_processor.uut.writeback.exception_out"
#lappend sg_writeback "tb_processor.uut.writeback.csr_write_out"
#lappend sg_writeback "tb_processor.uut.writeback.csr_data_out"
#lappend sg_writeback "tb_processor.uut.writeback.csr_addr_out"
gtkwave::addSignalsFromList $sg_writeback_dec
gtkwave::highlightSignalsFromList $sg_writeback_dec
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All
gtkwave::addSignalsFromList $sg_writeback
gtkwave::/Edit/UnHighlight_All


#gtkwave::addCommentTracesFromList "ROB_Completed_In"
#set sg_completed [list]
#set sg_completed_dec [list]
#lappend sg_completed_dec "tb_processor.uut.reorder_buffer.completed1_num"
#lappend sg_completed     "tb_processor.uut.reorder_buffer.completed1_op"
#lappend sg_completed_dec "tb_processor.uut.reorder_buffer.completed1_res"
#lappend sg_completed     "tb_processor.uut.reorder_buffer.completed1_jump_taken"
#lappend sg_completed_dec "tb_processor.uut.reorder_buffer.completed1_jump_target"
#gtkwave::addSignalsFromList $sg_completed_dec
#gtkwave::highlightSignalsFromList $sg_completed_dec
#gtkwave::/Edit/Data_Format/Decimal
#gtkwave::/Edit/UnHighlight_All
#gtkwave::addSignalsFromList $sg_completed
#gtkwave::/Edit/UnHighlight_All


gtkwave::addCommentTracesFromList "ROB_Commit_Out"
set sg_commit [list]
set sg_commit_dec [list]
#lappend sg_commit_dec "tb_processor.uut.reorder_buffer.committing_t1"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_num"
lappend sg_commit     "tb_processor.uut.reorder_buffer.commit1_op"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_x_src"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_y_src"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_rd_addr"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_res"
lappend sg_commit     "tb_processor.uut.reorder_buffer.commit1_rd_write"
lappend sg_commit     "tb_processor.uut.reorder_buffer.commit1_jump_taken"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_jump_target"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_mem_op"
lappend sg_commit "tb_processor.uut.reorder_buffer.commit1_mem_size"
gtkwave::addSignalsFromList $sg_commit_dec
gtkwave::highlightSignalsFromList $sg_commit_dec
gtkwave::/Edit/Data_Format/Decimal
gtkwave::/Edit/UnHighlight_All
gtkwave::addSignalsFromList $sg_commit
gtkwave::/Edit/UnHighlight_All


gtkwave::/Time/Zoom/Zoom_Full