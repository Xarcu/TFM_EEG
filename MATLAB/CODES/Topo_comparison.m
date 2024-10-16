function [] = Topo_comparison(mean_R_data,mean_L_data,band)
    % Topoplot for mean of all 'R' events
    subplot(1, 2, 1)
    topoplot(mean_R_data, 'Standard-10-20-Cap9.locs', 'maplimits', [-0.5, 0.5])
    colorbar
    colormap('jet')
    title("EEG TOPOPLOT (MEAN) for all 'R' Events for "+ band)
    
    % Topoplot for mean of all 'L' events
    subplot(1, 2, 2)
    topoplot(mean_L_data, 'Standard-10-20-Cap9.locs', 'maplimits', [-0.5, 0.5])
    colorbar
    colormap('jet')
    title("EEG TOPOPLOT (MEAN) for all 'L' Events for "+ band)
    
    sgtitle("TOPOPLOTS FOR 'R' AND 'L' MOTOR IMAGERY EVENTS for "+ band, 'Color', 'red', 'FontSize', 20);
end

