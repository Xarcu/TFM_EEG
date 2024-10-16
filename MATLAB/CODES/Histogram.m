function [] = Generic_INFO(EEG_DATA_R,EEG_DATA_L)
%HISTOGRAM Summary of this function goes here
%% Histogram 

% Create a histogram for Cz
figure;
histogram(EEG_DATA_R.data(5,:), 50); % 50 bins
xlabel('Amplitude');
ylabel('Frequency');
title('Histogram of EEG Signal for EEG DATA R');

% Create a histogram for Cz
figure;
histogram(EEG_DATA_L.data(5,:), 50); % 50 bins
xlabel('Amplitude');
ylabel('Frequency');
title('Histogram of EEG Signal for EEG DATA L');

end

