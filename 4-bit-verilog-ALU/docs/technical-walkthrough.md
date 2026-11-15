# 4-bit ALU — technical walkthrough

**The purpose.** An arithmetic logic unit takes operands and an operation selector, then produces a result and status flags. Our inputs A and B are four bits each, and the opcode is three bits. Four bits encode 16 patterns. These can represent unsigned values 0 to 15 or signed two's-complement values -8 to +7.

The same bits can have different interpretations. 1111 is unsigned 15 or signed -1. 1010 is unsigned 10 or signed -6. The hardware computes bits; the flag rules allow both interpretations to be assessed.

**Operations.**

| Opcode | Operation | Example |
|---|---|---|
| 000 | A+B | 0011+0010 → 0101 |
| 001 | A-B | 0101-0011 → 0010 |
| 010 | Bitwise AND | 1010 AND 1100 → 1000 |
| 011 | Bitwise OR | 1010 OR 1100 → 1110 |
| 100 | Bitwise XOR | 1010 XOR 1100 → 0110 |
| 101 | Bitwise NOT A | NOT 1010 → 0101 |
| 110 | Logical left shift by one | 1010 → 0100, shifted-out bit 1 |
| 111 | Pass B | Y=B |

Each bitwise operation works independently on corresponding bit positions. A logical left shift inserts zero on the right and discards the most significant bit.

**Why the arithmetic temporary has five bits.** Adding two four-bit unsigned inputs can produce up to 30. The concatenation {1'b0,a} prepends zero to make a five-bit operand. temp retains the complete five-bit result; y=temp[3:0] keeps the low four bits, and carry=temp[4] retains the extra bit.

15+1 becomes 1111+0001 = 10000. The four-bit result is 0000, carry is 1, and zero is 1. Under signed interpretation this is -1+1=0, so signed overflow is 0.

**Carry and overflow are different.** 7+3 produces 1010. Unsigned 10 fits in four bits, so carry is zero. Signed 10 exceeds +7, and 1010 would be read as -6, so overflow is one.

For addition, overflow occurs when inputs have the same sign and the result has the opposite sign:

    Vadd = NOT(A3 XOR B3) AND (Y3 XOR A3)

For subtraction, overflow occurs when the operands have different signs and the result's sign differs from A:

    Vsub = (A3 XOR B3) AND (Y3 XOR A3)

The zero flag is simply Y == 0.

**Subtraction convention.** Our carry output means borrow during subtraction. Thus 2-5 produces the bit pattern 1101, representing -3 in two's complement; borrow=1, zero=0, overflow=0. The negative unsigned five-bit intermediate wraps modulo 32, so its high bit indicates borrow for this operand range. Other ALU designs may use carry=1 to mean no borrow; flag conventions must always be stated.

**Combinational Verilog.** always @* reevaluates when an input read by the block changes. Default assignments give every output a value on every path, which avoids inferring unwanted latches. Blocking assignments let temp and y be used later in the same evaluation. Although outputs are declared reg in this Verilog syntax, that keyword does not by itself imply a clocked register. There is no clock here.

**How it was run.** Icarus Verilog compiles the module and testbench into a simulation program; vvp executes it. The 12-case demonstration passed. The exhaustive testbench loops through all 16 values of A, all 16 values of B, and all eight opcodes, for 2,048 cases. Arithmetic expected values use ordinary integer calculations and signed range checks rather than copying the RTL overflow equations. Every case passed.

The waveform file records changes in A, B, opcode, result, and flags. In the first interval, A=0111, B=0011 and opcode=000 produce Y=1010 and overflow=1. In the next interval, 1111+0001 produces zero and carry. The 1 ns spacing comes from the testbench's #1 delay. It is not a measured or synthesized propagation delay.

Functional RTL simulation does not establish physical breadboard behavior. Possible next steps are gate-level mapping, FPGA synthesis, and timing analysis.
