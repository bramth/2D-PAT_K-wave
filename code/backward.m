function [p0_recon,kgrid_recon] = backward(sensor,kgrid,dim,input_args,varargin)
    % Backward function
    
    p = inputParser;
    
    defaultSpeed = 1500;
    defaultAbsorption = false;
    defaultIC = true;
    
    addRequired(p,'sensor')
    addRequired(p,'kgrid')
    addRequired(p,'dim')
    addRequired(p,'input_args',@iscell)
    addOptional(p,'SoundSpeed',defaultSpeed,@isnumeric);
    addOptional(p,'Absorption',defaultAbsorption,@islogical);
    addOptional(p,'InverseCrime',defaultIC,@islogical);
    
    parse(p,sensor,kgrid,dim,input_args,varargin{:})
    
    % optionally create a new computation grid to avoid inverse crime
    % DOES NOT WORK AT THE MOMENT DUE TO SENSOR INTERPOLATION IN MAIN
    % SCRIPT, NEEDING NX,NY ETC.
    if p.Results.InverseCrime == true
        Nx = p.Results.kgrid.Nx;
        Ny = p.Results.kgrid.Ny;
    elseif p.Results.InverseCrime == false
        Nx = 2*p.Results.kgrid.Nx;           % number of grid points in the x direction
        Ny = 2*p.Results.kgrid.Ny;           % number of grid points in the y direction
    end
    dx = p.Results.dim(1)/Nx;          % grid point spacing in the x direction [m]
    dy = p.Results.dim(2)/Ny;          % grid point spacing in the y direction [m]
    kgrid_recon = kWaveGrid(Nx, dx, Ny, dy);
    

    % use the same time array for the reconstruction
    kgrid_recon.setTime(p.Results.kgrid.Nt, p.Results.kgrid.dt);

    % reset the initial pressure
    source.p0 = 0;


    % define the medium properties
    %medium.sound_speed = 1500*ones(Nx, Ny);             % [m/s]
    %medium.sound_speed(source.p0>0.02) = 1600;          % [m/s]
    %medium.density = 1040*ones(Nx,Ny);                  % [kg/m^3]
    medium.sound_speed = p.Results.SoundSpeed;
    
    if p.Results.Absorption == true
        medium.alpha_power = 1.5;      
        medium.alpha_coeff = 3;                     % [dB/(MHz^y cm)]
        % define the cutoff frequency for the filter
        f_cutoff = 4e6;                     % [Hz]

        % create the filter to regularise the absorption parameters
        medium.alpha_filter = getAlphaFilter(kgrid_recon, medium, f_cutoff);

        % reverse the sign of the absorption proportionality coefficient
        medium.alpha_sign = [-1, 1];        % [absorption, dispersion];
    end
    
    % run the time reversal reconstruction
    p0_recon = kspaceFirstOrder2D(kgrid_recon, medium, source, sensor, input_args{:}); 

    % from gpu-memory to local memory
    p0_recon = gather(p0_recon);
end

