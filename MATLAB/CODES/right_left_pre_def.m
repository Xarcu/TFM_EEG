clear all 
close all 

%% Load Eeglab path
eeglab_path='G:\Users\Public\Documents\USB\Master\Segon semestre\Human_Machine_Interface\eeglab_2023\eeglab2023'; 
addpath(genpath(eeglab_path));

%% LOAD XDF file
currentFolder = fileparts(which(mfilename));
XDF_Matlab = fullfile(currentFolder,'xdf_Matlab');
addpath(XDF_Matlab)

% xdfFilePath_Right = "G:\Users\Public\Documents\USB\Feina UPC\EEG\Experiments\PSYCHOPY+BITBRAIN\LAB_RECORDER\OFFLINE\DATASET\ME\SUB_2\RIGHT\sub-P001\ses-S002\eeg\sub-P001_ses-S002_task-Default_run-001_eeg.xdf";
% xdfFilePath_Left ="G:\Users\Public\Documents\USB\Feina UPC\EEG\Experiments\PSYCHOPY+BITBRAIN\LAB_RECORDER\OFFLINE\DATASET\ME\SUB_2\LEFT\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf";

xdfFilePath_Right = "G:\Users\Public\Documents\USB\Feina UPC\EEG\Experiments\PSYCHOPY+BITBRAIN\LAB_RECORDER\OFFLINE\DATASET\SUB_2\RIGHT\sub-P001\ses-S002\eeg\sub-P001_ses-S002_task-Default_run-001_eeg.xdf";
xdfFilePath_Left ="G:\Users\Public\Documents\USB\Feina UPC\EEG\Experiments\PSYCHOPY+BITBRAIN\LAB_RECORDER\OFFLINE\DATASET\SUB_2\LEFT\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf";


[streams_R, fileheader_R] = load_xdf(xdfFilePath_Right);
[streams_L, fileheader_L] = load_xdf(xdfFilePath_Left);

%% Determine sampling rate
try
    sampling_rate = streams_R{1, 1}.info.effective_srate;
catch
    sampling_rate = streams_R{1, 2}.info.effective_srate;
end

%% Perform ICA Filtering
try
    EEG_DATA_R = perform_ICA(streams_R, 1);
catch
    EEG_DATA_R = perform_ICA(streams_R, 2);
end
try
    EEG_DATA_L = perform_ICA(streams_L, 1);
catch
    EEG_DATA_L = perform_ICA(streams_L, 2);
end

%% Power spectral density and Histogram
Generic_INFO(EEG_DATA_R,'R');
Generic_INFO(EEG_DATA_L,'L');

%% Filtering

EEG_filt_R = Filtering(EEG_DATA_R);
EEG_filt_L = Filtering(EEG_DATA_L); 

%% Representation EEG_RIGHT
try
    duration_right = streams_R{1, 2}.segments.duration;
catch
    duration_right = streams_R{1, 1}.segments.duration;
end

time_vector_right = (0:(length(EEG_filt_R) - 1)) / sampling_rate;

try
    events_right = (streams_R{1, 1}.time_stamps - streams_R{1, 2}.segments.t_begin) * sampling_rate;
catch
    events_right = (streams_R{1, 2}.time_stamps - streams_R{1, 1}.segments.t_begin) * sampling_rate;
end

figure;
plot(time_vector_right, EEG_filt_R(:, 5));
hold on;

for i = 1:numel(events_right)
    line([events_right(i) / sampling_rate, events_right(i) / sampling_rate], ylim, 'Color', 'red', 'LineStyle', '--'); 
    text(events_right(i) / sampling_rate, max(ylim), char(streams_R{1, 2}.time_series(i)));
end

xlabel('SAMPLES');
ylabel('EEG Data');
title('EEG Data with Event Markers MOTOR IMAGERY, Cz (RIGHT)');

%% Representation EEG_LEFT
try
    duration_left = streams_L{1, 2}.segments.duration;
catch
    duration_left = streams_L{1, 1}.segments.duration;
end

time_vector_left = (0:(length(EEG_filt_L) - 1)) / sampling_rate;

try
    events_left = (streams_L{1, 1}.time_stamps - streams_L{1, 2}.segments.t_begin) * sampling_rate;
catch
    events_left = (streams_L{1, 2}.time_stamps - streams_L{1, 1}.segments.t_begin) * sampling_rate;
end

figure;
plot(time_vector_left, EEG_filt_L(:, 5));
hold on;

