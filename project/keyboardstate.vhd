---------------------------------------------------------------
--Contributor:杜家驹
--键盘信号处理，将scancode转换为每一个按键的状态
---------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity keyboardstate is
	port(
		clk:in std_logic;--100M时钟
		scancode:in std_logic_vector(7 downto 0);--键盘扫描码
		statusa:out std_logic_vector(7 downto 0);--人物A按键状态
		statusb:out std_logic_vector(7 downto 0)--人物B按键状态
	);
end keyboardstate;
architecture maps of keyboardstate is
signal internal:std_logic_vector(14 downto 0);
signal lastscancode:std_logic_vector(7 downto 0);
signal e0:std_logic;
begin
	process(clk)
	begin
		if clk'event and clk='1' then
			if scancode/=lastscancode then
				if lastscancode=240 then
					case scancode is
						when "00011101"=>internal(0)<='0';
						when "00011011"=>internal(1)<='0';
						when "00011100"=>internal(2)<='0';
						when "00100011"=>internal(3)<='0';
						when "00111011"=>internal(5)<='0';
						when "01000010"=>internal(6)<='0';
						when "00110011"=>internal(4)<='0';
						when "01110101"=>
							if e0='1' then
								internal(7)<='0';
							end if;
						when "01110010"=>
							if e0='1' then
								internal(8)<='0';
							else
								internal(12)<='0';
							end if;
						when "01101011"=>
							if e0='1' then
								internal(9)<='0';
							end if;
						when "01110100"=>
							if e0='1' then
								internal(10)<='0';
							end if;
						when "01101001"=>
							if e0='0' then
								internal(11)<='0';
							end if;
						when "01111010"=>
							if e0='0' then
								internal(13)<='0';
							end if;
						when "01011010"=>internal(14)<='0';
						when others=>
					end case;
					if scancode>0 then
						lastscancode<=scancode;
						e0<='0';
					end if;
				else
					case scancode is
						when "00011101"=>internal(0)<='1';
						when "00011011"=>internal(1)<='1';
						when "00011100"=>internal(2)<='1';
						when "00100011"=>internal(3)<='1';
						when "00111011"=>internal(5)<='1';
						when "01000010"=>internal(6)<='1';
						when "00110011"=>internal(4)<='1';
						when "01110101"=>
							if e0='1' then
								internal(7)<='1';
							end if;
						when "01110010"=>
							if e0='1' then
								internal(8)<='1';
							else
								internal(12)<='1';
							end if;
						when "01101011"=>
							if e0='1' then
								internal(9)<='1';
							end if;
						when "01110100"=>
							if e0='1' then
								internal(10)<='1';
							end if;
						when "01101001"=>
							if e0='0' then
								internal(11)<='1';
							end if;
						when "01111010"=>
							if e0='0' then
								internal(13)<='1';
							end if;
						when "01011010"=>internal(14)<='1';
						when others=>
					end case;
					lastscancode<=scancode;
					if scancode=224 then
						e0<='1';
					elsif scancode/=240 and scancode/=0 then
						e0<='0';
					end if;
				end if;
			end if;
		end if;
	end process;
	process(internal)
	begin
		statusa(7 downto 1)<=internal(6 downto 0);
		statusb(7 downto 1)<=internal(13 downto 7);
		statusa(0)<=internal(14);
		statusb(0)<=internal(14);
	end process;
end maps;