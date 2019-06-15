function [sensor_data,kgrid] = forward(p0,sensor,dim,input_args,varargin)
    % Forward function
    
    p = inputParser;
    
    defaultThreshold = false;
    defaultSmooth = true; 
    defaultSpeed = 1500;
    defaultAbsorption = false;
    
    
    addRequired(p,'p0')
    addRequired(p,'sensor')
    addRequired(p,'dim')
    addRequired(p,'input_args',@iscell)
    addOptional(p,'Threshold',defaultThreshold,@islogical);
    addOptional(p,'Smooth',defaultSmooth,@islogical);
    addOptional(p,'SoundSpeed',defaultSpeed,@isnumeric);
    addOptional(p,'Absorption',defaultAbsorption,@islogical);
    
    parse(p,p0,sensor,dim,input_args,varargin{:})
    
    % add to source
    source.p0 = p.Results.p0;
    
    % remove old sensor data
    if isfield(sensor,'time_reversal_boundary_data')
        sensor = rmfield(sensor,'time_reversal_boundary_data'); 
    end
    
    % create the computational grid
    N = size(source.p0);
    Nx = N(1);       % number of grid points in the x (row) direction
    Ny = N(2);       % number of grid points in the y (column) direction
    dx = p.Results.dim(1) / Nx;     % grid point spacing in the x direction [m]
    dy = p.Results.dim(2) / Ny;     % grid point spacing in the y direction [m]
    kgrid = kWaveGrid(Nx, dx, Ny, dy);
    
    % filter low background signal
    if p.Results.Threshold
        source.p0 = source.p0 .* (source.p0>0.02);
    end
    
    % smooth the initial pressure distribution and restore the magnitude
    if p.Results.Smooth
        source.p0 = smooth(kgrid, source.p0, true);
    end

    % define the medium properties
    %medium.sound_speed = 1500*ones(Nx, Ny);             % [m/s]
    %medium.sound_speed(source.p0>0.02) = 1600;          % [m/s]
    %medium.density = 1040*ones(Nx,Ny);                  % [kg/m^3]
    medium.sound_speed = p.Results.SoundSpeed;
    
    if p.Results.Absorption == true
        medium.alpha_power = 1.5;      
        medium.alpha_coeff = 3;                     % [dB/(MHz^y cm)]
    end

    % create the time array
    kgrid.makeTime(medium.sound_speed);

    % run the simulation
    sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor,input_args{:});
    
    sensor_data = gather(sensor_data);
end

