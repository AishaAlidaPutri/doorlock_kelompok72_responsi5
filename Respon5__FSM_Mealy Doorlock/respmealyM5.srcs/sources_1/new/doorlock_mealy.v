module doorlock_mealy(
    input clk,              // Osilator internal Nexys A7 100MHz (Pin E3)
    input clk_sw,           // Saklar Clock Manual (Switch L16)
    input reset,            // Tombol Reset Tengah (BTNC)
    input w,                // Switch Input Data (SW0)
    output reg y,           // Output LED0 (Backup)
    output reg [7:0] an,    // Aktivasi Anode Seven Segment
    output reg [6:0] seg    // Katode Seven Segment
);

    // DEKLARASI STATE
    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;

    reg [1:0] state, next_state;
    reg [19:0] debounce_div; 
    reg clk_sw_sync0, clk_sw_sync1;
    reg clk_sw_debounced;
    reg clk_sw_prev;
    wire manual_clk_edge;

    // 1. LOGIKA DEBOUNCER UNTUK SWITCH L16
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            debounce_div <= 0;
            clk_sw_sync0 <= 0;
            clk_sw_sync1 <= 0;
            clk_sw_debounced <= 0;
        end else begin
            debounce_div <= debounce_div + 1;
            if(debounce_div == 0) begin
                clk_sw_sync0 <= clk_sw;
                clk_sw_sync1 <= clk_sw_sync0;
                if(clk_sw_sync1 == clk_sw_sync0) begin
                    clk_sw_debounced <= clk_sw_sync1;
                end
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if(reset) clk_sw_prev <= 0;
        else      clk_sw_prev <= clk_sw_debounced;
    end
    assign manual_clk_edge = (clk_sw_debounced && !clk_sw_prev);

    // 2. STATE REGISTER
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= S0;
        end else begin
            if(manual_clk_edge) begin
                state <= next_state;
            end
        end
    end

    // 3. NEXT STATE + MEALY OUTPUT LOGIC
    always @(*) begin
        y = 0;
        case(state)
            S0: begin
                if(w == 1) next_state = S1;
                else       next_state = S0;
            end
            S1: begin
                if(w == 0) next_state = S2;
                else       next_state = S0;
            end
            S2: begin
                if(w == 1) begin
                    next_state = S0;
                    y = 1;
                end else begin
                    next_state = S0;
                    y = 0;
                end
            end
            default: begin
                next_state = S0;
                y = 0;
            end
        endcase
    end

    // =========================================================================
    // LOGIKA DISPLAY SEVEN SEGMENT (COMMON ANODE: 0 = NYALA, 1 = MATI)
    // Bit mapping: [G F E D C B A]
    // =========================================================================
    localparam CHAR_W  = 7'b0011101; 
    localparam CHAR_Y  = 7'b0010001; 
    localparam CHAR_S  = 7'b0010010; 
    localparam CHAR_T  = 7'b0000111; 
    
    // Pola angka biner yang sudah divalidasi dengan board fisik Nexys A7
    localparam CHAR_0  = 7'b1000000; // Angka 0 (Hanya segmen G tengah yang mati)
    localparam CHAR_1  = 7'b1111001; // Angka 1 (Hanya segmen B & C kanan yang nyala)
    localparam CHAR_2  = 7'b0100100; // Angka 2 Sempurna (Segmen C & F mati)

    reg [16:0] display_div;
    always @(posedge clk or posedge reset) begin
        if(reset) display_div <= 0;
        else      display_div <= display_div + 1;
    end
    wire [2:0] seg_select = display_div[16:14];

    always @(*) begin
        an = 8'b11111111;
        seg = 7'b1111111;

        case(seg_select)
            // Digit 7 & 6: Menampilkan w.0 atau w.1
            3'b111: begin an = 8'b01111111; seg = CHAR_W; end
            3'b110: begin an = 8'b10111111; seg = (w) ? CHAR_1 : CHAR_0; end

            // Digit 5 & 4: Menampilkan y.0 atau y.1
            3'b101: begin an = 8'b11011111; seg = CHAR_Y; end
            3'b100: begin an = 8'b11101111; seg = (y) ? CHAR_1 : CHAR_0; end

            // Digit 3, 2, 1, 0: Menampilkan St.00, St.01, atau St.02
            3'b011: begin an = 8'b11110111; seg = CHAR_S; end
            3'b010: begin an = 8'b11111011; seg = CHAR_T; end
            3'b001: begin an = 8'b11111101; seg = CHAR_0; end
            3'b000: begin 
                an = 8'b11111110;
                case(state)
                    S0:      seg = CHAR_0;
                    S1:      seg = CHAR_1;
                    S2:      seg = CHAR_2;
                    default: seg = CHAR_0;
                endcase
            end
        endcase
    end

endmodule