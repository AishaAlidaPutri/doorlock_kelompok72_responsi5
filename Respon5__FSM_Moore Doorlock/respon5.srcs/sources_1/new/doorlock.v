// #########################################################
// FSM MOORE
// #########################################################

module doorlock_moore(
    input wire clk,
    input wire reset,
    input wire ce,
    input wire w,

    output reg y,
    output wire [1:0] state_display
);

    parameter S0=2'b00,
              S1=2'b01,
              S2=2'b10,
              S3=2'b11;

    reg [1:0] curr, next;

    assign state_display = curr;

    // =====================================================
    // STATE REGISTER
    // =====================================================

    always @(posedge clk or posedge reset) begin
        if(reset)
            curr <= S0;
        else if(ce)
            curr <= next;
    end

    // =====================================================
    // NEXT STATE LOGIC
    // =====================================================

    always @(*) begin

        y = (curr == S3);

        case(curr)

            // menunggu input 1
            S0:
                next = (w) ? S1 : S0;

            // sudah menerima 1
            S1:
                next = (w) ? S1 : S2;

            // sudah menerima 1-0
            S2:
                next = (w) ? S3 : S0;

            // unlock
            S3:
                next = (w) ? S1 : S2;

            default:
                next = S0;

        endcase
    end

endmodule