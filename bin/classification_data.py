import argparse
import os
import numpy as np
import mne
import joblib
from pylsl import StreamInlet, resolve_stream
import time
import threading
import json

# Global variables
stop_event = threading.Event()
baseline_event = threading.Event()
baseline_data = []
baseline_mean = None
lock = threading.Lock()

def load_model(model_path):
    """Load a pre-trained model."""
    return joblib.load(model_path)

def receive_lsl_data(inlet, duration=1.0):
    """Receive data from the LSL stream for a given duration."""
    start_time = time.time()
    data = []
    timestamps = []
    while (time.time() - start_time) < duration:
        sample, timestamp = inlet.pull_sample()
        if sample is not None:
            data.append(sample)
            timestamps.append(timestamp)
    return np.array(data), np.array(timestamps)

def chunk_offline_data(data, chunk_size, sfreq):
    """Yield data chunks to simulate streaming for offline mode."""
    num_samples = data.shape[1]
    step = int(chunk_size * sfreq)  # Calculate step size in samples
    for start in range(0, num_samples, step):
        yield data[:, start:start + step].T  # Transpose to match sample-first format

def read_offline_fif(fif_file_path):
    """Read data from a .fif file."""
    print(f"Reading data from {fif_file_path}...")
    raw = mne.io.read_raw_fif(fif_file_path, preload=True)
    return raw.get_data(), raw.info['sfreq']  # Return data and sampling frequency

def process_and_classify(data_source, csp, classifier, feedback_duration=1.0, mode="online", sfreq=250, labels=None):
    """Process incoming data and classify using the trained CSP-based model."""
    global baseline_mean, baseline_data

    print("CSP model and classifier loaded successfully.")
    print("Press Enter to stop the program.")
    print("Waiting for data...")

    correct_predictions = 0
    total_predictions = 0
    label_index = 0

    while not stop_event.is_set():
        # Fetch data: online from LSL, offline chunked
        if mode == "online":
            data, _ = receive_lsl_data(data_source, duration=feedback_duration)
        else:  # Simulate streaming in offline mode
            try:
                data = next(data_source)
            except StopIteration:
                print("End of offline data.")
                break

        if data.size == 0:
            continue

        print(f"Received {data.shape[0]} samples.")

        # Prepare channel info and sampling rate
        ch_names = ['F3', 'Fz', 'F4', 'C3', 'Cz', 'C4', 'P3', 'Pz', 'P4', 'GND']
        if data.shape[1] != len(ch_names):
            print(f"Unexpected number of channels: {data.shape[1]} (expected {len(ch_names)})")
            continue

        # Handle baseline recording
        with lock:
            if baseline_event.is_set():
                baseline_data.append(data)
                print("Collecting baseline data...")
                continue  # Skip classification while collecting baseline

        # Compute baseline mean if enough data has been collected
        if baseline_mean is None and len(baseline_data) > 0:
            with lock:
                all_baseline_data = np.vstack(baseline_data)
                baseline_mean = np.mean(all_baseline_data, axis=0)
                print(f"Baseline computed: {baseline_mean}")
                baseline_data = []  # Clear baseline data storage

        # Subtract baseline if available
        if baseline_mean is not None:
            data -= baseline_mean

        # Create MNE Raw object
        info = mne.create_info(ch_names=ch_names, sfreq=sfreq, ch_types='eeg')
        raw = mne.io.RawArray(data.T, info)

        # Filter the data
        filtered_raw = raw.copy().filter(l_freq=0.3, h_freq=30, fir_design='firwin', filter_length='auto', phase='zero')
        filtered_raw.notch_filter(freqs=[50], method='iir')

        # Reshape data for CSP transformation
        reshaped_data = filtered_raw.get_data()[np.newaxis, :, :]  # Add a trial dimension
        if reshaped_data.shape[1] != len(csp.patterns_):  # Check number of channels matches CSP training
            print(f"Mismatch in channels: expected {len(csp.patterns_)}, got {reshaped_data.shape[1]}")
            continue

        csp_features = csp.transform(reshaped_data)  # Output shape: (1, n_components)

        # Classify using the trained model
        try:
            prediction = classifier.predict(csp_features)[0]  # Extract single prediction
        except Exception as e:
            print(f"Error during classification: {e}")
            continue

        # Determine prediction outcome
        print(f"Prediction: {'LEFT' if prediction == 0 else 'RIGHT'}")
        if labels is not None and label_index < len(labels):
            expected_label = labels[label_index]
            print(f"Expected: {expected_label}, Predicted: {prediction}")
            if prediction == expected_label:
                correct_predictions += 1
            total_predictions += 1
            label_index += 1



    if total_predictions > 0:
        accuracy = correct_predictions / total_predictions * 100
        print(f"Correct: {correct_predictions}, Total: {total_predictions}")
        print(f"Classification Accuracy: {accuracy:.2f}%")
    else:
        print("No predictions made.")


