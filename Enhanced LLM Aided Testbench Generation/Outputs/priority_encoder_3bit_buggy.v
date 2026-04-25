
module priority_encoder_3bit (
    input  wire [2:0] in,
    output reg  [1:0] out,
    output reg        valid
);
    always @(*) begin
        if (in[1]) begin          // BUG: should check in[2] first
            out   = 2'b01;
            valid = 1'b1;
        end else if (in[2]) begin // BUG: in[2] should have highest priority
            out   = 2'b10;
            valid = 1'b1;
        end else if (in[0]) begin
            out   = 2'b00;
            valid = 1'b1;
        end else begin
            out   = 2'b00;
            valid = 1'b0;
        end
    end
endmodule
