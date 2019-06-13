function [fig] = show_result(p0_orig,kgrid,p0_recon,kgrid_recon,cart_sensor_mask)
    fig = figure;
    pause(0.0001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
    pause(0.0001);

    subplot(1,3,1);
    imagesc(cart2grid(kgrid, cart_sensor_mask)+p0_orig, [-1, 1]);
    ylabel('x-position [mm]');
    xlabel('y-position [mm]');
    title('Original image');
    axis image;
    colormap(getColorMap);
    colorbar;
    
    subplot(1,2,2);
    imagesc(cart2grid(kgrid_recon, cart_sensor_mask)+p0_recon, [-1, 1]);
    ylabel('x-position [mm]');
    xlabel('y-position [mm]');
    title('Reconstructed image');
    axis image;
    colormap(getColorMap);
    colorbar;
    
    return
end
