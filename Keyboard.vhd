---------------------------------------------------------------
--Contributor:杜家驹
--键盘信号处理，把PS/2键盘的信号转换为scancode
---------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity Keyboard is
port(
		keyboarddata:in std_logic;--键盘数据
		keyboardclk:in std_logic;--键盘时钟
		clk100m: in std_logic;--100M时钟
		rst : in std_logic; --reset
		scancode : out std_logic_vector(7 downto 0)--扫描码
	);
end Keyboard ;
architecture rtl of Keyboard is
type state_type is (delay, start, d0, d1, d2, d3, d4, d5, d6, d7, parity, stop, finish) ;
signal data,clk,clk1,clk2,odd,fok:std_logic;
signal code:std_logic_vector(7 downto 0); 
signal state:state_type;
begin
	clk1 <= keyboardclk when rising_edge(clk100m) ;
	clk2 <= clk1 when rising_edge(clk100m) ;
	clk <= (not clk1) and clk2 ;
	data <= keyboarddata when rising_edge(clk100m) ;
	odd <= code(0) xor code(1) xor code(2) xor code(3) xor code(4) xor code(5) xor code(6) xor code(7) ;
	process(fok)
	begin
		if fok='1' then
			scancode<=code;
		else
			scancode<="00000000";
		end if;
	end process;
	process(rst, clk100m)
	begin
		if rst = '0' then
			state <= delay ;
			code <= (others => '0') ;
			fok <= '0' ;
		elsif rising_edge(clk100m) then
			fok <= '0' ;
			case state is 
				when delay =>
					state <= start ;
				when start =>
					if clk = '1' then
						if data = '0' then
							state <= d0 ;
						else
							state <= delay ;
						end if ;
					end if ;
				when d0 =>
					if clk = '1' then
						code(0) <= data ;
						state <= d1 ;
					end if ;
				when d1 =>
					if clk = '1' then
						code(1) <= data ;
						state <= d2 ;
					end if ;
				when d2 =>
					if clk = '1' then
						code(2) <= data ;
						state <= d3 ;
					end if ;
				when d3 =>
					if clk = '1' then
						code(3) <= data ;
						state <= d4 ;
					end if ;
				when d4 =>
					if clk = '1' then
						code(4) <= data ;
						state <= d5 ;
					end if ;
				when d5 =>
					if clk = '1' then
						code(5) <= data ;
						state <= d6 ;
					end if ;
				when d6 =>
					if clk = '1' then
						code(6) <= data ;
						state <= d7 ;
					end if ;
				when d7 =>
					if clk = '1' then
						code(7) <= data ;
						state <= parity ;
					end if ;
				when parity =>
					if clk = '1' then
						if (data xor odd) = '1' then
							state <= stop ;
						else
							state <= delay ;
						end if;
					end if;
				when stop =>
					if clk = '1' then
						if data = '1' then
							state <= finish;
						else
							state <= delay;
						end if;
					end if;
				when finish =>
					state <= delay ;
					fok <= '1' ;
				when others =>
					state <= delay ;
			end case ; 
		end if ;
	end process ;
end rtl ;