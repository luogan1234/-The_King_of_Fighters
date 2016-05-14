library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

entity color_handle is
port
(
	sram_address:out std_logic_vector(20 downto 0);
	sram_CE,sram_OE,sram_WE:out std_logic;
	sram_data:inout std_logic_vector(31 downto 0);
	request_pos_x,request_pos_y:in std_logic_vector(9 downto 0);	--询问的位置坐标x,y
	clk1:in std_logic;	--50MHz，询问的触发信号用12.5MHz，自行分频，上升沿时罗干写入当前颜色的值，下降沿时杜家驹读取颜色并把像素+1，读取颜色的触发信号用50MHz，因为一个像素的颜色可能要读多次（这里设计3次最多）
	res_red,res_green,res_blue:out std_logic_vector(2 downto 0)	--颜色的值
);
end color_handle;

architecture bhv of color_handle is
type matrix_index0 is array(0 to 15) of std_logic_vector(2 downto 0);
type matrix_index1 is array(0 to 63) of integer range 0 to 1023;
type matrix_index2 is array(0 to 63) of std_logic_vector(18 downto 0);
type matrix_index3 is array(0 to 2) of std_logic_vector(2 downto 0);
type matrix_index4 is array(0 to 15) of integer range 0 to 1023;
type matrix_index5 is array(0 to 15) of integer range 0 to 63;
type matrix_index6 is array(0 to 15) of boolean;
signal pos_red,pos_green,pos_blue:matrix_index0;	--保存位置颜色的结果
signal image_n,image_m:matrix_index1;	--图像长宽
signal address_store:matrix_index2;	--图像存储的第一个像素的地址
signal exist_object_num:integer range 0 to 15;	--存在的物体数量
signal exist_object_pos_x,exist_object_pos_y:matrix_index4;	--存在的物体坐标，0号需要是背景，位置为0，0，不翻转，坐标是物体的左上角坐标
signal exist_object_number:matrix_index5;	--存在的物体编号
signal exist_object_reverse:matrix_index6;	--存在的物体左右翻转情况
begin
	process (clk1)
	variable stats:integer range 0 to 3:=0;  --对应初始化，准备读取状态，读取状态，完成状态
	variable pic:integer range 0 to 63:=0;	--图片编号
	variable pic_n,pic_m,pic_x,pic_y:integer range 0 to 1023;	--图片
	variable num:integer range 0 to 3;	--三个像素一组
	variable divide:integer range 0 to 3:=0;	--4分频用，写入时、保存结果时需要
	variable temp:integer;	--暂存读入的数
	variable red_in,green_in,blue_in:matrix_index3;	--三个像素一组缓存
	variable address:std_logic_vector(18 downto 0);	--地址位置
	variable x,y,x1,y1,pos_temp,add:integer;	--分别是询问的位置，对于一个物体的相对位置，转成一维的位置，地址需在起始地址的基础上的增量
	variable mo:integer range 0 to 2;	--三个像素的哪个
	variable z:integer range 0 to 31:=8;	--上一次询问的结果所在像素
	variable tt,tt2:integer range -1 to 126;
	file file_in:text;
	variable fstatus:file_open_status;
	variable line_in:line;
	constant TOTALPICTURE:integer range 0 to 63:=2;
	begin
		if clk1'event and clk1='1' then
			case stats is
			when 0=>
				res_red<="000";
				res_green<="000";
				res_blue<="000";
				stats:=1;
				sram_data<=(others=>'Z');
				address:=(others=>'0');
				file_open(fstatus,file_in ,"./picture.txt",read_mode);
			when 1=>
				sram_CE<='1';	--等待状态
				sram_OE<='0';
				sram_WE<='1';
				if pic<TOTALPICTURE then
					pic_x:=0;
					pic_y:=0;
					stats:=2;
					readline(file_in,line_in);
					read(line_in,temp);
					pic_m:=conv_integer(conv_std_logic_vector(temp,10));
					readline(file_in,line_in);
					read(line_in,temp);
					pic_n:=conv_integer(conv_std_logic_vector(temp,10));
					address_store(pic)<=address;
					image_n(pic)<=pic_n;
					image_m(pic)<=pic_m;
					num:=0;
				else
					stats:=3;
					divide:=3;
					file_close(file_in);
					sram_CE<='0';	--进入读状态
					sram_OE<='0';
					sram_WE<='1';
				end if;
			when 2=>
				if divide<3 then
					divide:=divide+1;
				else
					divide:=0;
					if pic_x<pic_n or pic_y<pic_m then
						readline(file_in,line_in);
						read(line_in,temp);
						red_in(num):=conv_std_logic_vector(temp,3);
						readline(file_in,line_in);
						read(line_in,temp);
						green_in(num):=conv_std_logic_vector(temp,3);
						readline(file_in,line_in);
						read(line_in,temp);
						blue_in(num):=conv_std_logic_vector(temp,3);
						num:=num+1;
						if pic_y<pic_m then
							pic_y:=pic_y+1;
						else
							pic_y:=0;
							pic_x:=pic_x+1;
						end if;
					else
						stats:=1;
						if num>0 then
							num:=3;
						end if;
						if pic<TOTALPICTURE then
							pic:=pic+1;
						end if;
					end if;
					if num=3 then
						num:=0;
						sram_CE<='0';	--写状态
						sram_OE<='0';
						sram_WE<='0';
						sram_address<="00" & address;
						sram_data<="00000" & red_in(2) & green_in(2) & blue_in(2) & red_in(1) & green_in(1) & blue_in(1) & red_in(0) & green_in(0) & blue_in(0);
						address:=address+1;
					else
						sram_CE<='1';	--等待状态
						sram_OE<='0';
						sram_WE<='1';
					end if;
				end if;
			when 3=>
				if divide=3 then
					divide:=0;
					res_red<=pos_red(0);
					res_green<=pos_green(0);
					res_blue<=pos_blue(0);
					for i in 1 to exist_object_num loop	--计算颜色
						if pos_red(i)/="000" or pos_green(i)/="000" or pos_blue(i)/="000" then
							res_red<=pos_red(i);
							res_green<=pos_green(i);
							res_blue<=pos_blue(i);
						end if;
					end loop;
					if request_pos_y=479 then	--先计算下一个点颜色
						x:=0;
						if request_pos_x<639 then
							y:=conv_integer(request_pos_y)+1;
						else
							y:=0;
						end if;
					else
						x:=conv_integer(request_pos_x);
						y:=conv_integer(request_pos_y)+1;
					end if;
					tt:=-1;
				else
					divide:=divide+1;
				end if;
				if tt<=exist_object_num then
					if tt>-1 then
						tt:=0;
						pos_red(tt)<=sram_data(z downto z-2);
						pos_green(tt)<=sram_data(z-3 downto z-5);
						pos_blue(tt)<=sram_data(z-6 downto z-8);
					end if;
				end if;
				tt2:=tt;
				for i in 0 to exist_object_num loop
					if i>tt2 and tt2=tt then
						if x>=exist_object_pos_x(i) and x<exist_object_pos_x(i)+image_n(i) and y>=exist_object_pos_y(i) and y<exist_object_pos_y(i)+image_m(i) then
							y1:=y-exist_object_pos_y(i);
							if exist_object_reverse(i)=true then
								x1:=exist_object_pos_x(i)+image_n(i)-x-1;
							else
								x1:=x-exist_object_pos_x(i);
							end if;
							pos_temp:=y1*image_n(i)+x1;
							add:=pos_temp/3;
							mo:=pos_temp-add*3;
							address:=address_store(i)+add;
							sram_address<="00" & address;
							z:=mo*9+8;
							tt:=i;
						else
							pos_red(i)<="000";
							pos_green(i)<="000";
							pos_blue(i)<="000";
						end if;
					end if;
				end loop;
				if tt2=tt then
					tt:=exist_object_num+1;
				end if;
			end case;
		end if;
	end process;
end bhv;