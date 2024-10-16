clear all 
close all 

%% Load Eeglab path

eeglab_path='G:\Users\Public\Documents\USB\Master\Segon semestre\Human_Machine_Interface\eeglab_2023\eeglab2023'; 
addpath(genpath(eeglab_path));


%% Load LIBLSL MATLAB (supposely to do on-line readings)
%libsl_path='E:\Users\Public\Documents\USB\Master\Segon semestre\Human_Machine_Interface\Unicorn\EEG_Recordings_20240510\liblsl-Matlab'; 
%addpath(genpath(libsl_path))


%% LOAD XDF file

% Get the current directory where your MATLAB script is located
currentFolder = fileparts(which(mfilename));

%Make sure to have on the same folder where the code is located the
%XDF_Matlab codes

XDF_Matlab = fullfile(currentFolder,'xdf_Matlab');
addpath(XDF_Matlab)

% Define the relative path to the xdf file

relativePath_MI = '\MI\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf';
relativePath_ME = '\ME\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf';


% Generate the full path to the xdf file
xdfFilePath_MI = fullfile(currentFolder, relativePath_MI);
xdfFilePath_ME = fullfile(currentFolder, relativePath_ME);


% Load the xdf file
[streams_MI, fileheader_MI] = load_xdf(xdfFilePath_MI);
[streams_ME, fileheader_ME] = load_xdf(xdfFilePath_ME);

% Both datasets have the same sampling rate
sampling_rate = streams_MI{1, 1}.info.effective_srate; 

%% EEG DATA PROCESSING

EEG_DATA_MI = streams_MI{1, 1}.time_series(1:9,:);  
EEG_DATA_ME = streams_ME{1, 2}.time_series(1:9,:);  

% Convert to double precision
EEG_DATA_MI = double(EEG_DATA_MI);
EEG_DATA_ME = double(EEG_DATA_ME);

%% ICA FILTERING 

EEG_DATA_MI = perform_ICA(streams_MI,1);
EEG_DATA_ME = perform_ICA(streams_ME,2);

%% FILTERING

% BANDPASS FILTER, when I increase butterworth order all the filtered data
% becomes NaN, don't know why. 

[b_butter,a_butter] = butter(2,[0.3,10]/(sampling_rate/2)); 

% Butterworth filtering of 0.3 to 10 Hz is applied for all 10 channels and
% zero mean is performed to avoid some noise. 
for i=1:size(EEG_DATA_MI.data, 1)
    eeg_data_but_notch_MI(i,:) = filtfilt(b_butter,a_butter,detrend(double(EEG_DATA_MI.data(i,:)),'constant')); 
    eeg_data_mean_MI(i,:) = mean(eeg_data_but_notch_MI(i,:)); 
end
eeg_data_but_notch_MI = eeg_data_but_notch_MI';
channels_mean_MI = mean(eeg_data_but_notch_MI,2); 
channels_mean_matrix_MI =  repmat(channels_mean_MI, 1, size(eeg_data_but_notch_MI, 2)); % Replicate along the second dimension (columns)

for i=1:size(EEG_DATA_ME.data, 1)
    eeg_data_but_notch_ME(i,:) = filtfilt(b_butter,a_butter,detrend(double(EEG_DATA_ME.data(i,:)),'constant')); 
    eeg_data_mean_ME(i,:) = mean(eeg_data_but_notch_ME(i,:)); 
end
eeg_data_but_notch_ME = eeg_data_but_notch_ME';
channels_mean_ME = mean(eeg_data_but_notch_ME,2); 
channels_mean_matrix_ME =  repmat(channels_mean_ME, 1, size(eeg_data_but_notch_ME, 2)); % Replicate along the second dimension (columns)

eeg_data_filtered_MI = eeg_data_but_notch_MI - channels_mean_matrix_MI;
eeg_data_filtered_ME = eeg_data_but_notch_ME - channels_mean_matrix_ME;

%% REPRESENTATION MI

% Assuming duration is in seconds and sampling_rate is in Hz
duration = streams_MI{1,1}.segments.duration;

% Calculate the time vector based on the duration and sampling rate
time_vector_MI = (0:(duration * sampling_rate)) / sampling_rate;

% Shift the event timestamps relative to the beginning of the EEG data
events_MI = (streams_MI{1,2}.time_stamps - streams_MI{1,1}.segments.t_begin) * sampling_rate;

% Plot EEG data
figure;
subplot(2,1,1)
plot(time_vector_MI,eeg_data_filtered_MI(:,5));
hold on;

% Plot event markers
for i = 1:numel(events_MI)
    line([events_MI(i)/sampling_rate, events_MI(i)/sampling_rate], ylim, 'Color', 'red', 'LineStyle', '--'); 
    text(events_MI(i)/sampling_rate, max(ylim), char(streams_MI{1,2}.time_series(i)));