def monitor_keyboard():
    """Monitor keyboard input to stop the program or handle baseline collection."""
    global baseline_event

    while not stop_event.is_set():
        key = input("Press 'S' to toggle baseline recording, or Enter to stop: ").strip().upper()
        if key == "S":
            with lock:
                if baseline_event.is_set():
                    baseline_event.clear()
                    print("Baseline recording stopped.")
                else:
                    baseline_event.set()
                    print("Baseline recording started.")
        elif key == "":
            stop_event.set()
            print("Stopping the program...")

def main(base_save_dir, csp_model_path, classifier_model_path, mode, feedback_duration=1.0, offline_folder=None, labels_file=None):
    """Main function to set up LSL stream and process data."""
    # Load CSP and classifier models
    csp = load_model(csp_model_path)
    classifier = load_model(classifier_model_path)

    sfreq = None
    labels = None  # Initialize labels to None to avoid UnboundLocalError

    if mode == "online":
        print("Looking for an EEG stream...")
        streams = resolve_stream('type', 'EEG')
        if not streams:
            print("No EEG streams found. Ensure the LSL stream is active.")
            return

        inlet = StreamInlet(streams[0])
        sfreq = inlet.info().nominal_srate()  # Get the sampling frequency
        data_source = inlet
    elif mode == "offline":
        if not offline_folder or not offline_folder.endswith('.fif'):
            print("Invalid .fif file specified for offline mode.")
            return

        print(f"Reading offline data from {offline_folder}...")
        try:
            offline_data, sfreq = read_offline_fif(offline_folder)
        except ValueError as e:
            print(e)
            return

        data_source = iter(chunk_offline_data(offline_data, feedback_duration, sfreq))
        
        if labels_file:
            try:
                with open(labels_file, 'r') as file:
                    labels = np.array(json.load(file))
            except Exception as e:
                print(f"Error loading labels file: {e}")
                return
    else:
        print("Invalid mode specified. Use 'online' or 'offline'.")
        return

    # Start a thread to monitor keyboard input
    keyboard_thread = threading.Thread(target=monitor_keyboard, daemon=True)
    keyboard_thread.start()

    # Process and classify data
    process_and_classify(data_source, csp, classifier, feedback_duration, mode, sfreq, labels=labels)



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Real-time EEG Classification with CSP and Trained Classifier")
    parser.add_argument('-c', '--csp_model_path', required=True, help="Path to the pre-trained CSP model")
    parser.add_argument('-k', '--classifier_model_path', required=True, help="Path to the pre-trained classifier model")
    parser.add_argument('-d', '--duration', type=float, default=0.25, help="Duration for feedback in seconds")
    parser.add_argument('-m', '--mode', required=True, choices=['online', 'offline'], help="Mode: 'online' for LSL stream or 'offline' for data files")
    parser.add_argument('-f', '--offline_folder', help="Path to the .fif file (required in offline mode)")
    parser.add_argument('-l', '--labels_file', help="Path to the file containing ground truth labels for offline data")
    args = parser.parse_args()

    main("dummy_base_save_dir", args.csp_model_path, args.classifier_model_path, args.mode, args.duration, args.offline_folder, args.labels_file)


