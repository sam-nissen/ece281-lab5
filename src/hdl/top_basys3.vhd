--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port (
        clk     : in std_logic;
        btnU    : in std_logic;
        btnC    : in std_logic;
        sw      : in std_logic_vector (7 downto 0);
        seg     : out std_logic_vector (6 downto 0);
        led     : out std_logic_vector (15 downto 0);
        an      : out std_logic_vector (3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component cpu_register is
        Port (
            clk : in STD_LOGIC;   
            i_D : in STD_LOGIC_VECTOR(7 downto 0);
            o_D : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component cpu_register;
    
    component ALU is
        port (
            i_op     : in std_logic_vector (2 downto 0);
            i_aluA   : in std_logic_vector (7 downto 0);
            i_aluB   : in std_logic_vector (7 downto 0);
            o_result : out std_logic_vector (7 downto 0);
            o_flag   : out std_logic_vector (3 downto 0)
        );
    end component ALU;
    
    component twoscomp_decimal is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic_vector(3 downto 0);
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twoscomp_decimal;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk        : in  STD_LOGIC;
               i_reset      : in  STD_LOGIC; -- asynchronous
               i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data       : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel        : out STD_LOGIC_VECTOR (3 downto 0)    -- selected data line (one-cold)
        );
    end component TDM4;

    component sevenSegDecoder is
        Port ( i_D : in STD_LOGIC_VECTOR (3 downto 0);
               o_S : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenSegDecoder;
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port (  i_clk    : in std_logic;
                i_reset  : in std_logic;           -- asynchronous
                o_clk    : out std_logic           -- divided (slow) clock
        );
    end component clock_divider;
    
    signal w_reset_fsm : std_logic;
    signal w_adv       : std_logic;
    signal w_cycle     : std_logic_vector(3 downto 0);
    signal w_clk       : std_logic;
    signal w_A         : std_logic_vector(7 downto 0);
    signal w_B         : std_logic_vector(7 downto 0);
    signal w_result    : std_logic_vector(7 downto 0);
    signal w_bin       : std_logic_vector(7 downto 0);
    signal w_sign      : std_logic_vector(3 downto 0);
    signal w_hund      : std_logic_vector(3 downto 0);
    signal w_tens      : std_logic_vector(3 downto 0);
    signal w_ones      : std_logic_vector(3 downto 0);
    signal w_data      : std_logic_vector(3 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
    controller_fsm_inst : controller_fsm
        port map (
            i_reset => w_reset_fsm,
            i_adv   => w_adv,
            o_cycle => w_cycle
        );
    regA_inst : cpu_register
        port map (
            clk => w_cycle(2),
            i_D => sw(7 downto 0),
            o_D => w_A
        );
    regB_inst : cpu_register
        port map(
            clk => w_cycle(1),
            i_D => sw(7 downto 0),
            o_D => w_B
	    );
	ALU_inst : alu
	    port map(
	        i_op     => sw(2 downto 0),
	        i_aluA   => w_A,
	        i_aluB   => w_B,
	        o_result => w_result,
	        o_flag   => led(15 downto 12)
	    );    
    twoscomp_decimal_inst : twoscomp_decimal
        port map(
            i_bin   => w_bin,
            o_sign  => w_sign,
            o_hund  => w_hund,
            o_tens  => w_tens,
            o_ones  => w_ones
        );
    clkdiv_inst : clock_divider
        generic map ( k_div => 125000)
        port map(
            i_clk   => clk,
            i_reset => btnU,
            o_clk   => w_clk
        );
    tdm4_inst : tdm4
        generic map (k_WIDTH => 4)
        port map(
            i_clk   => w_clk,
            i_reset => btnU,
            i_D3    => w_sign,
            i_D2    => w_hund,
            i_D1    => w_tens,
            i_D0    => w_ones,
            o_data  => w_data,
            o_sel   => an
        );
    sevensegdecoder_inst : sevenSegDecoder
        port map(
            i_D => w_data,
            o_S => seg
        );
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	w_bin <= sw(7 downto 0) when (w_cycle = "1000") else
	         sw(7 downto 0) when (w_cycle = "0100") else
	         w_result when (w_cycle = "0010") else
	         x"00";
	         
    w_adv <= btnC;       
	         
    led(3 downto 0) <= w_cycle;
    led(11 downto 4) <= w_bin;
	
end top_basys3_arch;
