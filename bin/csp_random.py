import argparse
import os
import numpy as np
import mne
import pyxdf
import json


"""
This script processes a single XDF file to extract EEG data and associated event markers. The main functionality includes:
1. **Loading XDF Files**: Reads the EEG data and event markers from the file using the `pyxdf` library.
2. **Processing Data**: Separates EEG data and event markers, ensuring the data is aligned and correctly formatted.
3. **Saving Processed Data**: Saves:
   - Raw EEG data in `.fif` format using the MNE library.
   - Event timestamps and labels in a `.json` file.
4. **Flexibility**: Allows specification of the input XDF file and output directory via command-line arguments.
   
The script is designed for EEG analysis workflows and ensures compatibility with standard EEG formats and tools.
"""

def load_xdf_file(filepath):
    """Load the XDF file using pyxdf and extract EEG data and events."""
    streams, _ = pyxdf.load_xdf(filepath)
    eeg_data, sampling_rate, timestamps = None, None, None
    event_timestamps, event_labels = [], []

    for stream in streams:
        print(f"Stream name: {stream['info']['name'][0]}")
        print(f"Stream type: {stream['info']['type'][0]}")

        if 'EEG' in stream['info']['type'][0]:
            eeg_data = np.array(stream['time_series'])
            sampling_rate = float(stream['info']['effective_srate'])
            timestamps = np.array(stream['time_stamps'])
            print(f"Loaded EEG data with shape: {eeg_data.shape}")

        elif stream['info']['type'][0] == 'Markers':
            print(f"Processing marker stream: {stream['info']['name'][0]}")
            print(f"Marker stream values: {stream['time_series']}")

            for ts, value in zip(stream['time_stamps'], stream['time_series']):
                value_str = str(value[0]).strip()

                if value_str in {'p', 'n'}:
                    event_labels.append(1 if value_str == 'p' else 0)
                    event_timestamps.append(ts)
                else:
                    print(f"Unrecognized marker value: {value_str}")

    # Validate streams
    if eeg_data is None or sampling_rate is None:
        raise ValueError("No EEG data found in the XDF file.")
    
    if len(event_timestamps) != len(event_labels):
        raise ValueError("Mismatch between the number of event timestamps and labels.")

    return eeg_data, sampling_rate, timestamps, event_timestamps, event_labels

def save_processed_data(output_dir, eeg_data, sampling_rate, timestamps, events, labels):
    """Save raw EEG data and events to files."""
    os.makedirs(output_dir, exist_ok=True)

    # Validate channel count matches EEG data
    ch_names = ['F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'GND']
    if eeg_data.shape[1] != len(ch_names):
        raise ValueError(f"Mismatch between EEG data channels ({eeg_data.shape[1]}) and channel names ({len(ch_names)})")

    # Save raw EEG data as a .fif file
    info = mne.create_info(ch_names=ch_names, sfreq=sampling_rate, ch_types='eeg')
    raw = mne.io.RawArray(eeg_data.T, info)
    fif_path = os.path.join(output_dir, "eeg_raw.fif")
    raw.save(fif_path, overwrite=True)
    print(f"Saved raw EEG data to {fif_path}")

    # Save event timestamps and labels as a JSON file
    events_data = {
        "timestamps": events,
        "labels": labels
    }
    json_path = os.path.join(output_dir, "events_labels.json")
    with open(json_path, "w") as json_file:
        json.dump(events_data, json_file, indent=4)
    print(f"Saved events and labels to {json_path}")

def process_single_xdf(xdf_file, output_dir):
    """Process a single XDF file and save EEG data and events."""
    eeg_data, sampling_rate, timestamps, event_timestamps, event_labels = load_xdf_file(xdf_file)

    print("Extracted event timestamps:", event_timestamps)
    print("Extracted event labels:", event_labels)

    save_processed_data(output_dir, eeg_data, sampling_rate, timestamps, event_timestamps, event_labels)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a single XDF file and extract EEG data and events.")
    parser.add_argument('-i', '--input_file', required=True, help="Path to the input XDF file.")
    parser.add_argument('-o', '--output_dir', required=True, help="Directory to save processed data.")
    args = parser.parse_args()

    process_single_xdf(args.input_file, args.output_dir)
