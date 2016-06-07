library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
entity king is
	port(
		sram_address:out std_logic_vector(20 downto 0);
		sram_CE,sram_OE,sram_WE:out std_logic;
		sram_data:inout std_logic_vector(31 downto 0);
		keyboarddata:in std_logic;
		keyboardclk:in std_logic;
		clk100m:in std_logic;
		rst:in std_logic;
		hs:out std_logic;
		vs:out std_logic;
		ored:out std_logic_vector (2 downto 0);
		ogreen:out std_logic_vector (2 downto 0);
		oblue:out std_logic_vector (2 downto 0)
	);
end king;
architecture behave of king is
component Keyboard is
	port(
		keyboarddata: in std_logic ; -- PS2 clk
		keyboardclk: in std_logic;--PS2 data
		clk100m: in std_logic ;  -- filter clock
		rst : in std_logic ; 
		scancode : out std_logic_vector(7 downto 0) -- scan code signal output
	) ;
end component ;
component keyboardstate is
	port(
		clk:in std_logic;
		scancode:in std_logic_vector(7 downto 0);
		statusa:out std_logic_vector(7 downto 0);
		statusb:out std_logic_vector(7 downto 0)
	);
end component;
component vga_controller is
	port (
		hs:out std_logic;
		vs:out std_logic;
		ored:out std_logic_vector (2 downto 0);
		ogreen:out std_logic_vector (2 downto 0);
		oblue:out std_logic_vector (2 downto 0);
		request_pos_x:out std_logic_vector(9 downto 0);
		request_pos_y:out std_logic_vector(9 downto 0);
		res_red:in std_logic_vector(2 downto 0);
		res_green:in std_logic_vector(2 downto 0);
		res_blue:in std_logic_vector(2 downto 0);
		reset:in std_logic;
		clk100m:in std_logic			--100M时钟输入
	);		
end component;
component logic is
port
(
	key0:in std_logic_vector(7 downto 0);
	key1:in std_logic_vector(7 downto 0);
	sram_address:out std_logic_vector(20 downto 0);
	sram_CE,sram_OE,sram_WE:out std_logic;
	sram_data:inout std_logic_vector(31 downto 0);
	request_pos_x,request_pos_y:in std_logic_vector(9 downto 0);
	clk1:in std_logic;
	res_red,res_green,res_blue:out std_logic_vector(2 downto 0)
);
end component;
signal scancode : std_logic_vector(7 downto 0);
signal statusa:std_logic_vector(7 downto 0);
signal statusb:std_logic_vector(7 downto 0);
signal request_pos_x:std_logic_vector(9 downto 0);
signal request_pos_y:std_logic_vector(9 downto 0);
signal res_red:std_logic_vector(2 downto 0);
signal res_green:std_logic_vector(2 downto 0);
signal res_blue:std_logic_vector(2 downto 0);
begin
	u0: Keyboard port map(keyboarddata,keyboardclk,clk100m,rst,scancode);
	u1: keyboardstate port map(clk100m,scancode,statusa,statusb);
	u2: VGA_controller port map(hs,vs,ored,ogreen,oblue,request_pos_x,request_pos_y,res_red,res_green,res_blue,rst,clk100m);
	u3: logic port map(statusa,statusb,sram_address,sram_CE,sram_OE,sram_WE,sram_data,request_pos_x,request_pos_y,clk100m,res_red,res_green,res_blue);
end behave;