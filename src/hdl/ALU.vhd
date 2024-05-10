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
--|
--| ALU OPCODES:
--|
--|     000 OR
--|     001 AND
--|     010 RSHIFT
--|     011 LSHIFT
--|     100 ADD
--|     101 SUB
--|     110 ADD
--|     111 SUB
--|
--| Flags: NCZV
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
    port (
        i_op     : in std_logic_vector (2 downto 0);
        i_aluA   : in std_logic_vector (7 downto 0);
        i_aluB   : in std_logic_vector (7 downto 0);
        o_result : out std_logic_vector (7 downto 0);
        o_flag   : out std_logic_vector (3 downto 0)
    );
end ALU;

architecture behavioral of ALU is 
  
	-- declare components and signals
    component alu_addsub is
        port (
            i_A      : in std_logic_vector(7 downto 0);
            i_B      : in std_logic_vector(7 downto 0);
            i_C  : in std_logic;
            o_result : out std_logic_vector(7 downto 0);
            o_carry  : out std_logic
        );
        
    end component alu_addsub;
    
    component alu_rshift is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               o_shift : out STD_LOGIC_VECTOR (7 downto 0));
               
    end component alu_rshift;
    
    component alu_lshift is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               o_shift : out STD_LOGIC_VECTOR (7 downto 0));
               
    end component alu_lshift;
             
    signal w_or     : std_logic_vector (7 downto 0);
    signal w_and    : std_logic_vector (7 downto 0);
    signal w_lshift : std_logic_vector (7 downto 0);
    signal w_rshift : std_logic_vector (7 downto 0);
    signal w_addsub : std_logic_vector (7 downto 0);
    signal w_mux    : std_logic_vector (7 downto 0);
    signal w_result : std_logic_vector (7 downto 0);
  
  
begin
	-- PORT MAPS ----------------------------------------
    
    alu_addsub_inst : alu_addsub
        port map (
            i_A      => i_aluA,
            i_B      => i_aluB,
            i_C      => i_op(0),
            o_result => w_addsub,
            o_carry  => o_flag(2)
        );
	
	alu_rshift_inst : alu_rshift
	   port map(
	       i_A     => i_aluA,
	       i_B     => i_aluB,
	       o_shift => w_rshift
	   );
	 
	alu_lshift_inst : alu_lshift
       port map(
           i_A     => i_aluA,
           i_B     => i_aluB,
           o_shift => w_lshift
       );
	   
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	w_or  <= i_aluA OR i_aluB;
	w_and <= i_aluA AND i_aluB;
	w_mux <= w_or     when i_op(1 downto 0) = "00" else
	         w_and    when i_op(1 downto 0) = "01" else
	         w_rshift when i_op(1 downto 0) = "10" else
	         w_lshift when i_op(1 downto 0) = "11";
	w_result <= w_mux when i_op(2) = '0' else
	            w_addsub when i_op(2) = '1';
	o_flag(3) <= '1' when w_result(7) = '1' else '0';
	o_flag(1) <= '1' when w_result = "00000000" else '0';
	o_result <= w_result;
	
end behavioral;
