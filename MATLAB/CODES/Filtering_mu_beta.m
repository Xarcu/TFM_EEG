function [eeg_data_mu,eeg_data_beta] = Filtering_mu_beta(DATA)

sampling_rate = DATA.srate; 
[b_notch, a_notch] = iirnotch(50 / (sampling_rate / 2), 50 / (sampling_rate / 2) / 35);

% Define the frequency ranges for mu and beta waves
mu_range = [8, 12];
beta_range = [13, 30];

% Butterworth filter for mu waves
[b_mu, a_mu] = butter(4, mu_range / (sampling_rate / 2));

% Butterworth filter for beta waves
[b_beta, a_beta] = butter(4, beta_range / (sampling_rate / 2));

% Apply bandpass filters
for i = 1:size(DATA.data, 1)
    % Apply notch filter
    eeg_data_notch(i, :) = filtfilt(b_notch, a_notch, double(DATA.data(i, :)));
    % Apply mu bandpass filter
    eeg_data_mu(i, :) = filtfilt(b_mu, a_mu, detrend(eeg_data_notch(i, :), 'constant'));
    % Apply beta bandpass filter
    eeg_data_beta(i, :) = filtfilt(b_beta, a_beta, detrend(eeg_data_notch(i, :), 'constant'));
end

% for i = 1:size(EEG_DATA_L.data, 1)
%     % Apply notch filter
%     eeg_data_notch_L(i, :) = filtfilt(b_notch, a_notch, double(EEG_DATA_L.data(i, :)));
%     % Apply mu bandpass filter
%     eeg_data_mu_L(i, :) = filtfilt(b_mu, a_mu, detrend(eeg_data_notch_L(i, :), 'constant'));
%     % Apply beta bandpass filter
%     eeg_data_beta_L(i, :) = filtfilt(b_beta, a_beta, detrend(eeg_data_notch_L(i, :), 'constant'));
% end

end
