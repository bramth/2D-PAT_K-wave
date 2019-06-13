function [fig] = show_slice(p0_orig,kgrid,p0_recon,kgrid_recon,dim,slice_pos)
    % show slice of pressure distribution
    fig = figure;
    
    if dim == 'x'
        ndim = 2;
    elseif dim == 'y'
        ndim = 1;
    end
    
    % take slice as half
    if slice_pos == 0
        slice_pos = size(p0_orig,ndim)/2;
    end      
    
    % plot a profile for comparison
    if dim == 'y'
        plot(kgrid.y_vec * 1e3, p0_orig(slice_pos, :), 'k--', ...
             kgrid_recon.y_vec * 1e3, p0_recon(slice_pos, :), 'r-')
        xlabel('y-position [mm]');
    elseif dim == 'x'
        plot(kgrid.x_vec * 1e3, p0_orig(:, slice_pos), 'k--', ...
             kgrid_recon.x_vec * 1e3, p0_recon(:,slice_pos), 'r-')
        xlabel('x-position [mm]');
    end
    ylabel('Pressure');
    legend('Initial Pressure', 'Point Reconstruction');
    axis tight;
    %set(gca, 'YLim', [0 2.1]);
end

