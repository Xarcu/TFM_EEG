function [] = topo(EEG_DATA,events,sampling_rate,description)
    figure
    subplot(4,3,1)
    topoplot(mean(EEG_DATA),'Standard-10-20-Cap9.locs')
    colorbar
    colormap('jet')
    title('EEG TOPOPLOT (MEAN)')
    
    for j=1: numel(events)
        % 1. Define the start and end time points of the period you want to analyze
        start_time = events(j)/sampling_rate - 0.1;
        end_time = events(j)/sampling_rate + 0.3;
        
        % 2. Convert the time points to indices using the sampling rate
        start_index = round(start_time * sampling_rate);
        end_index = round(end_time * sampling_rate);
        
        % 3. Extract the EEG data within the specified time window
        eeg_data_period = EEG_DATA(start_index:end_index, :);
        
        subplot(4,3,j+1)
        topoplot(mean(eeg_data_period),'Standard-10-20-Cap9.locs')
        colorbar
        colormap('jet')
        title("EEG TOPOPLOT AT EVENT"+ j +" :" + description+ " MI")
    end
    
    % Create extra space at the top by adjusting the 'Position' of the subplots
    h = findall(gcf,'type','axes'); % Find all axes in the figure
    for i = 1:length(h)
        pos = get(h(i), 'Position'); % Get current position
        pos(2) = pos(2) - 0.05; % Move subplots down by adjusting the y-position
        set(h(i), 'Position', pos); % Set the new position
    end
    
    st = sgtitle("TOPOPLOTS FOR THE "+ numel(events)+ " "+ description+" MOTOR IMAGINERY DETECTED EVENTS",'Color','red');
    st.FontSize = 20;

end