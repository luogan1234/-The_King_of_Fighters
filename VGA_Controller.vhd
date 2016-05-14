library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity vga_controller is
	port (
		vga_clk:out std_logic;
		hs,vs:out std_logic;		--行同步、场同步信号
		ored:out std_logic_vector (2 downto 0);
		ogreen:out std_logic_vector (2 downto 0);
		oblue:out std_logic_vector (2 downto 0);
		request_pos:out std_logic_vector(18 downto 0);
		pos_signal:out std_logic;
		res_red:in std_logic_vector(2 downto 0);
		res_green:in std_logic_vector(2 downto 0);
		res_blue:in std_logic_vector(2 downto 0);
		reset:in std_logic;
		clk_in:in std_logic			--100M时钟输入
	);		
end entity vga_controller;
architecture behave of vga_controller is
--vga
	signal clk:std_logic;
	signal rt,gt,bt:std_logic_vector(2 downto 0);
	signal hst,vst:std_logic;
	signal x:std_logic_vector(9 downto 0);		--X坐标
	signal y	:std_logic_vector(8 downto 0);		--Y坐标
begin
	vga_clk<=clk;
	pos_signal<=clk;
	process (clk_in)
	variable counter:integer:=0;
	begin
		if clk_in'event and clk_in = '1' then
			counter:=counter+1;
			if counter=2 then
				clk<=not clk;
				counter:=0;
			end if;
		end if;
	end process;
	process (clk, reset)--区间像素数（含消隐区）
	begin
		if reset='0' then
			x<=(others=>'0');
			y<=(others=>'0');
		elsif clk'event and clk='1' then
			if x=799 then
				x<=(others=>'0');
				if y=524 then
					y<=(others=>'0');
				else
					y<=y+1;
				end if;
			else
				x<=x+1;
			end if;
		end if;
	end process;
	process (clk, reset)	--行同步信号产生（同步宽度96，前沿16）
	begin
		if reset = '0' then
			hst <= '1';
		elsif clk'event and clk = '1' then
			if x >= 656 and x < 752 then
				hst <= '0';
			else
				hst <= '1';
			end if;
		end if;
	end process;
	process (clk, reset)	--场同步信号产生（同步宽度2，前沿10）
	begin
		if reset = '0' then
			vst <= '1';
		elsif clk'event and clk = '1' then
			if y >= 490 and y< 492 then
				vst <= '0';
			else
				vst <= '1';
			end if;
		end if;
	end process;
	process (clk, reset)--行同步信号输出
	begin
		if reset = '0' then
			hs <= '0';
		elsif clk'event and clk = '1' then
			hs <=  hst;
		end if;
	end process;
	process (clk, reset)--场同步信号输出
	begin
		if reset = '0' then
			vs <= '0';
		elsif clk'event and clk='1' then
			vs <=  vst;
		end if;
	end process;
	process(reset,clk,x,y)
	begin
		if reset='0' then
			request_pos<=(others=>'0');
		elsif clk'event and clk='1' then
			if x>=639 then
				request_pos(18 downto 9)<=(others=>'0');
				if y>=479 then
					request_pos(8 downto 0)<=(others=>'0');
				else
					request_pos(8 downto 0)<=y+1;
				end if;
			else
				request_pos(18 downto 9)<=(others=>'0');
			end if;
		end if;
	end process;
	process(reset,clk,x,y)  -- XY坐标定位控制
	begin  
		if reset='0' then
			rt<="000";
			gt<="000";
			bt<="000";	
		elsif clk'event and clk='1' then 
			rt<=res_red;
			gt<=res_green;
			bt<=res_blue;
		end if;		 
	end process;	
	process (hst,vst,rt,gt,bt)--色彩输出
	begin
		if hst = '1' and vst = '1' then
			ored	<= rt;
			ogreen	<= gt;
			oblue	<= bt;
		else
			ored<=(others=>'0');
			ogreen<=(others=>'0');
			oblue<=(others=>'0');
		end if;
	end process;
end behave;