import argparse
import os
import numpy as np
import mne
import pyxdf
import json
from mne.decoding import CSP
import joblib
import pandas as pd
import re


def load_xdf_file(filepath):
    """Load the XDF file using pyxdf and log details about each stream."""
    streams, header = pyxdf.load_xdf(filepath)
    print(f"Loaded XDF file: {filepath}")
    print(f"Number of streams: {len(streams)}")
    for idx, stream in enumerate(streams):
        stream_name = stream['info']['name'][0]
        stream_srate = stream['info']['effective_srate']
        stream_shape = np.array(stream['time_series']).shape
        print(f"Stream {idx + 1} - Name: {stream_name}, Sampling rate: {stream_srate}, Shape: {stream_shape}")
    return streams, header

def find_xdf_files(base_dir):
    """Find all .xdf files within the given directory and its subdirectories."""
    file_paths = []
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".xdf"):
                file_paths.append(os.path.join(root, file))
    return file_paths

def perform_ICA(streams, side_label, xdf_filename, base_save_dir, marker=None):
    """Perform ICA and preprocess EEG data."""
    data, sampling_rate, timestamps, event_timestamps = None, None, None, []

    # Extract EEG data
    for idx, stream in enumerate(streams):
        stream_data = np.array(stream['time_series'])
        if stream_data.shape[1] == 10 and stream['info']['effective_srate'] > 0:
            data = stream_data
            sampling_rate = stream['info']['effective_srate']
            timestamps = np.array(stream['time_stamps'])
            print(f"Using EEG data from stream {idx + 1} with shape: {data.shape}")
            break
    else:
        raise ValueError("No valid EEG data found in the streams.")

    # Baseline correction
    baseline_duration = 10  # seconds
    baseline_samples = int(baseline_duration * sampling_rate)
    baseline = np.mean(data[:baseline_samples, :], axis=0)
    data -= baseline

    print(f"Baseline corrected data shape: {data.shape}")

    # Identify event timestamps
    for idx, stream in enumerate(streams):
        stream_data = np.array(stream['time_series'])
        if stream_data.shape[1] == 1:  # Event markers
            for ts, value in zip(stream['time_stamps'], stream_data[:, 0]):
                if marker is None or value == marker:
                    event_timestamps.append(ts)

    print(f"Detected {len(event_timestamps)} events for marker '{marker}'")

    if len(event_timestamps) == 0:
        raise ValueError(f"No events detected for marker '{marker}' in file: {xdf_filename}")

    # Create MNE Raw object
    ch_names = ['F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'GND']
    info = mne.create_info(ch_names=ch_names, sfreq=sampling_rate, ch_types='eeg')
    raw = mne.io.RawArray(data.T, info)

    # Filter the data
    filtered_raw = raw.copy().filter(l_freq=0.3, h_freq=30)
    filtered_raw.notch_filter(freqs=[50], method='iir')

    print(f"Filtered raw data shape: {filtered_raw.get_data().shape}")

    # Extract event segments
    segment_duration_samples = int(1.5 * sampling_rate)
    event_data_segments = []
    labels = []
    for event_time in event_timestamps:
        event_index = np.searchsorted(timestamps, event_time)
        end_index = event_index + segment_duration_samples
        if end_index <= data.shape[0]:
            event_data_segments.append(data[event_index:end_index, :].tolist())
            labels.append(0 if side_label == 'L' else 1)

    print(f"Extracted {len(event_data_segments)} event segments")

    # Save event data
    subject_id = re.findall(r'ses-S\d+', xdf_filename)[0].split('-')[1].zfill(3)
    output_dir = os.path.join(base_save_dir, side_label, f"{subject_id}")
    os.makedirs(output_dir, exist_ok=True)

    json_path = os.path.join(output_dir, f"sub-{subject_id}_{side_label}_event_data.json")
    with open(json_path, "w") as json_file:
        json.dump({
            "side": side_label,
            "event_data_segments": event_data_segments,
            "labels": labels
        }, json_file, indent=4)

    print(f"Saved event data to {json_path}")


def prepare_csp_data(base_save_dir):
    """Load data for CSP from JSON files."""
    data, labels = [], []
    max_length = None

    for side in ['L', 'R']:
        side_dir = os.path.join(base_save_dir, side)
        if os.path.exists(side_dir):
            for subject_folder in os.listdir(side_dir):
                json_path = os.path.join(side_dir, subject_folder, f"sub-{subject_folder}_{side}_event_data.json")
                if os.path.exists(json_path):
                    with open(json_path, "r") as f:
                        event_data = json.load(f)
                    for segment in event_data['event_data_segments']:
                        segment_array = np.array(segment)
                        if segment_array.ndim == 2:
                            if max_length is None:
                                max_length = segment_array.shape[0]
                            if segment_array.shape[0] > max_length:
                                segment_array = segment_array[:max_length, :]
                            elif segment_array.shape[0] < max_length:
                                pad_width = max_length - segment_array.shape[0]
                                segment_array = np.pad(segment_array, ((0, pad_width), (0, 0)), mode='constant')
                            segment_array = segment_array.T
                            data.append(segment_array)
                            labels.append(0 if side == 'L' else 1)

    data = np.array(data)
    labels = np.array(labels)

    print(f"Prepared CSP data shape: {data.shape}, labels shape: {labels.shape}")

    if data.ndim != 3:
        raise ValueError(f"Data must be 3D (samples, channels, time points), but got shape: {data.shape}")

    return data, labels


def compute_csp_features(base_save_dir, mode):
    """Compute CSP features and save the CSP model."""
    data, labels = prepare_csp_data(base_save_dir)

    print(f"Loaded data shape: {data.shape}, labels shape: {labels.shape}")

    reshaped_data = data.transpose(0, 2, 1)
    print(f"Reshaped data for CSP: {reshaped_data.shape}")

    if mode == 'default':
        csp = CSP(n_components=4, reg=None, log=True)
        csp_features = csp.fit_transform(reshaped_data, labels)

        print(f"CSP patterns shape: {csp.patterns_.shape}")
        print(f"CSP filters shape: {csp.filters_.shape}")

        csp_model_path = os.path.join(base_save_dir, 'csp_model.pkl')
        joblib.dump(csp, csp_model_path)
        print(f"Saved CSP model to {csp_model_path}")
    elif mode == 'random':
        csp_model_path = os.path.join(base_save_dir, 'csp_model.pkl')
        if not os.path.exists(csp_model_path):
            raise ValueError(f"CSP model not found at {csp_model_path}. Train the model in 'default' mode first.")

        csp = joblib.load(csp_model_path)
        csp_features = csp.transform(reshaped_data)
        print(f"Computed CSP features with shape: {csp_features.shape}")
    else:
        raise ValueError("Invalid mode. Use 'default' or 'random'.")

    save_csp_features_labels(csp_features, labels, base_save_dir, mode)


def save_csp_features_labels(csp_features, labels, base_save_dir, mode):
    """Save the CSP features and labels to a Parquet file."""
    df = pd.DataFrame(csp_features)
    df['labels'] = labels

    filename = 'csp_features_labels_validation.parquet' if mode == 'random' else 'csp_features_labels.parquet'
    parquet_path = os.path.join(base_save_dir, filename)
    df.to_parquet(parquet_path)
    print(f"Saved CSP features and labels to {parquet_path}")



def process_all_xdf_files(base_dir, base_save_dir, mode):
    """Process XDF files based on the chosen mode."""
    if mode == 'default':
        left_dir = os.path.join(base_dir, 'LEFT')
        right_dir = os.path.join(base_dir, 'RIGHT')
        left_files = find_xdf_files(left_dir)
        right_files = find_xdf_files(right_dir)

        print(f"Found {len(left_files)} files in LEFT directory.")
        print(f"Found {len(right_files)} files in RIGHT directory.")

        for left_file in left_files:
            print(f"Processing {left_file}...")
            streams, header = load_xdf_file(left_file)
            perform_ICA(streams, 'L', left_file, base_save_dir)

        for right_file in right_files:
            print(f"Processing {right_file}...")
            streams, header = load_xdf_file(right_file)
            perform_ICA(streams, 'R', right_file, base_save_dir)
    elif mode == 'random':
        all_files = find_xdf_files(base_dir)
        print(f"Found {len(all_files)} files in the dataset.")
        for file_path in all_files:
            print(f"Processing {file_path}...")
            streams, header = load_xdf_file(file_path)
            perform_ICA(streams, 'L', file_path, base_save_dir, marker='n')
            perform_ICA(streams, 'R', file_path, base_save_dir, marker='p')
    else:
        raise ValueError("Invalid mode. Use 'default' or 'random'.")
    



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="EEG CSP Feature Extraction")
    parser.add_argument('-b', '--base_dir', required=True, help="Base directory containing EEG data")
    parser.add_argument('-o', '--output_dir', required=True, help="Output directory for processed data")
    parser.add_argument('-m', '--mode', default='default', choices=['default', 'random'],
                        help="Mode for processing: 'default' for separate LEFT/RIGHT, 'random' for mixed events")
    args = parser.parse_args()

    try:
        process_all_xdf_files(args.base_dir, args.output_dir, args.mode)
        compute_csp_features(args.output_dir, args.mode)
    except Exception as e:
        print(f"Error: {e}")
