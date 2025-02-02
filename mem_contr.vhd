
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  

entity mem_contr is 
    port(
        rst, clk, rd_wr, ready : in std_logic;  
        oe, we : out std_logic;                 
        timeout : out std_logic;                
        state_debug : out std_logic_vector(1 downto 0)  
    );
end entity;

architecture sm of mem_contr is
    -- State definitions for the FSM (Finite State Machine)
    type state is (idle, decision, read1, write1);
    signal present_state, next_state : state;
    
    -- New: 4-bit counter for timeout detection (maximum count: 15)
    signal timer_count : unsigned(3 downto 0);  
    
begin
    -- Synchronous process for state updates and timer management
    sync: process (clk, rst)
    begin
        if rst = '1' then 
            -- Reset condition: Initialize state and timer
            present_state <= idle;
            timer_count <= (others => '0');
        elsif rising_edge(clk) then 
            -- Normal operation on clock edge
            present_state <= next_state;
            
            -- Timer logic: Reset on state change, increment otherwise
            if present_state /= next_state then
                timer_count <= (others => '0');  -- Reset timer on state transition
            elsif timer_count /= "1111" then
                timer_count <= timer_count + 1;  -- Increment timer if not at max
            end if;
        end if;
    end process;

    -- Combinational process for next state logic and outputs
    comb: process (present_state, rd_wr, ready, timer_count)
    begin
        -- Default values for outputs (good design practice)
        oe <= '0';
        we <= '0';
        timeout <= '0';
        state_debug <= "00";

        case present_state is
            when idle => 
                state_debug <= "00";  -- Debug code for IDLE state
                if ready = '1' then 
                    next_state <= decision;
                else 
                    next_state <= idle;
                end if;

            when decision =>
                state_debug <= "01";  -- Debug code for DECISION state
                if rd_wr = '1' then 
                    next_state <= read1;  -- Transition to read state
                else 
                    next_state <= write1;  -- Transition to write state
                end if;

            when read1 =>
                state_debug <= "10";  -- Debug code for READ state
                oe <= '1';  -- Enable output for read operation
                if timer_count = "1111" then  -- Timeout check
                    timeout <= '1';
                    next_state <= idle;  -- Return to idle on timeout
                elsif ready = '0' then 
                    next_state <= read1;  -- Stay in read state
                else 
                    next_state <= idle;  -- Complete read operation
                end if;

            when write1 =>
                state_debug <= "11";  -- Debug code for WRITE state
                we <= '1';  -- Enable write operation
                if timer_count = "1111" then  -- Timeout check
                    timeout <= '1';
                    next_state <= idle;  -- Return to idle on timeout
                elsif ready = '0' then 
                    next_state <= write1;  -- Stay in write state
                else 
                    next_state <= idle;  -- Complete write operation
                end if;

        end case;
    end process;
end architecture;