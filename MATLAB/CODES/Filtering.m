function [EEG_filt] = Filtering(EEG_data)

sampling_rate = EEG_data.srate;
[b_butter, a_butter] = butter(4, [0.3, 10] / (sampling_rate / 2));

% Define the frequency ranges for mu waves
mu_range = [8, 12];

% Butterworth filter for mu waves
[b_mu, a_mu] = butter(4, mu_range / (sampling_rate / 2)); % Increased filter order

% Notch filter for power line noise (assuming 50 Hz)
[b_notch, a_notch] = iirnotch(50 / (sampling_rate / 2), 50 / (sampling_rate / 2) / 35);

for i = 1:size(EEG_data.data, 1)
    % Apply notch filter
    eeg_data_notch(i, :) = filtfilt(b_notch, a_notch, double(EEG_data.data(i, :)));
    % Apply bandpass filter
    eeg_data_but(i, :) = filtfilt(b_butter, a_butter, detrend(eeg_data_notch(i, :), 'constant'));
    % Filter for mu waves
    eeg_data_mu(i, :) = filtfilt(b_mu, a_mu, detrend(eeg_data_but(i, :), 'constant'));
    eeg_data_mean(i, :) = mean(eeg_data_mu(i, :));
end

eeg_data_but = eeg_data_but';
channels_mean = mean(eeg_data_but, 2);
channels_mean_matrix = repmat(channels_mean, 1, size(eeg_data_but, 2));
EEG_filt = eeg_data_but - channels_mean_matrix;


end
% 
% % BANDPASS FILTER, when I increase butterworth order all the filtered data
% % becomes NaN, don't know why. 
% sampling_rate = EEG_data.srate;
% [b_butter,a_butter] = butter(2,[0.3,10]/(sampling_rate/2)); 
% 
% %Define the frequency ranges for mu and beta waves
% mu_range = [8, 13];
% 
% % Butterworth filter for mu waves
% [b_mu, a_mu] = butter(2, mu_range / (sampling_rate / 2));
% 
% % Butterworth filtering of 0.3 to 10 Hz is applied for all 10 channels and
% % zero mean is performed to avoid some noise. 
% for i=1:length(EEG_data.data(:,1))
% 
% 
%     eeg_data_but_notch(i,:) = filtfilt(b_butter,a_butter,detrend(EEG_data.data(i,:),'constant')); 
%     % Filter for mu waves
%     eeg_data_mu(i, :) = filtfilt(b_mu, a_mu, detrend(eeg_data_but_notch(i, :), 'constant'));
%     eeg_data_mean(i,:) = mean(eeg_data_mu(i,:));
% 
% end
% 
% eeg_data_but_notch = eeg_data_but_notch';
% channels_mean = mean(eeg_data_but_notch,2); 
% channels_mean_matrix =  repmat(channels_mean, 1, size(eeg_data_but_notch, 2)); % Replicate along the second dimension (columns)
% 
% 
% EEG_filt = eeg_data_but_notch-channels_mean_matrix;
% 
% end

% function [EEG_filt] = Filtering(EEG_data)
% 
% % Sampling rate
% sampling_rate = EEG_data.srate;
% 
% % Define the frequency ranges for mu and beta waves
% mu_range = [8, 13];
% beta_range = [14, 38];
% 
% % Butterworth filter for mu waves
% [b_mu, a_mu] = butter(2, mu_range / (sampling_rate / 2));
% 
% % Butterworth filter for beta waves
% [b_beta, a_beta] = butter(2, beta_range / (sampling_rate / 2));
% 
% % Initialize filtered data matrices
% eeg_data_mu = zeros(size(EEG_data.data));
% eeg_data_beta = zeros(size(EEG_data.data));
% 
% % Apply filters to each channel
% for i = 1:size(EEG_data.data, 1)
%     % Filter for mu waves
%     eeg_data_mu(i, :) = filtfilt(b_mu, a_mu, detrend(EEG_data.data(i, :), 'constant'));
%     % Filter for beta waves
%     eeg_data_beta(i, :) = filtfilt(b_beta, a_beta, detrend(EEG_data.data(i, :), 'constant'));
% end
% 
% % Combine mu and beta filtered data
% EEG_filt = eeg_data_mu + eeg_data_beta;
% 
% % Ensure the length of the filtered data matches the original data
% if size(EEG_filt, 2) ~= size(EEG_data.data, 2)
%     error('Filtered data length does not match original data length.');
% end
% 
% end
