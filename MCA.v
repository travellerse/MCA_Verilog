module MCA();

    // 定义输入输出端口
    reg clk;
    reg rst;
    parameter clk_period = 2;  
    initial begin  
        clk = 0;  
        forever  
        begin
            #(clk_period/2) clk = ~clk;  
        end
    end

    output reg [15:0] count [0:1023];

    // 定义文件
    reg [15:0] Co_data [0:1023];
    reg [15:0] peak [0:1023];
    reg [15:0] zero_peak [0:1023];
    reg [15:0] peak_count;
    reg [31:0] Co_data_sum [0:1023];
    reg [15:0] Co_data_size;
    reg [31:0] sum;
    reg [31:0] count_sum;
    reg [15:0] show;
    integer i;
    reg [15:0] j;
    reg [15:0] con;
    reg flag;
    integer k;

    function [15:0] get_index_for_data;
        input [31:0] input_data;
        reg [15:0] index;
        begin
            index = get_random_data_index(input_data);
            //$display("random = %d, index = %d", random, index);
            get_index_for_data = index;
        end
    endfunction

    function [15:0] get_random_data_index;
        input [31:0] random;
        begin
            con = 0;
            flag = 0;
            for (j = 0; j < 1024 && random >= Co_data_sum[j]; j = j + 1) begin
                if(random < Co_data_sum[j] && flag == 0)
                begin
                    flag = 1;
                    get_random_data_index = con;
                end
                if(flag == 0)
                    con = con + 1;
            end
            if(flag == 0)
                get_random_data_index = con;
        end
    endfunction

    function [15:0] moving_average;
        input [15:0] flag;
        reg [15:0] average;
        reg [15:0] temp_data [0:1023];
        begin
            average = 7;
            for (i = 3; i < 1024 - 3; i = i + 1) begin
                temp_data [i] = (count [i - 3] + count [i - 2] + count [i - 1] + count [i] + count [i + 1] + count [i + 2] + count [i + 3]) / average;
            end
            for(i = 3; i < 1024 - 3; i = i + 1)
                count[i] = temp_data[i];
            moving_average = 0;
        end
    endfunction

    function [15:0] zero_find_peak;
        input [15:0] W;
        input [15:0] HL;
        input [15:0] HG;
        input [15:0] percent;
        input [15:0] threshold;
        reg [15:0] peak_count;
        begin
            
        end
    endfunction

    function [15:0] find_peak;
        input [15:0] flag;
        reg [15:0] peak_count;
        begin
            peak_count = 0;
            for (i = 1; i < 1023 - 1; i = i + 1) begin
                if(count[i] > count[i - 1] && count[i] > count[i + 1] && count[i] > count_sum/2)
                begin
                    peak[peak_count] = i;
                    peak_count = peak_count + 1;
                end
            end
            find_peak = peak_count;
        end
    endfunction

    reg [31:0] temp;
    reg [31:0] randomCount;
    always @(posedge clk) begin
        if(rst == 1) begin
            randomCount = 1000;//$random %10;
            for(i = 0; i < randomCount; i = i + 1)
            begin
                temp = get_index_for_data($random % sum);
                count[temp] = count[temp] + 1;
            end
        end
    end

    integer fd ;
    initial begin
        //$dumpfile("MCA.vcd");
        //$dumpvars(0, MCA);

        $readmemh("Co.hex", Co_data);
        Co_data_size = 1024;
        randomCount = 0;
        sum = 0;
        con = 0;
        flag = 0;
        peak_count = 0;
        count_sum = 0;
        for (i = 0; i < 1024; i = i + 1) begin
            Co_data_sum[i] = 0;
            count[i] = 0;
            peak[i] = 0;
            zero_peak[i] = 0;
        end
        
        for (i = 0; i < 1024; i = i + 1) begin
            if(i>0)
                Co_data_sum[i] = Co_data_sum[i-1] + Co_data[i];
            else
                Co_data_sum[i] = 0 + Co_data[0];
            sum = sum + Co_data[i];
            //$display("Co_data_sum[%d] = %d",i, Co_data_sum);
        end
        $display("sum = %d", sum);
        rst = 1;
        
        #(3000);
        rst = 0;
        for (k = 0; k < 1024; k = k + 1) begin
            count_sum = count_sum + count[k];
            //$display("count[%d] = %d", k, count[k]);
        end
        rst = moving_average(0);
        peak_count = find_peak(0);

        $display("peak_count = %d", peak_count);

        // 写入文件
        fd = $fopen("./out.hex", "w");
        for (k = 0; k < 1024; k = k + 1) begin
            $fwrite(fd, "%d\n", count[k]);
        end
        $fclose(fd);
        $display("count_sum = %d", count_sum);

        fd = $fopen("./peak.hex", "w");
        for (k = 0; k < peak_count; k = k + 1) begin
            $fwrite(fd, "%d\n", peak[k]);
        end
        $fclose(fd);

        $finish;
    end



endmodule;