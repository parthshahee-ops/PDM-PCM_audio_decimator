clear; clc; close all;

% COM port and baud rate parameters used for receiving live FPGA data.
com_port  = "COM4";
baud_rate = 115200;

% Number of samples maintained in the scrolling waveform history window.
max_samples = 50;

% Circular display buffer initialized with zeros.
pcm_buffer = zeros(1, max_samples);

% Port Initialization
fprintf("Opening serial connection on %s...\n", com_port);

s = serialport(com_port, baud_rate);

% Incoming data packets are separated using line Feed (\n).
configureTerminator(s, "LF");

% RT Port Initialization
figure( ...
    'Name', 'FPGA Real-Time PCM Waveform Monitor', ...
    'NumberTitle', 'off');

h_plot = plot( ...
    pcm_buffer, ...
    'LineWidth', 2.5, ...
    'Color', [0 0.4470 0.7410]);

grid on;
ax = gca;

% display range configured for signed 8-bit PCM values.
ax.YLim = [-255 255];

% horizontal axis represents the history window.
ax.XLim = [1 max_samples];

% zero-amplitude reference line.
yline(0, '--k', 'Zero');

title('Live FPGA PCM Output Stream');
xlabel('Sample History Window');
ylabel('Amplitude');

fprintf("=== Stream Connected: Real-Time Plotting Started ===\n");

% Removw any stale bytes accumulated before monitoring begins.
flush(s);


% RT Data Acquisation
while ishandle(h_plot)

    % Process data only when bytes are available in the receive buffer.
    if s.NumBytesAvailable > 0

        % Read a complete line from the serial stream.
        raw_line = readline(s);

        % Extract signed numeric values following the "OUT:" tag.
        tokens = regexp(raw_line, 'OUT:(-?\d+)', 'tokens');

        if ~isempty(tokens)

            % Convert extracted text into numeric form.
            pcm_value = str2double(tokens{1}{1});

            % Continue only if a valid number was received.
            if ~isnan(pcm_value)

                % Shift historical samples left and append the newest value.
                pcm_buffer = [pcm_buffer(2:end), pcm_value];

                % Update waveform data in the existing plot object.
                set(h_plot, 'YData', pcm_buffer);

                % Force immediate graphical refresh.
                drawnow;
            end
        end
    end
end

% SHUTDOWN
clear s;
fprintf("\nSerial port closed successfully.\n");