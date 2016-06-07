library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity logic is
port
(
	key0:in std_logic_vector(7 downto 0);
	key1:in std_logic_vector(7 downto 0);
	sram_address:out std_logic_vector(20 downto 0);
	sram_CE,sram_OE,sram_WE:out std_logic;
	sram_data:inout std_logic_vector(31 downto 0);
	request_pos_x,request_pos_y:in std_logic_vector(9 downto 0);	--询问的位置坐标x,y
	clk1:in std_logic;	--100MHz，询问的触发信号用25MHz，自行分频，上升沿时罗干写入当前颜色的值，下降沿时杜家驹读取颜色并把像素+1，读取颜色的触发信号用100MHz，因为一个像素的颜色可能要读多次（这里设计3次最多）
	res_red,res_green,res_blue:out std_logic_vector(2 downto 0)	--颜色的值
);
end logic;

architecture bhv of logic is
type pos_info is array(0 to 39) of std_logic_vector(7 downto 0);
type image_length is array(0 to 27) of integer range 0 to 1023;
type image_address is array(0 to 27) of integer range 0 to 524287;
type index0 is array(0 to 7) of integer range 0 to 1023;
type index1 is array(0 to 7) of integer range 0 to 63;
signal pos_color,pos_color_temp:pos_info;	--保存一轮的位置颜色的结果
signal deal_line,deal_x:integer:=0;	--当前所处理的行和起始列
signal background_pos_x,background_pos_y:integer;	--这一轮背景的位置
--存在的物体的中心坐标，背景另外处理
signal object_pos_x: index0:=(0,300, 500, 0,600,0,249,249);
signal object_pos_y: index0:= (0,300, 300,0,0,0,212,212);
--存在的物体左右翻转情况
signal object_reverse: std_logic_vector(0 to 7):= "01000000";
signal object_used: std_logic_vector(0 to 7):= "00000100";
signal p2_hp:integer range 0 to 255 := 200;	--双方的血量
signal p1_hp:integer range 0 to 255 := 200;	--双方的血量
signal object_number:index1:=(0,1,12,23,24,25,26,27);	--存在的物体编号

signal object_pos_x_temp:index0;
signal object_pos_y_temp:index0;
signal object_reverse_temp,object_used_temp:std_logic_vector(0 to 7):="00000000";
signal object_number_temp:index1;
signal start_x_sig,pos_temp:integer;	--像素起始位置
signal isrotate_sig:boolean:=false;	--像素是否翻转
signal x0_sig,y0_sig:integer:=0;
signal ss_sig:integer range 0 to 4:=0;
signal choose_sig:integer range 0 to 63;
constant image_n:image_length:=(960,160,160,103,225,228,89,205,253,249,183,177,118,122,118,138,226,159,148,238,237,152,159,40,40,640,142,142);
constant image_m:image_length:=(480,218,218,230,225,230,322,177,109,190,194,221,223,238,234,240,218,206,156,108,204,209,159,40,40,480,56,56);
constant center_n:image_length:=(0,80,80,51,112,114,44,102,126,124,91,88,59,61,59,69,113,79,74,119,118,76,79,0,0,0,0,0);
constant center_m:image_length:=(0,109,109,121,116,121,213,68,0,81,85,112,113,128,124,130,108,96,46,0,94,99,49,0,0,0,0,0);
--	constant address_store:image_address:=(0,115200,123920,132640,138563,151220,164330,171495,180567,187462,199290,208166,217946,224525,
--	231784,238687,246967,259284,267473,273245,279671,291758,299700,306021,306421,306821,383621,385609);
constant address_store:image_address:=(0,122880,136832,150784,158144,172544,187264,197568,208896,215872,228032,240448,
254592,261728,269344,276832,292192,306144,319328,329312,336224,349280,362656,372832,373472,374112,496992,500576);
constant address_n:image_length:=(1024,256,256,128,256,256,128,256,256,256,256,256,128,128,128,256,256,256,256,256,256,256,256,64,64,1024,256,256);

