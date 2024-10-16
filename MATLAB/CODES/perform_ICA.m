function [EEG] = perform_ICA(streams,num)
    
    % Step 1: Start EEGLAB
    eeglab;

    % Step 2: Load your EEG data from the workspace
    if num == 1
        data = streams{1, 1}.time_series(1:9, :);
        sampling_rate = streams{1, 1}.info.effective_srate;
    else
        data = streams{1, 2}.time_series(1:9, :); 
        sampling_rate = streams{1, 2}.info.effective_srate;
    end  
    % Step 3: Load your channel locations file
    chanlocs = 'G:\Users\Public\Documents\USB\Master\Segon semestre\Human_Machine_Interface\eeglab_2023\eeglab2023\sample_locs\Standard-10-20-Cap10.txt';
    
    % Step 4: Create an EEG structure from your matrix
    num_channels = size(data, 1);
    %sampling_rate = streams{1, 1}.info.effective_srate;

    % Create the EEG structure with the locs file
    EEG = pop_importdata('data', data, 'srate', sampling_rate, 'nbchan', num_channels, 'chanlocs', chanlocs); 

    % Step 5: Preprocess the data (optional)
    EEG = pop_eegfiltnew(EEG, 1, 50); % Bandpass filter between 1-50 Hz

    % Step 6: Run ICA
    EEG = pop_runica(EEG, 'extended', 1);
    
    % Optional: Save the EEG dataset with ICA weights
    % pop_saveset(EEG, 'filename', 'yourdata_ica.set', 'filepath', 'path/to/save/');  % Uncomment and modify to save the dataset
    
end
