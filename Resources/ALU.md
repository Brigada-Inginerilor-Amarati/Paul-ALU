## Project Overview

You will design and simulate an 8-bit Arithmetic Logic Unit (ALU) using a Hardware Description Language (HDL) of your choice (e.g., VHDL, Verilog). The project is to be completed **structurally**, emphasizing the hardware components rather than behavioral descriptions.

## Team Composition

- Teams of 1–4 students.

## Project Requirements

Your ALU must support the following arithmetic operations:

1. **Addition**
2. **Subtraction**
3. **Multiplication**
4. **Division**
### Multiplication Algorithms

You must implement one multiplication algorithm of your choice, from the following options studied during the laboratory:

- Booth Radix-2
- Modified Booth Algorithm
- Booth Radix-4
- Booth Radix-8
### Division Algorithms

You must implement one division algorithm of your choice, from the following options studied during the laboratory:

- Restoring Division
- Non-restoring Division
- SRT Radix-2
- SRT Radix-4
### Structural Implementation

Your HDL code should be structurally described, which means:

- Clearly defined hardware modules and interconnections
- Separate implementation for Arithmetic Unit, Control Unit, Multiplexer, Registers, and other necessary hardware components
- Minimal or no behavioral code
### Control Unit

You must design a Control Unit capable of emitting appropriate control signals to select and execute each arithmetic operation.

## Recommended Tools

You may use any HDL simulation tool of your choice. Recommended tools include: ModelSim, Quartus Prime, Xilinx Vivado, Icarus Verilog

## Project Phases

The project will be divided into three primary phases:

### 1. Design Phase

- Define the architecture and component modules.
- Provide schematic diagrams detailing module connections and signal flow.
- Clearly indicate the algorithm choices for multiplication and division
### 2. Implementation Phase

- Write structurally-oriented HDL code.
- Implement each arithmetic module individually.
- Integrate modules with the Control Unit to form a fully operational 8-bit ALU.
### 3. Testing Phase

- Develop comprehensive testbenches for each arithmetic operation.
- Perform simulations to verify correctness.
- Provide simulation waveforms demonstrating successful operation.
## Deliverables

Your final submission should include:

- **Documentation**:
    
    - Project overview and objectives
        
    - Architecture diagrams and explanations
        
    - HDL code listings (clearly commented and structured)
        
    - Testbench descriptions and simulation waveforms
        
    - Discussion of results, including issues encountered and resolutions
        
- **Presentation**:
    
    - Prepare a concise presentation (~10 minutes) summarizing design decisions, structural implementations, testing procedures, and final results.
        
    - Presentations will be conducted during **Week 9** of the laboratory sessions.
        

## Evaluation Criteria

- Correctness and functionality of arithmetic operations
    
- Clarity and structural organization of HDL implementation
    
- Completeness of testing and accuracy of simulations
    
- Quality and clarity of project documentation and presentation
    
- Team collaboration and individual contribution (where applicable)