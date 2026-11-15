`timescale 1ns/1ps
module tb_alu4;
    reg [3:0] a;
    reg [3:0] b;
    reg [2:0] op;
    wire [3:0] y;
    wire zero;
    wire carry;
    wire overflow;

    integer errors = 0;

    alu4 dut (
        .a(a),
        .b(b),
        .op(op),
        .y(y),
        .zero(zero),
        .carry(carry),
        .overflow(overflow)
    );

    task check;
        input [3:0] test_a;
        input [3:0] test_b;
        input [2:0] test_op;
        input [3:0] expected_y;
        input expected_zero;
        input expected_carry;
        input expected_overflow;
        begin
            a = test_a;
            b = test_b;
            op = test_op;
            #1;
            if (y !== expected_y ||
                zero !== expected_zero ||
                carry !== expected_carry ||
                overflow !== expected_overflow) begin
                $display("FAIL op=%b a=%b b=%b got y=%b z=%b c=%b v=%b",
                         test_op, test_a, test_b, y, zero, carry, overflow);
                errors = errors + 1;
            end else begin
                $display("PASS op=%b a=%b b=%b -> y=%b z=%b c=%b v=%b",
                         test_op, test_a, test_b, y, zero, carry, overflow);
            end
        end
    endtask

    initial begin
        $dumpfile("alu4.vcd");
        $dumpvars(0, tb_alu4);

        // Addition: signed overflow, unsigned carry, zero, and ordinary sum.
        check(4'd7,  4'd3,  3'b000, 4'd10, 1'b0, 1'b0, 1'b1);
        check(4'd15, 4'd1,  3'b000, 4'd0,  1'b1, 1'b1, 1'b0);
        check(4'd1,  4'd1,  3'b000, 4'd2,  1'b0, 1'b0, 1'b0);

        // Subtraction: no borrow, borrow, and signed overflow.
        check(4'd5,  4'd3,  3'b001, 4'd2,  1'b0, 1'b0, 1'b0);
        check(4'd2,  4'd5,  3'b001, 4'd13, 1'b0, 1'b1, 1'b0);
        check(4'd7,  4'd15, 3'b001, 4'd8,  1'b0, 1'b1, 1'b1);

        // Logic, shift, and pass-through operations.
        check(4'b1010, 4'b1100, 3'b010, 4'b1000, 1'b0, 1'b0, 1'b0);
        check(4'b1010, 4'b1100, 3'b011, 4'b1110, 1'b0, 1'b0, 1'b0);
        check(4'b1010, 4'b1100, 3'b100, 4'b0110, 1'b0, 1'b0, 1'b0);
        check(4'b1010, 4'b0000, 3'b101, 4'b0101, 1'b0, 1'b0, 1'b0);
        check(4'b1010, 4'b0000, 3'b110, 4'b0100, 1'b0, 1'b1, 1'b0);
        check(4'b0000, 4'b0000, 3'b111, 4'b0000, 1'b1, 1'b0, 1'b0);

        if (errors == 0) begin
            $display("All test vectors passed.");
        end else begin
            $fatal(1, "%0d test vector(s) failed.", errors);
        end
        $finish;
    end
endmodule
