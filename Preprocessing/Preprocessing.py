import numpy as np
import mne
from scipy import signal
from scipy.signal import butter, filtfilt, iirnotch, detrend
from definitions import CHAN_LOC

def perform_ICA(streams, num):
    # Step 2: Load your EEG data from the stream
    if num == 1:
        data = streams[0]['time_series'][:9, :]
        sampling_rate = streams[0]['info']['effective_srate']
    else:
        data = streams[1]['time_series'][:9, :]
        sampling_rate = streams[1]['info']['effective_srate']

    # Step 3: Load your channel locations file
    chanlocs = CHAN_LOC
    
    # Step 4: Create an MNE RawArray object from the data
    num_channels = data.shape[0]
    ch_names = ['EEG' + str(i) for i in range(1, num_channels + 1)]  # Assuming generic channel names
    montage = mne.channels.read_custom_montage(chanlocs)  # Load channel locations
    info = mne.create_info(ch_names=ch_names, sfreq=sampling_rate, ch_types='eeg')
    raw = mne.io.RawArray(data, info)
    raw.set_montage(montage)

    # Step 5: Preprocess the data (bandpass filter between 1-50 Hz)
    raw.filter(1., 50., fir_design='firwin')

    # Step 6: Run ICA
    ica = mne.preprocessing.ICA(n_components=num_channels, method='fastica', random_state=97)
    ica.fit(raw)

    # Optional: Save the ICA results
    ica.save('yourdata_ica.fif')  # Uncomment and modify the path to save the ICA

    return raw, ica


def filtering(EEG_data):
    # Sampling rate
    sampling_rate = EEG_data.info['sfreq']

    # Butterworth bandpass filter between 0.3 and 10 Hz (4th order)
    b_butter, a_butter = butter(4, [0.3, 10], btype='bandpass', fs=sampling_rate)

    # Mu wave frequency range
    mu_range = [8, 12]
    b_mu, a_mu = butter(4, mu_range, btype='bandpass', fs=sampling_rate)

    # Notch filter for power line noise at 50 Hz
    b_notch, a_notch = iirnotch(50, 50 / 35, sampling_rate)

    # Initialize the filtered data
    eeg_data_notch = np.zeros_like(EEG_data.get_data())
    eeg_data_but = np.zeros_like(EEG_data.get_data())
    eeg_data_mu = np.zeros_like(EEG_data.get_data())
    eeg_data_mean = np.zeros_like(EEG_data.get_data())

    # Apply filtering to each channel
    for i in range(EEG_data.get_data().shape[0]):
        # Apply notch filter to remove 50 Hz power line noise
        eeg_data_notch[i, :] = filtfilt(b_notch, a_notch, EEG_data.get_data()[i, :])

        # Apply Butterworth bandpass filter (0.3-10 Hz)
        eeg_data_but[i, :] = filtfilt(b_butter, a_butter, detrend(eeg_data_notch[i, :]))

        # Apply Butterworth filter for mu waves (8-12 Hz)
        eeg_data_mu[i, :] = filtfilt(b_mu, a_mu, detrend(eeg_data_but[i, :]))

        # Calculate the mean for each channel after mu wave filtering
        eeg_data_mean[i, :] = np.mean(eeg_data_mu[i, :])

    # Transpose the filtered data
    eeg_data_but = eeg_data_but.T

    # Zero-mean the data
    channels_mean = np.mean(eeg_data_but, axis=1)
    channels_mean_matrix = np.tile(channels_mean[:, np.newaxis], (1, eeg_data_but.shape[1]))
    EEG_filt = eeg_data_but - channels_mean_matrix

    return EEG_filt


