module systolic_top (
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    start,

    // Matrices are presented in parallel at the top-level interface.
    input  logic signed [7:0]       A [0:3][0:3],
    input  logic signed [7:0]       B [0:3][0:3],

    output logic                    busy,
    output logic                    done,
    output logic signed [31:0]      C [0:3][0:3]
);

    // For a 4x4 array, the final pair (A[3][3], B[3][3]) reaches
    // PE(3,3) at scheduled cycle k+i+j = 3+3+3 = 9.
    localparam int LAST_SCHEDULE_CYCLE = 9;

    logic [3:0] cycle_count;

    logic signed [7:0] a_row_in        [0:3];
    logic             a_row_valid_in  [0:3];
    logic signed [7:0] b_col_in        [0:3];
    logic             b_col_valid_in  [0:3];

    integer i, j;

    // Generate the skewed streams.
    // A[i][k] enters row i at cycle k+i.
    // B[k][j] enters column j at cycle k+j.
    always_comb begin
        for (int r = 0; r < 4; r++) begin
            a_row_in[r]       = '0;
            a_row_valid_in[r] = 1'b0;
            b_col_in[r]       = '0;
            b_col_valid_in[r] = 1'b0;
        end

        if (busy) begin
            // Activations: row i is delayed by i cycles.
            for (int r = 0; r < 4; r++) begin
                for (int k = 0; k < 4; k++) begin
                    if (cycle_count == (r + k)) begin
                        a_row_in[r]       = A[r][k];
                        a_row_valid_in[r] = 1'b1;
                    end
                end
            end

            // Weights: column j is delayed by j cycles.
            for (int c = 0; c < 4; c++) begin
                for (int k = 0; k < 4; k++) begin
                    if (cycle_count == (c + k)) begin
                        b_col_in[c]       = B[k][c];
                        b_col_valid_in[c] = 1'b1;
                    end
                end
            end
        end
    end

    systolic_array_4x4 u_array (
        .clk             (clk),
        .rst             (rst),
        .a_row_in        (a_row_in),
        .a_row_valid_in  (a_row_valid_in),
        .b_col_in        (b_col_in),
        .b_col_valid_in  (b_col_valid_in),
        .c_out            (C)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            busy       <= 1'b0;
            done       <= 1'b0;
            cycle_count <= '0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                if (start) begin
                    busy        <= 1'b1;
                    cycle_count <= '0;
                end
            end else begin
                if (cycle_count == LAST_SCHEDULE_CYCLE) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    cycle_count <= cycle_count + 1'b1;
                end
            end
        end
    end

endmodule