end

xlabel('SAMPLES');
ylabel('EEG Data');
title('EEG Data with Event Markers MOTOR IMAGINERY, Cz');

%% REPRESENTATION ME

% Assuming duration is in seconds and sampling_rate is in Hz
duration = streams_ME{1,2}.segments.duration;

% Calculate the time vector based on the duration and sampling rate
time_vector_ME = (0:(duration * sampling_rate + 1)) / sampling_rate;

% Shift the event timestamps relative to the beginning of the EEG data
events_ME = (streams_ME{1,1}.time_stamps - streams_ME{1,2}.segments.t_begin) * sampling_rate;

% Plot EEG data
subplot(2,1,2)
plot(time_vector_ME, eeg_data_filtered_ME(:,5));
hold on;

% Plot event markers
for i = 1:numel(events_ME)
    line([events_ME(i)/sampling_rate, events_ME(i)/sampling_rate], ylim, 'Color', 'red', 'LineStyle', '--'); 
    text(events_ME(i)/sampling_rate, max(ylim), char(streams_ME{1,1}.time_series(i)));
end

xlabel('SAMPLES');
ylabel('EEG Data');
title('EEG Data with Event Markers MOTOR E, Cz');

%% TOPOPLOT MI

figure
subplot(4,3,1)
topoplot(mean(eeg_data_filtered_MI),'Standard-10-20-Cap9.locs')
colorbar
colormap('jet')
title('EEG TOPOPLOT (MEAN)')

for j=1: numel(events_MI)
    % 1. Define the start and end time points of the period you want to analyze
    start_time_MI = events_MI(j) / sampling_rate;
    end_time_MI = events_MI(j) / sampling_rate + 0.3;
    
    % 2. Convert the time points to indices using the sampling rate
    start_index_MI = round(start_time_MI * sampling_rate);
    end_index_MI = round(end_time_MI * sampling_rate);
    
    % 3. Extract the EEG data within the specified time window
    eeg_data_period_MI = eeg_data_filtered_MI(start_index_MI:end_index_MI, :);
    
    subplot(4,3,j+1)
    topoplot(mean(eeg_data_period_MI),'Standard-10-20-Cap9.locs')
    colorbar
    colormap('jet')
    title("EEG TOPOPLOT AT EVENT "+ j +" :" + char(streams_MI{1,2}.time_series(j)) + " MOVEMENT")
end

% Create extra space at the top by adjusting the 'Position' of the subplots
h = findall(gcf,'type','axes'); % Find all axes in the figure
for i = 1:length(h)
    pos = get(h(i), 'Position'); % Get current position
    pos(2) = pos(2) - 0.05; % Move subplots down by adjusting the y-position
    set(h(i), 'Position', pos); % Set the new position
end

st = sgtitle("TOPOPLOTS FOR THE "+ numel(events_MI) + " MOTOR IMAGINERY DETECTED EVENTS",'Color','red');
st.FontSize = 20;

%% TOPOPLOT ME

figure
subplot(4,3,1)
topoplot(mean(eeg_data_filtered_ME),'Standard-10-20-Cap9.locs')
colorbar
colormap('jet')
title('EEG TOPOPLOT (MEAN)')

for j=1: numel(events_ME)
    % 1. Define the start and end time points of the period you want to analyze
    start_time_ME = events_ME(j) / sampling_rate;
    end_time_ME = events_ME(j) / sampling_rate + 0.3;
    
    % 2. Convert the time points to indices using the sampling rate
    start_index_ME = round(start_time_ME * sampling_rate);
    end_index_ME = round(end_time_ME * sampling_rate);
    
    % 3. Extract the EEG data within the specified time window
    eeg_data_period_ME = eeg_data_filtered_ME(start_index_ME:end_index_ME, :);
    
    subplot(4,3,j+1)
    topoplot(mean(eeg_data_period_ME),'Standard-10-20-Cap9.locs')
    colorbar
    colormap('jet')
    title("EEG TOPOPLOT AT EVENT "+ j +" :" + char(streams_ME{1,1}.time_series(j)) + " MOVEMENT")
end

% Create extra space at the top by adjusting the 'Position' of the subplots
h = findall(gcf,'type','axes'); % Find all axes in the figure
for i = 1:length(h)
    pos = get(h(i), 'Position'); % Get current position
    pos(2) = pos(2) - 0.05; % Move subplots down by adjusting the y-position
    set(h(i), 'Position', pos); % Set the new position
end

st = sgtitle("TOPOPLOTS FOR THE "+ numel(events_ME) + " MOTOR E DETECTED EVENTS",'Color','red');
st.FontSize = 20;
