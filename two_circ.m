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

% define an initial pressure using makeDisc
disc_x_pos = 128 - PML_size; % [grid points]
disc_y_pos = 100 - PML_size; % [grid points]
disc_radius = 8; % [grid points]
disc_mag = 3; % [Pa]
source_disk = makeDisc(Nx, Ny, disc_x_pos, disc_y_pos, disc_radius);

disc_x_pos = 128 - PML_size; % [grid points]
disc_y_pos = 156 - PML_size; % [grid points]
disc_radius = 5; % [grid points]
disc_mag = 2; % [Pa]
source_disk = source_disk + makeDisc(Nx, Ny, disc_x_pos, disc_y_pos, disc_radius);

source.p0 = disc_mag*source_disk;


% create wall
width = 100;
thickness = 10;
wall_y_pos = [128 - PML_size - width/2, 128 - PML_size + width/2];
wall_x_pos = [150 - PML_size - thickness/2, 150 - PML_size + thickness/2]; % [grid points]
%wall_radius = 30; % [grid points]
%bone_wall = makeDisc(Nx, Ny, wall_x_pos, wall_y_pos, wall_radius);
bone_wall = zeros(Nx, Ny); 
bone_wall(wall_x_pos(1):wall_x_pos(2),wall_y_pos(1):wall_y_pos(2)) = 1;

% define the medium properties
c_water = 1505; % m/s
c_bone = 3476; % 2118 % m/s
c_breast = 1510; % m/s
c_blood = 1584; % m/s

rho_water = 1000; % kg/m3
rho_bone = 1975; % 1600 % kg/m3
rho_breast = 1020; % kg/m3
rho_blood = 1060; % kg/m3

medium.sound_speed = c_blood*ones(Nx, Ny); % [m/s]
medium.sound_speed(source_disk==1) = c_breast; % [m/s]
medium.sound_speed(bone_wall==1) = c_bone;
medium.density = rho_breast*ones(Nx,Ny);  % [kg/m^3]
medium.density(bone_wall==1) = rho_bone;
%medium.alpha_coeff = 1;

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