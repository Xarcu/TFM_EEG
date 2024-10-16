function [] = plotting(description, time_vector,EEG_DATA_Filt,events,sampling_rate,LOC)

plot(time_vector,EEG_DATA_Filt);
hold on;

% Plot event markers
for i = 1:numel(events)
    line([events(i)/sampling_rate, events(i)/sampling_rate], ylim, 'Color', 'red', 'LineStyle', '--'); 
    if LOC == 'R'
        text([events(i)/sampling_rate, events(i)/sampling_rate], ylim, 'R');
    else
        text([events(i)/sampling_rate, events(i)/sampling_rate], ylim, 'L');
    end
end
xlabel('SAMPLES');
ylabel('EEG Data');
title('EEG Data with Event Markers MOTOR IMAGINERY, Cz, MOVING :' + description);




end