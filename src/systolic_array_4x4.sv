module systolic_array_4x4 (
    input  logic                    clk,
    input  logic                    rst,

    // One scheduled activation stream enters each row from the left.
    input  logic signed [7:0]       a_row_in       [0:3],
    input  logic                    a_row_valid_in[0:3],

    // One scheduled weight stream enters each column from the top.
    input  logic signed [7:0]       b_col_in       [0:3],
    input  logic                    b_col_valid_in[0:3],

    // Each PE's local accumulator is one element of C.
    output logic signed [31:0]      c_out          [0:3][0:3]
);

    logic signed [7:0] a_link       [0:3][0:4];
    logic             a_valid_link [0:3][0:4];
    logic signed [7:0] b_link       [0:4][0:3];
    logic             b_valid_link [0:4][0:3];

    genvar i, j;
    generate
        for (i = 0; i < 4; i++) begin : GEN_A_ROW_INPUTS
            assign a_link[i][0]       = a_row_in[i];
            assign a_valid_link[i][0] = a_row_valid_in[i];
        end

        for (j = 0; j < 4; j++) begin : GEN_B_COL_INPUTS
            assign b_link[0][j]       = b_col_in[j];
            assign b_valid_link[0][j] = b_col_valid_in[j];
        end

        for (i = 0; i < 4; i++) begin : GEN_PE_ROWS
            for (j = 0; j < 4; j++) begin : GEN_PE_COLS
                processing_element u_pe (
                    .clk          (clk),
                    .rst          (rst),

                    .a_in         (a_link[i][j]),
                    .a_valid_in   (a_valid_link[i][j]),
                    .a_out        (a_link[i][j+1]),
                    .a_valid_out  (a_valid_link[i][j+1]),

                    .b_in         (b_link[i][j]),
                    .b_valid_in   (b_valid_link[i][j]),
                    .b_out        (b_link[i+1][j]),
                    .b_valid_out  (b_valid_link[i+1][j]),

                    .acc_out      (c_out[i][j])
                );
            end
        end
    endgenerate

endmodule
