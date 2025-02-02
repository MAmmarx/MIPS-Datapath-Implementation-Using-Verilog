# MIPS-Datapath-Implementation-Using-Verilog
This project was made in 2nd Year of Univesity in Computer Organization course and its about making a datapath mips using verilog.

# 🖥️ MIPS Datapath Implementation in Verilog

## 📌 Overview  
This project implements a **MIPS-like Processor Datapath** using **Verilog**. It covers essential components like the **Arithmetic Logic Unit (ALU)**, **Program Counter (PC)**, **Instruction Memory**, **Register File**, **Data Memory**, and **Multiplexers**. The datapath allows for arithmetic, logical, memory, and branching operations, with a testbench that validates the processor's functionality.

---

## 📂 Features  
✅ **ALU Operations**: Performs arithmetic and logical operations like addition, subtraction, AND, OR, XOR, etc.  
✅ **Program Counter (PC)**: Tracks and updates the address of the current instruction.  
✅ **Instruction Memory**: Fetches instructions from memory based on the PC.  
✅ **Register File**: Provides read and write access to 32 registers.  
✅ **Data Memory**: Supports read and write operations with different data sizes (byte, halfword, word).  
✅ **Branching & Jumping**: Implements branch and jump operations for conditional control flow.  
✅ **Testbench**: Simulates the datapath with multiple test cases, including arithmetic, logical, load/store, and branching operations.

---

## ⚙️ How It Works  
1. **Instruction Fetching**: The Program Counter fetches the next instruction from memory.  
2. **Instruction Decoding**: The instruction is decoded to extract register addresses and control signals.  
3. **ALU Operations**: The ALU performs calculations or logical operations based on the operands and control signals.  
4. **Memory Operations**: Data is read from or written to memory depending on the operation.  
5. **Branching**: The PC is updated based on branch conditions (e.g., `BEQ` instruction).  
6. **Testbench**: The testbench simulates different instruction types and verifies the output.

---

## 🛠️ Installation & Usage  
### **🔹 Prerequisites**  
- A **Verilog simulator** (e.g., ModelSim, VCS, XSIM)  

### **🔹 Running the Simulation**  
1. **Clone this repository**:  
   ```sh
   git clone https://github.com/YOUR_USERNAME/mips-datapath-verilog.git
