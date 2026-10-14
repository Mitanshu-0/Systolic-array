module processing_element (
    input  logic                    clk,
    input  logic                    rst,

    // Activation travels left -> right.
    input  logic signed [7:0]       a_in,
    input  logic                    a_valid_in,
    output logic signed [7:0]       a_out,
    output logic                    a_valid_out,

    // Weight travels top -> bottom.
    input  logic signed [7:0]       b_in,
    input  logic                    b_valid_in,
    output logic signed [7:0]       b_out,
    output logic                    b_valid_out,

    // This PE owns exactly one output accumulator.
    output logic signed [31:0]      acc_out
);

    logic signed [15:0] product;

    always_comb begin
        product = a_in * b_in;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            a_out       <= '0;
            a_valid_out <= 1'b0;
            b_out       <= '0;
            b_valid_out <= 1'b0;
            acc_out     <= '0;
        end else begin
            // Registered forwarding: operands advance by one PE per cycle.
            a_out       <= a_in;
            a_valid_out <= a_valid_in;
            b_out       <= b_in;
            b_valid_out <= b_valid_in;

            // Update only when both operands are valid and aligned.
            if (a_valid_in && b_valid_in)
                acc_out <= acc_out + {{16{product[15]}}, product};
        end
    end

endmodule
