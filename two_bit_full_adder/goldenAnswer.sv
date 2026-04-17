module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule


module two_bit_full_adder (
    input  logic [1:0] a,
    input  logic [1:0] b,
    input  logic       cin,
    output logic [1:0] sum,
    output logic       cout
);
    logic carry;

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(cin),   .sum(sum[0]), .cout(carry));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(carry), .sum(sum[1]), .cout(cout));
endmodule
