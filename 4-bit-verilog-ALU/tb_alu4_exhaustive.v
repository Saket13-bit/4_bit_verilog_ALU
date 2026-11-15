`timescale 1ns/1ps
module tb_alu4_exhaustive;
    reg [3:0] a, b;
    reg [2:0] op;
    wire [3:0] y;
    wire zero, carry, overflow;
    integer ai, bi, oi, signed_a, signed_b, signed_result;
    integer expected_y, expected_carry, expected_overflow;
    integer errors = 0;
    integer checked = 0;

    alu4 dut(a,b,op,y,zero,carry,overflow);

    initial begin
        for (oi=0; oi<8; oi=oi+1) begin
            for (ai=0; ai<16; ai=ai+1) begin
                for (bi=0; bi<16; bi=bi+1) begin
                    a=ai; b=bi; op=oi;
                    signed_a = ai < 8 ? ai : ai-16;
                    signed_b = bi < 8 ? bi : bi-16;
                    signed_result = 0;
                    expected_carry = 0;
                    expected_overflow = 0;
                    case (oi)
                        0: begin
                            expected_y = (ai+bi) % 16;
                            expected_carry = (ai+bi) > 15;
                            signed_result = signed_a+signed_b;
                            expected_overflow = signed_result < -8 || signed_result > 7;
                        end
                        1: begin
                            expected_y = (ai-bi+16) % 16;
                            expected_carry = ai < bi;
                            signed_result = signed_a-signed_b;
                            expected_overflow = signed_result < -8 || signed_result > 7;
                        end
                        2: expected_y = ai & bi;
                        3: expected_y = ai | bi;
                        4: expected_y = ai ^ bi;
                        5: expected_y = 15-ai;
                        6: begin
                            expected_y = (2*ai) % 16;
                            expected_carry = ai >= 8;
                        end
                        7: expected_y = bi;
                    endcase
                    #1;
                    checked = checked+1;
                    if (y !== expected_y[3:0] ||
                        zero !== (expected_y == 0) ||
                        carry !== expected_carry[0] ||
                        overflow !== expected_overflow[0]) begin
                        errors=errors+1;
                        $display("FAIL op=%0d a=%0d b=%0d",oi,ai,bi);
                    end
                end
            end
        end
        if (errors != 0)
            $fatal(1,"%0d errors out of %0d cases",errors,checked);
        $display("PASS: all %0d binary input/opcode combinations matched the reference.",checked);
        $finish;
    end
endmodule
