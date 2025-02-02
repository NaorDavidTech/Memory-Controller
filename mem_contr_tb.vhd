-- Memory Controller TestBench
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_contr_tb is
end entity;

architecture test of mem_contr_tb is
    -- Component Declaration
    component mem_contr is
        port(
            rst, clk, rd_wr, ready : in std_logic;
            oe, we : out std_logic;
            timeout : out std_logic;
            state_debug : out std_logic_vector(1 downto 0)
        );
    end component;

    -- Signal Declaration
    signal clk_tb      : std_logic := '0';
    signal rst_tb      : std_logic := '0';
    signal rd_wr_tb    : std_logic := '0';
    signal ready_tb    : std_logic := '0';
    signal oe_tb       : std_logic;
    signal we_tb       : std_logic;
    signal timeout_tb  : std_logic;
    signal state_debug_tb : std_logic_vector(1 downto 0);

    -- Clock period definition
    constant CLK_PERIOD : time := 10 ns;

begin
    -- Device Under Test (DUT) instantiation
    DUT: mem_contr port map (
        clk => clk_tb,
        rst => rst_tb,
        rd_wr => rd_wr_tb,
        ready => ready_tb,
        oe => oe_tb,
        we => we_tb,
        timeout => timeout_tb,
        state_debug => state_debug_tb
    );

    -- Clock Generation Process
    clk_process: process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Test Stimulus Process
    stim_proc: process
    begin
        -- Initial Reset
        rst_tb <= '1';
        wait for CLK_PERIOD * 2;
        rst_tb <= '0';
        wait for CLK_PERIOD;

        -- Test Case 1: Read Operation
        report "Starting Read Operation Test";
        ready_tb <= '1';      -- Signal ready
        rd_wr_tb <= '1';      -- Request read
        wait for CLK_PERIOD * 2;
        ready_tb <= '0';      -- Memory not ready
        wait for CLK_PERIOD * 5;
        ready_tb <= '1';      -- Memory ready
        wait for CLK_PERIOD * 2;

        -- Test Case 2: Write Operation
        report "Starting Write Operation Test";
        ready_tb <= '1';      -- Signal ready
        rd_wr_tb <= '0';      -- Request write
        wait for CLK_PERIOD * 2;
        ready_tb <= '0';      -- Memory not ready
        wait for CLK_PERIOD * 5;
        ready_tb <= '1';      -- Memory ready
        wait for CLK_PERIOD * 2;

        -- Test Case 3: Timeout Test
        report "Starting Timeout Test";
        ready_tb <= '1';
        rd_wr_tb <= '1';
        wait for CLK_PERIOD * 2;
        ready_tb <= '0';
        wait for CLK_PERIOD * 20;  -- Wait longer than timeout period

        -- Test Case 4: Rapid State Changes
        report "Starting Rapid State Change Test";
        ready_tb <= '1';
        rd_wr_tb <= '1';
        wait for CLK_PERIOD;
        ready_tb <= '0';
        wait for CLK_PERIOD;
        ready_tb <= '1';
        wait for CLK_PERIOD;

        -- End simulation
        report "Simulation Completed Successfully";
        wait for CLK_PERIOD * 5;
        wait;
    end process;

    -- Monitor Process for checking outputs
    monitor_proc: process
    begin
        wait for CLK_PERIOD;
        
        -- Monitor and report state transitions
        if rising_edge(clk_tb) then
            case state_debug_tb is
                when "00" => report "State: IDLE";
                when "01" => report "State: DECISION";
                when "10" => report "State: READ";
                when "11" => report "State: WRITE";
                when others => report "Unknown State";
            end case;

            -- Report timeout conditions
            if timeout_tb = '1' then
                report "TIMEOUT DETECTED" severity warning;
            end if;
        end if;
    end process;

end architecture;