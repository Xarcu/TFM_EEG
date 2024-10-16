function [] = Generic_INFO(EEG_DATA,hemisphere)
%Power spectral density and Histogram representation

%% Power spectral density
% Define parameters
window = 256; % Length of each segment
noverlap = 128; % Number of overlapping samples
nfft = 512; % Number of FFT points
sampling_rate = EEG_DATA.srate;

% Calculate PSD using Welch's method for Cz
[pxx, f] = pwelch(EEG_DATA.data(5,:), window, noverlap, nfft, sampling_rate);

% Plot the PSD
figure;
plot(f, 10*log10(pxx));
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
if hemisphere == "R"
    title('Power Spectral Density EEG_DATA_R');
elseif hemisphere == "L"
    title('Power Spectral Density EEG_DATA_L');
elseif hemisphere == "Rd"
    title('Power Spectral Density Random');
end
%% Histogram 

% Create a histogram for Cz
figure;
histogram(EEG_DATA.data(5,:), 50); % 50 bins
xlabel('Amplitude');
ylabel('Frequency');
if hemisphere == "R"
    title('Histogram of EEG Signal for EEG DATA R');
elseif hemisphere == "L"
    title('Histogram of EEG Signal for EEG DATA L');
elseif hemisphere == "Rd"
    title('Histogram of EEG Signal for EEG DATA Random');
end

end

