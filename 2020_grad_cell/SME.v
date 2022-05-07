module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;
// reg match;
// reg [4:0] match_index;
// reg valid;
//state => prepare , string ,pattern ,process , result 
//process => process_prepare , check , match , unmatch

reg [3-1:0] current_state,next_state;
parameter s_prepare = 4'b0000 ;
parameter s_string = 4'b0001 ;
parameter s_pattern = 4'b0010 ;
parameter s_process_prepare = 4'b0011 ;
parameter s_process_check = 4'b0100 ;
parameter s_process_match = 4'b0101 ;
parameter s_process_unmatch = 4'b0110 ;
parameter s_result = 4'b0111 ;

reg [2-1:0] check_flag;// 1: match ; 0: unmatch; 2:checking

reg [256-1:0] ipt_string;
reg [64-1:0] ipt_pattern;
















assign match = check_flag[0];


always @(*) begin
    if(reset) begin
        current_state <= s_prepare;
        check_flag <= 2'b10;
    end
    else current_state <= next_state;
end


always @(*) begin
    case(current_state)
        s_prepare:begin
            
            if(isstring == 1'b1) next_state <= s_string;
            else next_state <= s_prepare;
            ipt_string <= {256{1'b0}};

        end        
        
        s_string:begin
            if(isstring == 1'b0) next_state <= s_pattern;
            else next_state <= s_string;
        end        
        
        s_pattern:begin
            if(ispattern == 1'b0) next_state <= s_process_prepare;
            else next_state <= s_pattern;
        end
        
        s_process_prepare:begin
            next_state <= s_process_check;
        end
        
        s_process_check:begin
            if(check_flag == 2'b01) next_state <= s_process_match;
            else if(check_flag == 2'b00 )next_state <= s_process_unmatch;
            else next_state <= s_process_check;
        end
        
        s_process_match:begin
            next_state <= s_result;
            ipt_pattern <= {64{1'b0}};
        end        
        
        s_process_unmatch:begin
            next_state <= s_result;
            ipt_pattern <= {64{1'b0}};
        end        
        
        s_result:begin
            if(ispattern == 1'b1)next_state <= s_process_prepare;
            else  next_state <= s_prepare;

        end        
        
        default:
            next_state <= s_prepare;

    endcase
end

















endmodule