type status is (stop, walk, attack, kick, jump, defend, squat, skill, fall, stiff);
constant PICNUM: integer:= 11;
constant LOWPOS: integer:= 300;
constant HIGHPOS: integer:= 100;
constant ATTRANGE: integer:= 100;
signal s0,s1: status:= stop;
signal scnt0,scnt1 : integer:= 0;--0 1-4 5-7
signal fallcnt0, fallcnt1 : integer:= 0;
signal clk,clk50,clk25 : std_logic;
signal beginned: boolean := false;
begin
	sram_CE<='0';	--保持读的状态
	sram_OE<='0';
	sram_WE<='1';
	
	process (clk1)
	begin
		if clk1'event and clk1='1' then
			clk50<=not clk50;
		end if;
	end process;
	process (clk50)
	begin
		if clk50'event and clk50='1' then
			clk25<=not clk25;
		end if;
	end process;
--	 

	 process (clk1, key0(0))
    variable f0,f1: status;
	 variable kkey0 : std_logic_vector(7 downto 0);
	 variable cnt0,cnt1:integer:=0;
    begin
	 		if(not beginned)then
		   if(key0(0) = '1')then
			  beginned<= true;
--			  object_used(1 to 4) <= "1111";
--			  object_used(5 to 7) <= "000";
--			  p1_hp <= 200;
--			  p2_hp <= 200;
			end if;
		elsif(clk1'event and clk1 = '0' )then
				if cnt0>=10000000 then
					cnt0:=0;
				if beginned then
					if object_used(5) = '1' or object_used(6)  = '1' or object_used(7) = '1' then
					  object_used(1 to 4) <= "1111";
					  object_used(5 to 7) <= "000";
					  p1_hp <= 200;
					  p2_hp <= 200;
					else
--初次判定本回合动作
					kkey0 := key0;
               if(kkey0(1) = '1') then
						f0 := jump;
					elsif kkey0(2) = '1' then
                  f0 := squat;
               elsif kkey0(3) = '1' then
                  f0 := walk;
               elsif kkey0(4) = '1' then
                  f0 := walk;
               elsif kkey0(5) = '1' then
                  f0 := attack;
               elsif kkey0(6) = '1' then
                  f0 := kick;
               elsif kkey0(7) = '1' then
                  f0 := defend;
               elsif s0 = fall then
						f0 := fall;
					else
						f0 := stop;
               end if;
--攻击间隔
					if ((s0 = attack) and (f0 = attack))or((f0 = kick)and(s0 = kick)) then
						f0 := stop;
					end if;
--跳起还没落下时不能再跳
					if (object_pos_y(1) < LOWPOS) and (f0 = jump) then
						f0 := stop;
					end if;
--解除硬直
					if s0 = stiff then
						f0 := stop;
					end if;
--技能1释放
					if(scnt0 > 4) and (f0 = attack) then 
						f0 := skill;
					end if;
----------------------------------------------------------------------------------        
        --初次判定本回合动作
               if(key1(1) = '1') then
						f1 := jump;
               elsif key1(2) = '1' then
						f1 := squat;
					elsif key1(3) = '1' then
						f1 := walk;
					elsif key1(4) = '1' then
						f1 := walk;
					elsif key1(5) = '1' then
						f1 := attack;
					elsif key1(6) = '1' then
						f1 := kick;
					elsif key1(7) = '1' then
						f1 := defend;
					elsif s1 = fall then
						f1 := fall;
					else f1 := stop;
					end if;
--攻击间隔      
					if ((s1 = attack) and (f1 = attack))or((f1 = kick)and(s1 = kick)) then
						f1 := stop;
					end if;
--跳起还没落下时不能再跳
					if (object_pos_y(2) < LOWPOS) and (f1 = jump) then
						f1 := stop;
					end if;
--解除硬直
					if s1 = stiff then
						f1 := stop;
					end if;
--技能1释放
					if(scnt1 > 4) and (f1 = attack) then 
						f1 := skill;
					end if;
------------------------------------------------------------------------------------        
----战斗判定
					if(((object_pos_x(1) > object_pos_x(2))and (object_pos_x(1) - object_pos_x(2) < ATTRANGE))
					or((object_pos_x(1) < object_pos_x(2))and(object_pos_x(2) - object_pos_x(1) < ATTRANGE)))then 
						if (f1 = skill) then 
							f0 := stiff;
						if p1_hp > 20 then
							p1_hp <= p1_hp - 20;
						else
							object_used(7) <= '1';
							beginned <= false;
						end if;
						elsif (f0 = skill) then
							f1 := stiff;
							if p2_hp > 20 then
								p2_hp <= p2_hp - 20;
							else
								object_used(6) <= '1';
								beginned <= false;
							end if;            
						elsif(f0 = attack)then
							if(f1 = defend)then
								if p2_hp > 4 then
									p2_hp <= p2_hp - 4;
								else
									object_used(6) <= '1';
									beginned <= false;
								end if;           
							elsif(f1 /= fall) and (f1 /= squat)then
								f1 := stiff;
								if p2_hp > 8 then
									p2_hp <= p2_hp - 8;
								else
									object_used(6) <= '1';
									beginned <= false;
								end if;                 
							end if;
						elsif (f0 = kick) and (object_pos_y(2) = LOWPOS) then
							if(f1 = defend) then
								if p2_hp > 4 then
									p2_hp <= p2_hp - 4;
								else
									object_used(6) <= '1';
									beginned <= false;
								end if;
							elsif (f1 /= fall)then
								f1 := stiff;
								if p2_hp > 8 then
									p2_hp <= p2_hp - 8;
								else
									object_used(6) <= '1';
									beginned <= false;
								end if;
							end if;
						elsif (f1 = attack)then             
							if(f0 = defend)then
								if p1_hp > 4 then
									p1_hp <= p1_hp - 4;
								else
									object_used(7) <= '1';
									beginned <= false;
								end if;                
							elsif(f0 /= fall) and (f0 /= squat)then
								f0 := stiff;
								if p1_hp > 8 then
									p1_hp <= p1_hp - 8;
								else
									object_used(7) <= '1';
									beginned <= false;
								end if;                
							end if;
						elsif (f1 = kick) and (object_pos_y(1) = LOWPOS) then
							if(f0 = defend) then
								if p1_hp > 4 then
									p1_hp <= p1_hp - 4;
								else
									object_used(7) <= '1';
									beginned <= false;
								end if;
							elsif (f0 /= fall)then
								f0 := stiff;
								if p1_hp > 8 then
									p1_hp <= p1_hp - 8;
								else
									object_used(7) <= '1';
									beginned <= false;
								end if;               
							end if;
						end if;
					end if;
        
------走判定
					if(f0 = walk)and(key0(3) = '1')then
						if(object_pos_x(1) < 20)then
							 object_pos_x(1) <= 0;
						else object_pos_x(1) <= object_pos_x(1) - 20;
						end if;
						
					elsif(f0 = walk)and(key0(4) = '1')then
						if(object_pos_x(1) >= 940)then
							 object_pos_x(1) <= 959;
						else object_pos_x(1) <= object_pos_x(1) + 20;
						end if;
					end if;
				  
					if(f1 = walk)and(key1(3) = '1')then
						if(object_pos_x(2) < 20)then
							 object_pos_x(2) <= 0;
						else object_pos_x(2) <= object_pos_x(2) - 20;
						end if;
					elsif(f1 = walk)and(key1(4) = '1')then
						if(object_pos_x(2) >= 940)then
							 object_pos_x(2) <= 959;
						else object_pos_x(2) <= object_pos_x(2) + 20;
						end if;
					end if;
------技能判定
					if(f0 = skill)then
						scnt0 <= 0;
					elsif(scnt0 = 0)then
					   if(f0 = squat) then
							scnt0 <= 1;
						else scnt0 <= 0;
						end if;
    --下
					elsif(scnt0 > 0)and(scnt0 <= 4)then
						if(f0 = walk)then 
							scnt0 <= 5;
						elsif(f0 = stop) and (scnt0 < 4)then
							scnt0 <= scnt0 + 1;
						else scnt0 <= 0;
						end if;
    --走
					elsif(scnt0 > 4) and (scnt0 < 7)then
						scnt0 <= scnt0 + 1;
    --之后等几回合
					else scnt0 <= 0;
				end if;
--------------------------------------------------
				if(f1 = skill)then
					scnt1 <= 0;
				elsif(scnt1 = 0)then
				   if f1 = squat then
						scnt1 <= 1;
					else scnt1 <= 0;
					end if;
				elsif(scnt1 > 0)and(scnt1 <= 4)then
					if(f1 = walk)then 
						scnt1 <= 5;
					elsif(f1 = stop) and (scnt1 < 4)then
						scnt1 <= scnt1 + 1;
					else scnt1 <= 0;
					end if;
				elsif(scnt1 > 4) and (scnt1 < 7)then
					scnt1 <= scnt1 + 1;
				else scnt1 <= 0;
				end if;
	 
----------------------------------------
				if(f0 = stiff)then
					if(fallcnt0 >= 3)then 
						fallcnt0 <= 0;
						f0 := fall;
					elsif(fallcnt0 < 3)then
						fallcnt0 <= fallcnt0 + 1;
					end if;
				elsif(f0 /= stop)then fallcnt0 <= 0;
				end if;
    
				if(f1 = stiff)then
					if(fallcnt1 >= 3)then 
						fallcnt1 <= 0;
						f1 := fall;
					elsif(fallcnt1 < 3)then
						fallcnt1 <= fallcnt1 + 1;
					end if;
				elsif(f1 /= stop)then fallcnt1 <= 0;
				end if;
----图片编号    
				if(f0 = stop)then
					if(object_pos_y(1) < LOWPOS)then
						object_number(1) <= 6;
					else
						object_number(1) <= 1;
					end if;
				elsif (f0 = walk) then
					if(object_number(1) = 3)then
						object_number(1) <= 2;
					else object_number(1) <= 3;
					end if;
				elsif (f0 = attack) then
					object_number(1) <= 4;
				elsif (f0 = kick) then
					object_number(1) <= 5;
				elsif (f0 = jump) then
					object_number(1) <= 6;
				elsif (f0 = squat) then
					object_number(1) <= 7;
				elsif (f0 = fall) then
					object_number(1) <= 8;
				elsif (f0 = skill) then
					object_number(1) <= 9;
				elsif (f0 = defend)then
					object_number(1) <= 10;
				elsif (f0 = stiff)then
					object_number(1) <= 11;
				else object_number(1) <= 4;
				end if;
------------------------------------
				if(f1 = stop)then
					if(object_pos_y(2) < LOWPOS)then
						object_number(2) <= PICNUM + 6;
					else
						object_number(2) <= PICNUM + 1;
					end if;
				elsif (f1 = walk) then
					if(object_number(2) = PICNUM + 3)then
						object_number(2) <= PICNUM + 2;
					else object_number(2) <= PICNUM + 3;
					end if;
				elsif (f1 = attack) then
					object_number(2) <= PICNUM + 4;
				elsif (f1 = kick) then
					object_number(2) <= PICNUM + 5;
				elsif (f1 = jump) then
					object_number(2) <= PICNUM + 6;
				elsif (f1 = squat) then
					object_number(2) <= PICNUM + 7;
				elsif (f1 = fall) then
					object_number(2) <= PICNUM + 8;
				elsif (f1 = skill) then
				object_number(2) <= PICNUM + 9;
				elsif (f1 = defend)then
					object_number(2) <= PICNUM + 10;
				elsif (f1 = stiff)then
					object_number(2) <= PICNUM + 11;
				else object_number(2) <= PICNUM + 4;
				end if;

--本回合状态赋值
				s0 <= f0;
				s1 <= f1;			
		end if;
		end if;
			else
				cnt0:=cnt0+1;
		end if;
		if cnt1>=1000000 then
			cnt1:=0;
			if(s0 = jump and object_pos_y(1) > HIGHPOS)then
				object_pos_y(1) <= object_pos_y(1) - 8;
			elsif(object_pos_y(1) < LOWPOS)then
				object_pos_y(1) <= object_pos_y(1) + 2;
			else object_pos_y(1) <= LOWPOS;
			end if;
			if(s1 = jump  and object_pos_y(2) > HIGHPOS)then
				object_pos_y(2) <= object_pos_y(2) - 8;
			elsif(object_pos_y(2) < LOWPOS)then
				object_pos_y(2) <= object_pos_y(2) + 2;
			else object_pos_y(2) <= LOWPOS;
			end if; 
				--走向判定
			if(object_pos_x(1) <= object_pos_x(2))then
				object_reverse(1) <= '1';
				object_reverse(2) <= '0';
			else
				object_reverse(1) <= '0';
				object_reverse(2) <= '1';
			end if;

		else
			cnt1:=cnt1+1;
		end if;
	end if;
end process;
--测试
--	process (clk1)
--	variable dd:integer:=0;
--	variable cc:integer range 0 to 15;
--	begin
--		if clk1'event and clk1='1' then
--			if dd=3000000 then
--				dd:=0;
--				cc:=cc+1;
--				if cc=10 then
--					cc:=0;
--				end if;
--				object_pos_x(1)<=321+cc*10;
--				object_pos_x(2)<=601+cc*10;
--				object_pos_y(1)<=100-cc;
--				object_pos_y(2)<=260+cc;
--				object_number(1)<=1+cc;
--				object_number(2)<=12+cc;
--				object_reverse(1)<='1';
--				object_reverse(2)<='0';
--				object_used(1)<='1';
--				object_used(2)<='1';
--				p1_hp<=150-cc*10;
--				p2_hp<=130+cc*10;
--			else
--				dd:=dd+1;
--			end if;
--		end if;
--	end process;
	
	process (clk1)
	variable divide:integer range 0 to 3:=0;
	variable x0,y0,x1,y1:integer range 0 to 1023;
	variable last_xx:integer range 0 to 1023:=0;
	variable temp_red,temp_green,temp_blue:std_logic_vector(2 downto 0);
	begin
		if clk1'event and clk1='1' then
			if divide=3 then
				divide:=0;
				temp_red:="111";
				temp_green:="111";
				temp_blue:="111";
				x0:=conv_integer(request_pos_x);
				y0:=conv_integer(request_pos_y);
				x1:=x0-last_xx;
				if x0<640 and y0<480 and pos_color(x1)/="11110011" then
					temp_red:=pos_color(x1)(7 downto 5);
					temp_green:=pos_color(x1)(4 downto 2);
					temp_blue:=pos_color(x1)(1 downto 0) & "0";
				end if;
				if y0>=20 and y0<40 and object_used_temp(1)='1' and object_used_temp(2)='1' then
					if (x0>=50 and x0<50+p1_hp) or (x0<590 and x0>=590-p2_hp) then
						temp_red:="111";
						temp_green:="000";
						temp_blue:="000";
					end if;
				end if;
				if x0<640 and y0<480 then
					res_red<=temp_red;
					res_green<=temp_green;
					res_blue<=temp_blue;
				else
					res_red<="000";
					res_green<="000";
					res_blue<="000";
				end if;
				if x0=640 and y0=480 then
					object_number_temp<=object_number;
					object_pos_x_temp<=object_pos_x;
					object_pos_y_temp<=object_pos_y;
					object_reverse_temp<=object_reverse;
					object_used_temp<=object_used;
					if object_used_temp(1)='1' and object_used_temp(2)='1' then
						x1:=(object_pos_x(1)+object_pos_x(2))/2;
						if x1<320 then
							x1:=320;
						end if;
						if x1>640 then
							x1:=640;
						end if;
						x1:=x1-320;
						y1:=0;
						object_used_temp(0)<='1';
						background_pos_x<=x1;
						background_pos_y<=y1;
					else
						object_used_temp(0)<='0';
						background_pos_x<=0;
						background_pos_y<=0;
					end if;
				end if;
				if x0<640 and y0<480 then
					if x0=39 or x0=79 or x0=119 or x0=159 or x0=199 or x0=239 or x0=279 or x0=319 or x0=359 or x0=399 or x0=439 or x0=479 or x0=519 or x0=559 then
						last_xx:=x0+1;
						pos_color<=pos_color_temp;
						deal_line<=y0;
						deal_x<=x0+41;
					elsif x0=599 then
						last_xx:=600;
						pos_color<=pos_color_temp;
						deal_x<=0;
						if y0<479 then
							deal_line<=y0+1;
						else
							deal_line<=0;
						end if;
					elsif x0=639 then
						last_xx:=0;
						pos_color<=pos_color_temp;
						deal_x<=40;
						if y0<479 then
							deal_line<=y0+1;
						else
							deal_line<=0;
						end if;
					end if;
				end if;
			else
				divide:=divide+1;
			end if;
		end if;
	end process;
	process (clk1)
	variable dd:integer range 0 to 3:=0;
	variable last_line:integer:=1023;
	variable last_x:integer:=0;
	variable start_x:integer:=0;
	variable address:integer range 0 to 524287;	--地址位置
	variable deal:integer range -1 to 14:=-1;	--之前做到的物体编号
	variable delta,x0,y0,xl,xr,xx,add:integer;	--分别是询问的位置，对于一个物体的相对位置，转成一维的位置，地址需在起始地址的基础上的增量
	variable mo:integer range 0 to 3:=0;	--起始颜色位置
	variable ss:integer range 0 to 4:=0;	--颜色个数
	variable choose,z:integer range 0 to 63;
	variable p,isrotate:boolean;
	begin
		if clk1'event and clk1='0' then
			if dd=3 then
				dd:=0;
				if deal_line/=last_line or deal_x/=last_x then
					for i in 0 to 39 loop
						pos_color_temp(i)<="11110011";
					end loop;
					deal:=-1;
					last_line:=deal_line;
					last_x:=deal_x;
				else
					p:=true;
					for i in 0 to 7 loop
						if i>=deal and p and object_used_temp(i)='1' then
							choose:=object_number_temp(i);
							if choose<23 then
								xl:=deal_x+background_pos_x-object_pos_x_temp(i)+center_n(choose);
								xr:=deal_x+39+background_pos_x-object_pos_x_temp(i)+center_n(choose);
							else
								xl:=deal_x-object_pos_x_temp(i)+center_n(choose);
								xr:=deal_x+39-object_pos_x_temp(i)+center_n(choose);
							end if;
							xx:=xl;
							delta:=39;
							if xl<0 then
								xl:=0;
							end if;
							if xr>=image_n(choose) then
								xr:=image_n(choose)-1;
							end if;
							if xl<=xr then
								if object_reverse_temp(i)='1' then
									xx:=image_n(choose)-xl-1;
									xl:=image_n(choose)-xr-1;
									xr:=xx;
									xx:=xl;
									if xl=0 then
										delta:=xr-xl;
									end if;
								end if;
								if i>deal then
									x0:=0;
								else
									x0:=x0+ss;
								end if;
								if x0<xl then
									x0:=xl;
								end if;
								if x0>xr then
									x0:=image_n(choose);
								end if;
								y0:=deal_line-object_pos_y_temp(i)+center_m(choose);
								if x0<image_n(choose) and y0>=0 and y0<image_m(choose) then
									deal:=i;
									p:=false;
									ss_sig<=4;
									if xr-x0+1<4 then
										ss_sig<=xr-x0+1;
									end if;
									if object_reverse_temp(i)='1' then
										isrotate_sig<=true;
										start_x_sig<=delta-(x0-xx);
									else 
										isrotate_sig<=false;
										start_x_sig<=x0-xx;
									end if;
									x0_sig<=x0;
									y0_sig<=y0;
									choose_sig<=choose;
								end if;
							end if;
						end if;
					end loop;
					if p then
						deal:=11;
						ss_sig<=0;
					end if;
				end if;
			elsif dd=0 then
				dd:=1;
				pos_temp<=y0_sig*address_n(choose_sig)+x0_sig;
			elsif dd=1 then
				dd:=2;
				for i in 1 to 4 loop
					if i<=ss then
						z:=39-(i+mo)*8;
						if sram_data(z downto z-7)/="11110011" then
							if isrotate then
								pos_color_temp(start_x-i+1)<=sram_data(z downto z-7);
							else
								pos_color_temp(start_x+i-1)<=sram_data(z downto z-7);
							end if;
						end if;
					end if;
				end loop;
				start_x:=start_x_sig;
				isrotate:=isrotate_sig;
				ss:=ss_sig;
				add:=pos_temp/4;
				mo:=pos_temp-add*4;
				if 4-mo<ss then
					ss:=4-mo;
				end if;
				address:=address_store(choose_sig)+add;
				sram_address<="00" & conv_std_logic_vector(address,19);
				sram_data<=(others=>'Z');
			else
				dd:=3;
			end if;
		end if;
	end process;

end bhv;