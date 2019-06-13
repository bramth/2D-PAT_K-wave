function [] = show_sensor(sensor_data)
    % plot the simulated sensor data
    figure;
    imagesc(sensor_data, [-1, 1]);
    colormap(getColorMap);
    ylabel('Sensor Position');
    xlabel('Time Step');
    colorbar;
   return
end

