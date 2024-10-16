function [events] = EEG_Plot_Filtering(streams, DATA, hemisphere, band)

    try
        duration = streams{1, 1}.segments.duration;
        sampling_rate = streams{1, 1}.segments.effective_srate;
    catch
        duration = streams{1, 2}.segments.duration;
        sampling_rate = streams{1, 2}.segments.effective_srate;
    end
    
    time_vector = (0:(length(DATA) - 1)) / sampling_rate;
    
    try
        events = (streams{1, 1}.time_stamps - streams{1, 2}.segments.t_begin) * sampling_rate;
    catch
        events = (streams{1, 2}.time_stamps - streams{1, 1}.segments.t_begin) * sampling_rate;
    end
    
    figure;
    try
        plot(time_vector, DATA(5, :));
    catch
        plot(time_vector, DATA(:, 5));  
    end
    hold on;
    
    for i = 1:numel(events)
        line([events(i) / sampling_rate, events(i) / sampling_rate], ylim, 'Color', 'red', 'LineStyle', '--');
        
        % Check and modify time_series for streams{1, 1}
        if iscell(streams{1, 1}.time_series)
            if char(streams{1, 1}.time_series{i}) == 'p'
                streams{1, 1}.time_series{i} = 'R';
            elseif char(streams{1, 1}.time_series{i}) == 'n'
                streams{1, 1}.time_series{i} = 'L';
            end
            text(events(i) / sampling_rate, max(ylim), char(streams{1, 1}.time_series{i}));
        
        % Check and modify time_series for streams{1, 2}
        elseif iscell(streams{1, 2}.time_series)
            if char(streams{1, 2}.time_series{i}) == 'p'
                streams{1, 2}.time_series{i} = 'R';
            elseif char(streams{1, 2}.time_series{i}) == 'n'
                streams{1, 2}.time_series{i} = 'L';
            end
            text(events(i) / sampling_rate, max(ylim), char(streams{1, 2}.time_series{i}));
        end
    end
    
    xlabel('SAMPLES');
    ylabel('EEG Data');
    if hemisphere == 'R' && band == "mu"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (for MU band RIGHT)');
    elseif hemisphere == 'R' && band == "beta"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (for BETA band RIGHT)');
    elseif hemisphere == 'L' && band == "mu"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (for MU band LEFT)');
    elseif hemisphere == 'L' && band == "beta"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (for BETA band LEFT)');
    elseif hemisphere == "Rd" && band == "mu"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (for MU band RANDOM)');
    elseif hemisphere == "Rd" && band == "beta"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (for BETA band RANDOM)');
    elseif hemisphere == "R" && band == "all"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (RIGHT)');
    elseif hemisphere == "L" && band == "all"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (LEFT)');
    elseif hemisphere == "Rd" && band == "all"
        title('EEG Data with Event Markers MOTOR IMAGERY, Cz (RANDOM)');    
    end
    hold off
end
