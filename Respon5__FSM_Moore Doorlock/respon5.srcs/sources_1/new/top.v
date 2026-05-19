module top(
    input wire clk_100MHz,
    input wire sw0,
    input wire btnd,

    output wire led_y,
    output wire led_hb,

    output wire [6:0] seg,
    output wire [7:0] an
);

    wire rst, ce_2s, y;
    wire [1:0] st;

    // =====================================================
    // DEBOUNCER RESET
    // =====================================================

    debouncer db_r (
        .clk(clk_100MHz),
        .btn_in(btnd),
        .btn_pulse(),
        .btn_level(rst)
    );

    // =====================================================
    // CLOCK DIVIDER
    // =====================================================

    clock_divider div (
        .clk_100MHz(clk_100MHz),
        .reset(rst),
        .ce_2s(ce_2s),
        .led_hb(led_hb)
    );

    // =====================================================
    // FSM MOORE DOORLOCK
    // Password : 1 -> 0 -> 1
    // =====================================================

    doorlock_moore fsm (
        .clk(clk_100MHz),
        .reset(rst),
        .ce(ce_2s),
        .w(sw0),
        .y(y),
        .state_display(st)
    );

    // =====================================================
    // DISPLAY
    // =====================================================

    display disp (
        .clk(clk_100MHz),
        .w_in(sw0),
        .y_out(y),
        .state(st),
        .seg(seg),
        .an(an)
    );

    assign led_y = y;

endmodule