for i = 1:numel(events_left)
    line([events_left(i) / sampling_rate, events_left(i) / sampling_rate], ylim, 'Color', 'red', 'LineStyle', '--'); 
    text(events_left(i) / sampling_rate, max(ylim), char(streams_L{1, 2}.time_series(i)));
end

xlabel('SAMPLES');
ylabel('EEG Data');
title('EEG Data with Event Markers MOTOR IMAGERY, Cz (LEFT)');

%% TOPOPLOT

R_events = events_right;
L_events = events_left;

R_data = [];
L_data = [];

for j = 1:numel(R_events)
    start_time = R_events(j) / sampling_rate;
    end_time = start_time + 2.8;
    
    start_index = round(start_time * sampling_rate);
    end_index = round(end_time * sampling_rate);
    
    eeg_data_period_R = EEG_filt_R(start_index:end_index, :);
    
    R_data = [R_data; eeg_data_period_R];
end

for j = 1:numel(L_events)
    start_time = L_events(j) / sampling_rate;
    end_time = start_time + 2.8;
    
    start_index = round(start_time * sampling_rate);
    end_index = round(end_time * sampling_rate);
    
    eeg_data_period_L = EEG_filt_L(start_index:end_index, :);
 
    L_data = [L_data; eeg_data_period_L];
end

mean_R_data = mean(R_data, 1);
mean_L_data = mean(L_data, 1);

% Topoplot for mean of all 'R' events
subplot(1, 2, 1)
topoplot(mean_R_data, 'Standard-10-20-Cap9.locs', 'maplimits', [-0.5, 0.5])
colorbar
colormap('jet')
title('EEG TOPOPLOT (MEAN) for all ''R'' Events')

% Topoplot for mean of all 'L' events
subplot(1, 2, 2)
topoplot(mean_L_data, 'Standard-10-20-Cap9.locs', 'maplimits', [-0.5, 0.5])
colorbar
colormap('jet')
title('EEG TOPOPLOT (MEAN) for all ''L'' Events')

sgtitle("TOPOPLOTS FOR 'R' AND 'L' MOTOR IMAGERY EVENTS", 'Color', 'red', 'FontSize', 20);

% Define the number of columns to ensure larger subplots
num_cols = 5;

% Plot for R events
num_R_events = numel(R_events);
num_rows = ceil((num_R_events + 1) / num_cols);

figure('Position', [100, 100, 1500, 800]); % Increase figure size
subplot(num_rows, num_cols, 1)
topoplot(mean_R_data, 'Standard-10-20-Cap9.locs','maplimits', [-1, 1])
colorbar
colormap('jet')
title('EEG TOPOPLOT (MEAN) for ''R'' Events')

for j = 1:num_R_events
    start_time = R_events(j) / sampling_rate;
    end_time = R_events(j) / sampling_rate + 2.5;

    start_index = round(start_time * sampling_rate);
    end_index = round(end_time * sampling_rate);

    eeg_data_period_R = EEG_filt_R(start_index:end_index, :);

    subplot(num_rows, num_cols, j + 1)
    topoplot(mean(eeg_data_period_R),'Standard-10-20-Cap9.locs','maplimits', [-1, 1])
    colorbar
    colormap('jet')
    title("EEG TOPOPLOT AT 'R' EVENT " + j)
end

sgtitle("TOPOPLOTS FOR 'R' MOTOR IMAGERY EVENTS",'Color','red', 'FontSize', 20);

% Plot for L events
num_L_events = numel(L_events);
num_rows = ceil((num_L_events + 1) / num_cols);

figure('Position', [100, 100, 1500, 800]); % Increase figure size
subplot(num_rows, num_cols, 1)
topoplot(mean_L_data,'Standard-10-20-Cap9.locs','maplimits', [-1, 1])
colorbar
colormap('jet')
title('EEG TOPOPLOT (MEAN) for ''L'' Events')

for j = 1:num_L_events
    start_time = L_events(j) / sampling_rate;
    end_time = L_events(j) / sampling_rate + 2.5;

    start_index = round(start_time * sampling_rate);
    end_index = round(end_time * sampling_rate);

    eeg_data_period_L = EEG_filt_L(start_index:end_index, :);

    subplot(num_rows, num_cols, j + 1)
    topoplot(mean(eeg_data_period_L),'Standard-10-20-Cap9.locs','maplimits', [-1, 1])
    colorbar
    colormap('jet')
    title("EEG TOPOPLOT AT 'L' EVENT " + j)
end

sgtitle("TOPOPLOTS FOR 'L' MOTOR IMAGERY EVENTS",'Color','red', 'FontSize', 20);






