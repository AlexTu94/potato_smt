# Potato Simultaneous Multithreading (SMT) RISC-V Processor

This project is an evolution of the Potato processor, originally a 5-stage in-order RISC-V processor. It has been extended with a Reorder Buffer (ROB) to support Out-of-Order (OoO) execution and is currently being updated to implement **Simultaneous Multithreading (SMT)**.

## Architecture

- **ISA**: RV32I-Zicsr
- **Pipeline**: Extended with a **Reorder Buffer (ROB)** stage and parallelized for SMT.
- **Execution Model**: Out-of-Order execution with Simultaneous Multithreading support.
- **SMT Implementation**:
  - **Parallelized Stages**: Fetch, Decode, and ROB stages are parallelized to support multiple threads.
  - **Thread Support**: Initial implementation supports two threads (Main thread and a secondary hardware thread).
  - **Dual ROBs**: Two separate Reorder Buffers are used, one for the Main thread and one for the second thread.
  - **Execution Unit**: Capable of executing two instructions simultaneously, provided they utilize different functional units (e.g., an `ADD` and an `OR` can execute together, but two `AND`s cannot).
  - **Arbiter Module**: A dedicated Arbiter (to be implemented) manages instruction dispatch and resolves conflicts between the two ROBs.
- **Hazard Management**: RAW (Read-After-Write) hazards are managed through the ROB and renaming/forwarding mechanisms.

## Project Structure

- `src/`: VHDL source files for the processor core and components.
  - `pp_rob.vhd`: Implementation of the Reorder Buffer.
  - `pp_core.vhd`: Top-level core integration.
- `soc/`: System-on-Chip components (memory, UART, timer, GPIO).
- `sim/`: Simulation scripts and test programs.
- `tests/`: Assembly and C programs for functional verification.
- `software/`: Bootloader and sample applications.
- `testbenches/`: VHDL testbenches for individual components and the full SoC.

## Simulation & Development

### Vivado Simulation
The project is designed to be simulated using Xilinx Vivado. 
- Top-level simulation usually targets `tb_soc` or `tb_processor`.
- Use the provided testbenches in the `testbenches/` directory.

### Functional Verification
The `tests/` directory contains specific programs to verify the processor's functionality, including hazard handling and OoO execution logic.

## Conventions

- **Language**: VHDL is used for RTL design.
- **Tooling**: Xilinx Vivado for synthesis and simulation.
- **ISA Compliance**: Must maintain compatibility with RV32I and Zicsr extension.
