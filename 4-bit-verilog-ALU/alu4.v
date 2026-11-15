`timescale 1ns/1ps
module alu4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [2:0] op,
    output reg  [3:0] y,
    output reg        zero,
    output reg        carry,
    output reg        overflow
);

    reg [4:0] temp;

    always @* begin
        y        = 4'b0000;
        temp     = 5'b00000;
        zero     = 1'b0;
        carry    = 1'b0;
        overflow = 1'b0;

        case (op)
            3'b000: begin // ADD
                temp = {1'b0, a} + {1'b0, b};
                y = temp[3:0];
                carry = temp[4];
                overflow = (~(a[3] ^ b[3])) & (y[3] ^ a[3]);
            end

            3'b001: begin // SUB; carry output is borrow
                temp = {1'b0, a} - {1'b0, b};
                y = temp[3:0];
                carry = temp[4];
                overflow = (a[3] ^ b[3]) & (y[3] ^ a[3]);
            end

            3'b010: y = a & b;
            3'b011: y = a | b;
            3'b100: y = a ^ b;
            3'b101: y = ~a;

            3'b110: begin // Logical shift left by one
                y = {a[2:0], 1'b0};
                carry = a[3];
            end

            3'b111: y = b;
            default: y = 4'b0000;
        endcase

        zero = (y == 4'b0000);
    end

endmodule
