module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;


reg [4:0] match_index;
reg [5:0] str_ind;
reg [4:0] pat_ind,pat_ind_star;
reg [4:0] m_counter,m_counter_star; //match counter

reg [3:0] current_state,next_state,current_state_process,next_state_process;
reg [7:0] ipt_string [32-1:0];
reg [5:0] str_counter; 
reg [7:0] ipt_pattern [8-1:0];
reg [4:0] pat_counter; 

reg done; 
reg star_flag;



parameter IDLE = 4'b0000;
parameter s_string = 4'b0001; 
parameter s_pattern = 4'b0010; 
parameter s_process = 4'b1001;
parameter s_process_IDLE = 4'b0011;
parameter s_process_check = 4'b0100;
parameter s_process_check_match = 4'b0101;
parameter s_process_done_match = 4'b0110;
parameter s_process_done_unmatch = 4'b0111; 
parameter result = 4'b1000;



// //here bug 
// assign valid = (next_state == result)? 1'b1:1'b0; 
// assign match =(next_state_process == s_process_done_match)? 1'b1:1'b0;
// assign match = check_flag[0]; 


reg valid;
always @(posedge clk) begin
    if( next_state == result)valid <= 1'b1;
    else valid <= 1'b0;
end


reg match;
// match
always@(posedge clk) begin
    if(reset) match <= 1'd0;
    else if(next_state_process == s_process_done_match) match <= 1'd1;
    else if(next_state_process == s_process_done_unmatch) match <= 1'd0;
end



reg [2-1:0] check_flag;

always @(posedge clk) begin
    if (current_state_process == s_process_done_match) check_flag <= 2'b01;
    else if (current_state_process == s_process_done_unmatch) check_flag <= 2'b00;
    else check_flag <= 2'b10;
     
end

