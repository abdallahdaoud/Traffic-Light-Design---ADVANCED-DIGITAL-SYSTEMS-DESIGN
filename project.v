module traffic_light(input clk, go, rst, output [1:0] highwaySignal1, highwaySignal2, farmSignal1, farmSignal2);
	wire [6:0] count; 
	counter CTR(go, rst, clk, count);
	controller CRL(clk, rst, count, highwaySignal1, highwaySignal2, farmSignal1, farmSignal2);
endmodule

module controller(input clk, rst, [6:0] count, output reg [1:0] highwaySignal1=2, highwaySignal2=2, farmSignal1=2, farmSignal2=2);
	reg [6:0] state [0:17] = '{1,3,33,35,45,47,48,50,65,67,72,74,84,86,87,89,104,107}; //ppears in any clk
	reg [4:0] s = 0;
	always@(posedge clk && count >= state[s] && rst == 0) begin
		if(s >= 6 && s < 14) begin
			if((s <= 7) || (s >= 10 && s <= 11)) farmSignal1++;
			farmSignal2++;
		end
		else begin
			if((s >= 0 && s <= 1) || (s >= 4 && s <= 5)) highwaySignal1++;
			if((s >= 0 && s <= 3) || (s >= 14)) highwaySignal2++;
		end
		if(s == 17) s=0; 
		else s++;
	end
endmodule

module counter(input go, rst, clk, output reg [6:0] count=0);
	always@(posedge clk) begin
		if(rst) count = 0; 
		else if(go) 
			if(count>=107) count=0;
			else count++;
	end
endmodule

module traffic_light_TB();
	reg clk=0;
	reg go=1, rst=0; 
	reg [7:0] expectedResult; reg [1:0] highwaySignal1; reg [1:0] highwaySignal2;
	reg [1:0] farmSignal1; reg [1:0] farmSignal2; reg [6:0] count;
	wire error;
	generate_test GT(clk, go, rst, count, expectedResult);
	traffic_light TL(clk, go, rst, highwaySignal1, highwaySignal2, farmSignal1, farmSignal2);
	analyzer AZ(clk, count, {highwaySignal1, highwaySignal2, farmSignal1, farmSignal2}, expectedResult, error);
	initial begin 
		repeat(216) begin //(107clk + 1)*2
			#500ms if(error) break; //500ms*2 = 1s 
			clk = ~clk; 
		end
		if(!error) begin
			rst=1; #500ms clk = ~clk; #500ms clk = ~clk; //test reset 
			rst=0; #500ms clk = ~clk; #500ms clk = ~clk;
		end
		if(!error) begin
			go=0; #500ms clk = ~clk; #500ms clk = ~clk;	//test go
			go=1; #500ms clk = ~clk; #500ms clk = ~clk;
		end
		if(!error) $monitor("fault free");
	end
endmodule

module generate_test(input reg clk, reg go, reg rst, output reg [6:0] count=0, reg [7:0] expectedResult);
	reg [6:0] state [0:17] = '{1,3,33,35,45,47,48,50,65,67,72,74,84,86,87,89,104,107};
	reg [4:0] s = 0;
	reg [7:0] results [0:17] = '{8'b10101010,8'b11111010,8'b00001010,8'b00011010,
		8'b00101010,8'b01101010,8'b10101010,8'b10101111,8'b10100000,8'b10100001,
		8'b10100010,8'b10100111,8'b10101000,8'b10101001,8'b10101010,8'b10111010,
		8'b10001010,8'b10011010};
	initial expectedResult = results[s];
	always@(posedge clk) begin
		if(rst) count=0;
		else if(go) begin
			count++;
			if(count >= state[s]) 
				if(s == 17) begin 
					s=0;
					count=0;
				end
				else s++;
			expectedResult = results[s];
		end
	end
endmodule

module analyzer(input clk, [6:0] count, reg [7:0] result, reg [7:0] expectedResult, output reg error = 0);
	always@(posedge clk or count == 0) begin
		#100ms;
		if(result !== expectedResult) begin  
			error = 1;
			$monitor("faulty when counter =%d\nresult = %b <and> expectedResult = %b", count, result, expectedResult);
		end
	end
endmodule																    