library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity logic is
	port(
		clk:in std_logic;
		request_pos_x:in std_logic_vector(9 downto 0);
		request_pos_y:in std_logic_vector(9 downto 0);
		key0:in std_logic_vector(7 downto 0);
		key1:in std_logic_vector(7 downto 0);
		res_red:out std_logic_vector(2 downto 0);
		res_green:out std_logic_vector(2 downto 0);
		res_blue:out std_logic_vector(2 downto 0)
	);
end entity logic;
architecture behave of logic is
begin
process(clk)
begin
	if clk'event and clk='1' then
		if request_pos_x>=640 or request_pos_y>=480 then
			res_green<="000";
			res_blue<="000";
			res_red<="000";
		elsif request_pos_y>=360 then
			if request_pos_x>=480 then
				if key0(0)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=320 then
				if key0(1)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=160 then
				if key0(2)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			else
				if key0(3)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			end if;
		elsif request_pos_y>=240 then
			if request_pos_x>=480 then
				if key0(4)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=320 then
				if key0(5)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=160 then
				if key0(6)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			else
				if key0(7)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			end if;
		elsif request_pos_y>=120 then
			if request_pos_x>=480 then
				if key1(0)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=320 then
				if key1(1)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=160 then
				if key1(2)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			else
				if key1(3)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			end if;
		else
			if request_pos_x>=480 then
				if key1(4)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=320 then
				if key1(5)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			elsif request_pos_x>=160 then
				if key1(6)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			else
				if key1(7)='1' then
					res_green<="111";
					res_red<="000";
					res_blue<="000";
				else
					res_green<="000";
					res_red<="000";
					res_blue<="000";
				end if;
			end if;
		end if;	
	end if;
end process;
end architecture behave;