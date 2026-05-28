clear; clc; close all;
com_port = "COM4"; 
baud_rate = 115200; 

max_samples = 50; 
pcm_buffer = zeros(1, max_samples);

fprintf("Opening data connection gateway on %s...\n", com_port);
s = serialport(com_port, baud_rate);
configureTerminator(s, "LF"); % Split packets cleanly at every newline (\n)


figure('Name', 'FPGA Real-Time 16-Bit Waveform Tracker', 'NumberTitle', 'off');
h_plot = plot(pcm_buffer, 'LineWidth', 2.5, 'Color', [0 0.4470 0.7410]);
grid on;
ax = gca;

% Adjusted to focus beautifully right around your current 0 to 250 data range
ax.YLim = [-50, 300]; 
ax.XLim = [1, max_samples];
title('Live Real-Time Synced PCM Filter Output');
xlabel('Sample History Window');
ylabel('Amplitude');

fprintf("=== Stream Connected! Plotting synced data curves... ===\n");
flush(s); % Clear any stale byte clutter out of the serial cache

while ishandle(h_plot)
    if s.NumBytesAvailable > 0
        % Read the text line straight from your print statement output
        raw_line = readline(s);
        
        % TARGETED REGEX: Grabs the numbers following your exact 'OUT:' prefix
        tokens = regexp(raw_line, 'OUT:(-?\d+)', 'tokens');
        
        if ~isempty(tokens)
            % Convert text string directly to a plot-compatible numeric double
            pcm_value = str2double(tokens{1}{1});
            
            % Guardrail validation check
            if ~isnan(pcm_value)
                % Shift the old samples left and insert the fresh data point at the end
                pcm_buffer = [pcm_buffer(2:end), pcm_value];
                
                % CRITICAL LINK: Push the new array directly into the graphic handle
                set(h_plot, 'YData', pcm_buffer);
                
                % CRITICAL FOR REAL-TIME VIEW: Forces MATLAB to paint the line instantly
                drawnow; 
            end
        end
    end
end

% Clean shutdown loop upon exit
clear s;
fprintf("\nPort closed safely.\n");