always@(posedge clk) begin
    if(reset) begin
        pat_counter <= 0;
        for(i = 0;i < 8;i = i + 1) begin
            ipt_pattern[i] <= 8'd0;
        end       
    end
    else if(ispattern == 1'b1)begin
        ipt_pattern[pat_counter] <= chardata;
        pat_counter <= pat_counter + 1'b1;
    end 
    else if (next_state == result) pat_counter <= 0;
end



reg [5:0] str_counter_reg;

integer  i;
always@(posedge clk or posedge reset) begin
    if(reset) begin
        for(i=0;i<32;i=i+1) begin
            ipt_string[i] <= 8'd0;
        end
    end
    else if(isstring == 1'd1) ipt_string[str_counter] <= chardata;
end

//string counter
always@(*) begin
    if(current_state == result&& next_state == s_string) str_counter <= 6'd0;
    else if(current_state == IDLE&& next_state == s_string) str_counter <= 6'd0;
    else if(isstring == 1'd1) str_counter <= str_counter_reg + 6'd1;
    else str_counter <= str_counter_reg;
end

always@(posedge clk or posedge reset) begin
    if(reset) str_counter_reg <= 6'd0;
    else if(isstring == 1'd1) str_counter_reg <= str_counter;
end







always@(posedge clk) begin
    if(reset) begin
        current_state <= IDLE;
        current_state_process <= s_process_IDLE;
    end
    else begin
        current_state <= next_state;
        current_state_process <= next_state_process;
    end
end





always@(*) begin
    case(current_state)
        IDLE: begin
            if(isstring == 1'b1) next_state <= s_string;
            else if(ispattern == 1'b1) next_state <= s_pattern;
            else next_state = IDLE;
        end
    
        s_string: begin
            if(isstring == 1'b0) next_state <= s_pattern;
            else next_state <= s_string;
        end
    
        s_pattern: begin
            if(ispattern == 1'b1) next_state <= s_pattern;
            else next_state <= s_process;
        end
    
        s_process: begin
            if(done == 1'b1) next_state <= result;
            else next_state <= s_process;
        end
    
        result: begin
            if(isstring == 1'b1) next_state <= s_string;
            else if(ispattern == 1'b1) next_state <= s_pattern;
            else next_state <= IDLE;
        end
    default: next_state <= IDLE;
    endcase 
end


always @(*) begin
    if(current_state == s_process)begin
        case(current_state_process)
            
            s_process_IDLE:begin
                next_state_process <= s_process_check;
                
            end
            
            s_process_check:begin
                if( m_counter == pat_counter ) next_state_process <= s_process_done_match;
                else if( str_ind == str_counter || pat_counter == pat_ind )next_state_process <= s_process_check_match;
                else next_state_process <= s_process_check;
            end
            
            s_process_check_match:begin
                if( ipt_pattern[pat_counter - 1'b1] == 8'h24 ) begin
                    if(pat_counter == m_counter + 1'b1) next_state_process <= s_process_done_match;
                    else next_state_process <= s_process_done_unmatch;
                end
                else begin 
                    if(m_counter == pat_counter ) next_state_process <= s_process_done_match;
                    else next_state_process <= s_process_done_unmatch;
                end
            end
            
            s_process_done_match:begin
                next_state_process <= s_process_IDLE;
            end        
            
            s_process_done_unmatch:begin
                next_state_process <= s_process_IDLE;
            end

            default:
                next_state_process <= s_process_IDLE;


        endcase
    end
    else next_state_process <= s_process_IDLE;
end






always@(posedge clk) begin
    if(reset || current_state == result) begin
        
        str_ind <= 0;
        pat_ind <= 0 ;
        star_flag <= 1'b0;
        done <= 1'b0;
        m_counter <= 0;
        match_index <= 0;
        pat_ind_star <= 0;
        m_counter_star <= 0;

    end
    

    else if(current_state == s_process) begin
        if(current_state_process == s_process_check) begin
            // if is the  first => metch inedec give str index
            if(pat_ind == 5'b00000) match_index <= str_ind;
    
            // if same or is '.' => match counted 
            if( (ipt_string[str_ind] == ipt_pattern[pat_ind]) || (ipt_pattern[pat_ind]== 8'h2e))begin
                str_ind <= str_ind + 1'b1 ;
                pat_ind <= pat_ind + 1'b1 ;
                m_counter <= m_counter + 1'b1 ;
                // if(pat_ind == 5'b00000) match_index <= str_ind;

            end

            // if is '^'
            else if (ipt_pattern[pat_ind] == 8'h5E )begin
                // if is ( the first or the space ) and next is match => match counted
                if( (ipt_string[pat_ind] == 8'h20 ) && (( ipt_string[str_ind + 1'b1] == ipt_pattern[pat_ind + 1'b1]) || ipt_pattern[pat_ind + 1'b1] == 8'h2E))begin
                    str_ind <= str_ind + 1'b1 ;
                    pat_ind <= pat_ind + 1'b1 ;
                    m_counter <= m_counter + 1'b1 ;
                    if( ipt_string[str_ind] == 8'h20 )match_index <= str_ind + 1'b1 ;
                    //if is the first => give str index (0)
                    else match_index <= str_ind ;
                end

                else if( (str_ind == 6'b000000 ) && (( ipt_string[str_ind ] == ipt_pattern[pat_ind + 1'b1]) || ipt_pattern[pat_ind + 1'b1] == 8'h2E))begin
                    str_ind <= str_ind + 1'b1 ;
                    pat_ind <= pat_ind + 1'b1 ;
                    m_counter <= m_counter + 1'b1 ;
                    // if is the space =>¡@not first => give str index +1
                    if( ipt_string[str_ind] == 8'h20 )match_index <= str_ind + 1'b1 ;
                    //if is the first => give str index (0)
                    else match_index <= str_ind ;
                end
                // not match
                else begin
                    pat_ind <= pat_ind ;
                    m_counter <= 5'b00000 ;
                    // if is the fisrt char of pattern => shift one char
                    if(pat_ind == 5'b00000)str_ind <= str_ind + 1'b1;
                    // if had been match many chars => shift to match index
                    else str_ind <= match_index + 1'b1;

                end
            end
            // if is $ and (is on string's last or pattern star ) 
            else if( ipt_pattern[pat_ind] == 8'h24 && ( str_ind == str_counter || ipt_pattern[pat_ind]  == 8'h20) )begin
                pat_ind <= pat_ind + 1'b1 ;
                str_ind <= str_ind + 1'b1 ; 
                m_counter <= m_counter + 1'b1 ;
                // if(pat_ind == 5'b00000) match_index <= str_ind;

            end

            // if is '*' => str don't mv because can be zero 
            else if (ipt_pattern[pat_ind] == 8'h2A)begin
                
                str_ind <= str_ind ;
                pat_ind <= pat_ind + 1'b1;
                pat_ind_star <= pat_ind + 1'b1;
                m_counter_star <= m_counter + 1'b1;
                // match_index <= match_index + 1'b1;
                m_counter <= m_counter + 1'b1;
                star_flag <= 1'b1;
                // if(pat_ind == 5'b00000) match_index <= str_ind;


            end
            // if had been starred and encounter diff and isn't '.' => 
            else if( star_flag == 1'b1 &&  ipt_string[str_ind] != ipt_pattern[pat_ind] && ipt_pattern[pat_ind] != 8'h2E)begin
                str_ind <= str_ind + 1'b1;
                pat_ind <= pat_ind_star ;
                m_counter <= m_counter_star;
                
            end
            // not been starred and diff => not match  => to zero
            else if((ipt_string[str_ind] != ipt_pattern[pat_ind]) && (ipt_pattern[pat_ind] != 8'h2E))begin
                pat_ind <= pat_ind_star;
                m_counter <= 0;
                if(pat_ind != 0)str_ind <= match_index + 1'b1 ;
                else str_ind <= str_ind + 1'b1 ;

            end
        end
        else if(current_state_process == s_process_done_match || current_state_process == s_process_done_unmatch) begin 
            done <= 1'b1;
        end 
    end


    else begin
        done <= 1'b0;
    end
end



endmodule