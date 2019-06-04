clear all, close all, clc;

% create the computational grid
PML_size = 20;              % size of the PML in grid points
Nx = 256 - 2 * PML_size;    % number of grid points in the x (row) direction
Ny = 256 - 2 * PML_size;    % number of grid points in the y (column) direction
x = 10e-3;                  % total grid size [m]
y = 10e-3;                  % total grid size [m]
dx = x / Nx;                % grid point spacing in the x direction [m]
dy = y / Ny;                % grid point spacing in the y direction [m]
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% load the initial pressure distribution from an image and scale

p0_magnitude = 2;
padsize = [50,50];
p0_norm = loadImage('data/EXAMPLE_source_one.png');
p0_norm = padarray(p0_norm, padsize,'both');

p0_norm = resize(p0_norm, [Nx, Ny]);

source.p0 = p0_norm * p0_magnitude;

% create wall
% wall_y_pos = 128;
% wall_x_pos = 200 - PML_size; % [grid points]
% wall_radius = 10; % [grid points]
% bone_wall = makeDisc(Nx, Ny, wall_x_pos, wall_y_pos, wall_radius);

% define the medium properties
medium.sound_speed = 1500*ones(Nx, Ny); % [m/s]
medium.sound_speed(p0_norm==1) = 1600; % [m/s]
%medium.sound_speed(bone_wall==1) = 2118;
medium.density = 1040*ones(Nx,Ny);  % [kg/m^3]
%medium.density(bone_wall==1) = 1600;

% define a Cartesian sensor mask of a centered circle with 50 sensor elements
sensor_radius = 4e-3; % [m]
sensor_angle = pi;        % [rad]
sensor_pos = [0, 0];        % [m]
num_sensor_points = 45;
sensor.mask = makeCartCircle(sensor_radius, num_sensor_points, sensor_pos, sensor_angle);

% run the simulation
sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor);

% reset the initial pressure
source.p0 = 0;

% add noise to the recorded sensor data
signal_to_noise_ratio = 40;	% [dB]
sensor_data = addNoise(sensor_data, signal_to_noise_ratio, 'peak');

% INVERSE CRIME PREVENTION STILL

% assign the time reversal data
sensor.time_reversal_boundary_data = sensor_data;

% run the time reversal reconstruction
p0_recon = kspaceFirstOrder2D(kgrid, medium, source, sensor); % inverse crime

% visualize
figure;
imshow(p0_recon);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
axis image;
colormap(getColorMap);