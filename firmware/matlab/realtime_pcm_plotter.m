clear; clc; close all;

% Configuration Parameters
com_port = "COM4";          % Change to your active USB-Serial port map
baud_rate = 115200;         
window_size = 100;          % Number of concurrent samples shown on screen
pcm_history = zeros(1, window_size);

fprintf("Opening serial gateway connection on %s...\n", com_port);
s = serialport(com_port, baud_rate);
configureTerminator(s, "LF"); 

% Setup Plot Canvas Architecture
figure('Name', 'FPGA PDM-to-PCM Sine Wave Engine Telemetry', 'NumberTitle', 'off');
h_plot = plot(pcm_history, 'LineWidth', 2.5, 'Color', [0 0.5 0.8]);
grid on;
ax = gca;

% Fit full-scale 16-bit signed PCM amplitude boundaries comfortably
ax.YLim = [-35000, 35000]; 
ax.XLim = [1, window_size];
title('Live Decimated PCM Sine Wave Profile (R=8)');
xlabel('Real-Time Sample Window');
ylabel('Signed Amplitude (16-Bit Two''s Complement)');

fprintf("=== Stream Synced! Plotting incoming dataset... ===\n");
flush(s); 

% Continuous Data Acquisition Engine
while ishandle(h_plot)
    if s.NumBytesAvailable > 0
        raw_line = readline(s);
        
        % Targeted Regex Pattern Matching to isolate 'OUT:XXXX'
        tokens = regexp(raw_line, 'OUT:(-?\d+)', 'tokens');
        
        if ~isempty(tokens)
            pcm_value = str2double(tokens{1}{1});
            
            % Validate that data point stays inside legitimate PCM boundaries
            if ~isnan(pcm_value) && pcm_value >= -32768 && pcm_value <= 32767
                % Advance historical buffer window
                pcm_history = [pcm_history(2:end), pcm_value];
                
                % Update graphic coordinate data handle
                set(h_plot, 'YData', pcm_history);
                drawnow; 
            end
        end
    end
end

clear s;
fprintf("\nPort released cleanly.\n");
