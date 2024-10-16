clear all 
close all 

%% Load Eeglab path

%eeglab_path='E:\Users\Public\Documents\USB\Master\Segon semestre\Human_Machine_Interface\eeglab_2023\eeglab2023'; 
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

relativePath_MI_L_A = '\MI\Left Arm\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf';
relativePath_MI_L_L = '\MI\Left Leg\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf';
relativePath_MI_R_A = '\MI\Right Arm\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf';
relativePath_MI_R_L = '\MI\Right Leg\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf';


% Generate the full path to the xdf file
xdfFilePath_MI_L_A = fullfile(currentFolder, relativePath_MI_L_A);
xdfFilePath_MI_L_L = fullfile(currentFolder, relativePath_MI_L_L);
xdfFilePath_MI_R_A = fullfile(currentFolder, relativePath_MI_R_A);
xdfFilePath_MI_R_L = fullfile(currentFolder, relativePath_MI_R_L);

% Load the xdf file
[streams_MI_L_A, fileheader_MI_L_A] = load_xdf(xdfFilePath_MI_L_A);
[streams_MI_L_L, fileheader_MI_L_L] = load_xdf(xdfFilePath_MI_L_L);
[streams_MI_R_A, fileheader_MI_R_A] = load_xdf(xdfFilePath_MI_R_A);
[streams_MI_R_L, fileheader_MI_R_L] = load_xdf(xdfFilePath_MI_R_L);


%Both datasets have the same sampling rate
sampling_rate = streams_MI_L_A{1, 2}.info.effective_srate; 
%% EEG DATA PROCESSING

EEG_DATA_MI_L_A = streams_MI_L_A{1, 2}.time_series(1:10,:);  
EEG_DATA_MI_L_L = streams_MI_L_L{1, 2}.time_series(1:10,:);  
EEG_DATA_MI_R_A = streams_MI_R_A{1, 1}.time_series(1:10,:);  
EEG_DATA_MI_R_L = streams_MI_R_L{1, 2}.time_series(1:10,:);  


% Convert EEG data to double
EEG_DATA_MI_L_A = double(EEG_DATA_MI_L_A);
EEG_DATA_MI_L_L = double(EEG_DATA_MI_L_L);
EEG_DATA_MI_R_A = double(EEG_DATA_MI_R_A);
EEG_DATA_MI_R_L = double(EEG_DATA_MI_R_L);

%% ICA FILTERING 

EEG_DATA_MI_L_A = perform_ICA(streams_MI_L_A,2);
EEG_DATA_MI_L_L = perform_ICA(streams_MI_L_L,2);
EEG_DATA_MI_R_A = perform_ICA(streams_MI_R_A,1);
EEG_DATA_MI_R_L = perform_ICA(streams_MI_R_L,2);

%% FILTERING


% Apply filtering
eeg_data_filtered_MI_L_A = Filtering(EEG_DATA_MI_L_A);
eeg_data_filtered_MI_L_L = Filtering(EEG_DATA_MI_L_L);
eeg_data_filtered_MI_R_A = Filtering(EEG_DATA_MI_R_A);
eeg_data_filtered_MI_R_L = Filtering(EEG_DATA_MI_R_L);


%% REPRESENTATION 

% Assuming duration is in seconds and sampling_rate is in Hz
duration_MI_L_A = streams_MI_L_A{1,2}.segments.duration;
duration_MI_L_L = streams_MI_L_L{1,2}.segments.duration;
duration_MI_R_A = streams_MI_R_A{1,1}.segments.duration;
duration_MI_R_L = streams_MI_R_L{1,2}.segments.duration;


% Calculate the time vector based on the duration and sampling rate
time_vector_MI_L_A = (0:(duration_MI_L_A * sampling_rate)) / sampling_rate;
time_vector_MI_L_L = (0:(duration_MI_L_L * sampling_rate)) / sampling_rate;
time_vector_MI_R_A = (0:(duration_MI_R_A * sampling_rate)) / sampling_rate;
time_vector_MI_R_L = (0:(duration_MI_R_L * sampling_rate)) / sampling_rate;

% Shift the event timestamps relative to the beginning of the EEG data
events_MI_L_A = (streams_MI_L_A{1,1}.time_stamps - streams_MI_L_A{1,2}.segments.t_begin)*sampling_rate;
events_MI_L_L = (streams_MI_L_L{1,1}.time_stamps - streams_MI_L_L{1,2}.segments.t_begin)*sampling_rate;
events_MI_R_A = (streams_MI_R_A{1,2}.time_stamps - streams_MI_R_A{1,1}.segments.t_begin)*sampling_rate;
events_MI_R_L = (streams_MI_R_L{1,1}.time_stamps - streams_MI_R_L{1,2}.segments.t_begin)*sampling_rate;

% Plot EEG data
figure;
subplot(4,1,1)
plotting("Left Arm",time_vector_MI_L_A,eeg_data_filtered_MI_L_A(:,5),events_MI_L_A,sampling_rate,'L');
subplot(4,1,2)
plotting("Left Leg",time_vector_MI_L_L,eeg_data_filtered_MI_L_L(:,5),events_MI_L_A,sampling_rate,'L');
subplot(4,1,3)
plotting("Right Arm",time_vector_MI_R_A,eeg_data_filtered_MI_R_A(:,5),events_MI_L_A,sampling_rate,'R');
subplot(4,1,4)
plotting("Right Leg",time_vector_MI_R_L,eeg_data_filtered_MI_R_L(:,5),events_MI_L_A,sampling_rate,'R');




%% TOPOPLOT MI

topo(eeg_data_filtered_MI_L_A,events_MI_L_A,sampling_rate,"LEFT ARM")
topo(eeg_data_filtered_MI_L_L,events_MI_L_L,sampling_rate,"LEFT LEG")
topo(eeg_data_filtered_MI_R_A,events_MI_R_A,sampling_rate,"RIGHT ARM")
topo(eeg_data_filtered_MI_R_L,events_MI_R_L,sampling_rate,"RIGHT LEG")

