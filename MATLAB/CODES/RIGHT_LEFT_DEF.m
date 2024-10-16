clear all 
close all 

%% Load Eeglab path
eeglab_path='G:\Users\Public\Documents\USB\Master\Segon semestre\Human_Machine_Interface\eeglab_2023\eeglab2023'; 
addpath(genpath(eeglab_path));

%% LOAD XDF file
currentFolder = fileparts(which(mfilename));
XDF_Matlab = fullfile(currentFolder,'xdf_Matlab');
addpath(XDF_Matlab)

xdfFilePath_Right = "G:\Users\Public\Documents\USB\Feina UPC\EEG\Experiments\PSYCHOPY+BITBRAIN\LAB_RECORDER\OFFLINE\DATASET\SUB_2\RIGHT\sub-P001\ses-S010\eeg\sub-P001_ses-S010_task-Default_run-001_eeg.xdf";
xdfFilePath_Left ="G:\Users\Public\Documents\USB\Feina UPC\EEG\Experiments\PSYCHOPY+BITBRAIN\LAB_RECORDER\OFFLINE\DATASET\SUB_2\LEFT\sub-P001\ses-S004\eeg\sub-P001_ses-S004_task-Default_run-001_eeg.xdf";
xdfFilePath_Random = "G:\Users\Public\Documents\USB\Feina UPC\EEG\Experiments\PSYCHOPY+BITBRAIN\LAB_RECORDER\OFFLINE\DATASET\SUB_2\RANDOM\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf";

[streams_R, fileheader_R] = load_xdf(xdfFilePath_Right);
[streams_L, fileheader_L] = load_xdf(xdfFilePath_Left);
[streams_Rd, fileheader_Rd] = load_xdf(xdfFilePath_Random);

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
try
    EEG_DATA_Rd = perform_ICA(streams_Rd, 1);
catch
    EEG_DATA_Rd = perform_ICA(streams_Rd, 2);
end


%% PWD & Histogram 

Generic_INFO(EEG_DATA_R,"R");
Generic_INFO(EEG_DATA_L,"L");
Generic_INFO(EEG_DATA_Rd,"Rd");

%% FILTERING

% Obtaining mu and beta bands for Right and Left dataset

[eeg_data_mu_R,eeg_data_beta_R] = Filtering_mu_beta(EEG_DATA_R);
[eeg_data_mu_L,eeg_data_beta_L] = Filtering_mu_beta(EEG_DATA_L); 
[eeg_data_mu_Rd,eeg_data_beta_Rd] = Filtering_mu_beta(EEG_DATA_Rd);

% Plot filtered data for a specific channel (e.g., channel 5)
figure;
subplot(3, 1, 1);
plot(eeg_data_mu_R(5, :));
title('Filtered EEG Data (Mu Band) - Right');
xlabel('Samples');
ylabel('Amplitude');

subplot(3, 1, 2);
plot(eeg_data_beta_R(5, :));
title('Filtered EEG Data (Beta Band) - Right');
xlabel('Samples');
ylabel('Amplitude');

subplot(3, 1, 3);
plot(eeg_data_beta_Rd(5, :));
title('Filtered EEG Data (Beta Band) - Random');
xlabel('Samples');
ylabel('Amplitude');


%% EEG data filtered (generic filtering)
eeg_filt_R = Filtering(EEG_DATA_R);
eeg_filt_L = Filtering(EEG_DATA_L);
eeg_filt_Rd = Filtering(EEG_DATA_Rd);

%% Representation EEG_RIGHT
events_beta_R = EEG_Plot_Filtering(streams_R,eeg_data_beta_R,'R', "beta");
events_mu_R = EEG_Plot_Filtering(streams_R,eeg_data_mu_R,'R', "mu");
events_R = EEG_Plot_Filtering(streams_R,eeg_filt_R,'R', "all");

%% Representation EEG_LEFT
events_beta_L = EEG_Plot_Filtering(streams_L,eeg_data_beta_L,'L', "beta");
events_mu_L = EEG_Plot_Filtering(streams_L,eeg_data_mu_L,'L', "mu");
events_L = EEG_Plot_Filtering(streams_L,eeg_filt_L,'L', "all");

%% Representation EEG_Random
events_beta_Rd = EEG_Plot_Filtering(streams_Rd,eeg_data_beta_Rd,"Rd", "beta");
events_mu_Rd = EEG_Plot_Filtering(streams_Rd,eeg_data_mu_Rd,"Rd", "mu");
events_Rd = EEG_Plot_Filtering(streams_Rd,eeg_filt_Rd,"Rd", "all");

%% TOPOPLOT
mean_L_data = Topoplot(eeg_filt_L, events_L,sampling_rate, "L", "all bands");

mean_R_data = Topoplot(eeg_filt_R, events_R,sampling_rate, "R", "all bands");


Topo_comparison(mean_R_data, mean_L_data, "all bands")







