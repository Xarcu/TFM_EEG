function [mean_X_data] = Topoplot(EEG_filt_DATA, Events,sampling_rate, hemisphere, band)

X_data = [];
for j = 1:numel(Events)
    start_time = Events(j) / sampling_rate;
    end_time = start_time + 2.8;
    
    start_index = round(start_time * sampling_rate);
    end_index = round(end_time * sampling_rate);
    try
        eeg_data_period = EEG_filt_DATA(:,start_index:end_index);
        X_data = [X_data; eeg_data_period'];
    catch
        eeg_data_period = EEG_filt_DATA(start_index:end_index,:);  
        X_data = [X_data; eeg_data_period];
    end
end

mean_X_data = mean(X_data, 1);

% Define the number of columns to ensure larger subplots
num_cols = 5;

% Plot for R events
num_events = numel(Events);
num_rows = ceil((num_events + 1) / num_cols);

figure('Position', [100, 100, 1500, 800]); % Increase figure size
subplot(num_rows, num_cols, 1)
topoplot(mean_X_data, 'Standard-10-20-Cap9.locs','maplimits', [-1, 1])
colorbar
colormap('jet')
title("EEG TOPOPLOT (MEAN) for "+ hemisphere+ " Events for "+ band)

for j = 1:num_events
    start_time = Events(j) / sampling_rate;
    end_time = Events(j) / sampling_rate + 2.5;

    start_index = round(start_time * sampling_rate);
    end_index = round(end_time * sampling_rate);

    try
        eeg_data_period = EEG_filt_DATA(: , start_index:end_index);
    catch
        eeg_data_period = EEG_filt_DATA(start_index:end_index,:);
    end

    subplot(num_rows, num_cols, j + 1)
    topoplot(mean(eeg_data_period),'Standard-10-20-Cap9.locs','maplimits', [-1, 1])
    colorbar
    colormap('jet')
    title("EEG TOPOPLOT AT "+ hemisphere+" EVENT " + j)
end

sgtitle("TOPOPLOTS FOR "+ hemisphere+" MOTOR IMAGERY EVENTS FOR "+ band,'Color','red', 'FontSize', 20);

end

