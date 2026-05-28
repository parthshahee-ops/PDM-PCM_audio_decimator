
clear; clc; close all;
com_port = "COM4"; 
baud_rate = 115200; 

max_samples = 50; 
pcm_buffer = zeros(1, max_samples);

fprintf("Searching for device on %s...\n", com_port);
available_ports = serialportlist("available");
if ~ismember(com_port, available_ports)
    error("Port %s is not available. Ensure Thonny is disconnected!", com_port);
end

% Open the serial line connection
s = serialport(com_port, baud_rate);
configureTerminator(s, "LF"); % Look for Line Feed (\n) endings

figure('Name', 'FPGA Real-Time 8-Bit CIC Filter Visualizer', 'NumberTitle', 'off');
h_plot = plot(pcm_buffer, 'LineWidth', 2.5, 'Color', [0.9290 0.6940 0.1250]);
grid on;
ax = gca;

ax.YLim = [-140, 140]; 
ax.XLim = [1, max_samples];
title('Live 8-Bit Parallel PCM Data Stream (Test Pattern Loopback)');
xlabel('Sample History Window');
ylabel('Signed Amplitude (8-Bit PCM)');

fprintf("=== Connected! Streaming 8-bit hardware data... ===\n");
flush(s); % Purge old byte remnants in the hardware buffers

sample_count = 0;

while ishandle(h_plot)
    if s.NumBytesAvailable > 0
        raw_line = readline(s);
        
        tokens = regexp(raw_line, 'Filter Out:\s*(-?\d+)', 'tokens');
        
        if ~isempty(tokens)
            pcm_value = str2double(tokens{1}{1});
            
            if ~isnan(pcm_value) && pcm_value >= -128 && pcm_value <= 127
                sample_count = sample_count + 1;
                
                pcm_buffer = [pcm_buffer(2:end), pcm_value];
                
                set(h_plot, 'YData', pcm_buffer);
                
                if mod(sample_count, 10) == 0
                    fprintf("Sample #%d | Captured Value: %d\n", sample_count, pcm_value);
                end
                
                drawnow; % Instantly update the visualization canvas
            end
        end
    end
end

% Clean up the serial object dynamically upon closing the graph UI window
clear s;
fprintf("\nStream closed cleanly. Port %s released.\n", com_port);