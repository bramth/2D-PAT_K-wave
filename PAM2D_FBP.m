% 2D FBP algorithm on input vascular data.
% TODO:
% - Fix "The grid vectors do not define a grid of points that match the
% given values." in reconstruction. 
% - Add saving of FBP images to folder.
% - Add properties of sensor
% - Make function wise as to push settings (radius, num_sensor, etc)
% - Loop over all images

clear all, close all, clc;

% load the initial pressure distribution from an image and scale
data = load('data/vessel_2D_(DRIVE)/Vascular_set_c0_inhomogeneous_new_fixed_mu.mat');

padsize = [50,50]; % [200,200]; %
data.Train_H = padarray(data.Train_H, padsize,'both');
data.Test_H = padarray(data.Test_H, padsize,'both');

% create the computational grid
N = size(data.Train_H);

Nx = N(1);       % number of grid points in the x (row) direction
Ny = N(2);       % number of grid points in the y (column) direction
x = 10e-3;                      % total grid size [m]
y = 10e-3;                      % total grid size [m]
dx = x / Nx;                    % grid point spacing in the x direction [m]
dy = y / Ny;                    % grid point spacing in the y direction [m]
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% set the input options
input_args = {'Smooth', false, 'PMLInside', false, 'PlotPML', false};

% define a Cartesian sensor mask of a centered circle with 50 sensor elements
sensor_radius = 4.5e-3; % [m]
sensor_angle = pi;        % [rad]
sensor_pos = [0, 0];        % [m]
num_sensor_points = 64; % 256; %
sensor.mask = makeCartCircle(sensor_radius, num_sensor_points, sensor_pos, sensor_angle);
%sensor.frequency_response = [6.25e6,80];
%sensor.directivity_angle
%sensor.directivity_size

% -------------------------------------------- %

% take an image
source.p0 = data.Train_H(:,:,12);

% smooth the initial pressure distribution and restore the magnitude
source.p0 = smooth(kgrid, source.p0, true);

% define the medium properties
medium.sound_speed = 1500*ones(Nx, Ny);             % [m/s]
%medium.sound_speed(source.p0>0.02) = 1600;          % [m/s]
medium.density = 1040*ones(Nx,Ny);                  % [kg/m^3]

% create the time array
kgrid.makeTime(medium.sound_speed);

% run the simulation
sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor,input_args{:});


% -------------------------------------------- %

% reset the initial pressure
p0_orig = source.p0;
source.p0 = 0;

% add noise to the recorded sensor data
signal_to_noise_ratio = 40;	% [dB]
sensor_data = addNoise(sensor_data, signal_to_noise_ratio, 'peak');

% create a new computation grid to avoid inverse crime
Nx = ceil(Nx/50)*50;           % number of grid points in the x direction
Ny = ceil(Nx/50)*50;           % number of grid points in the y direction
dx = x/Nx;          % grid point spacing in the x direction [m]
dy = y/Ny;          % grid point spacing in the y direction [m]
kgrid_recon = kWaveGrid(Nx, dx, Ny, dy);

% use the same time array for the reconstruction
kgrid_recon.setTime(kgrid.Nt, kgrid.dt);

% assign the time reversal data
sensor.time_reversal_boundary_data = sensor_data;

% run the time reversal reconstruction
p0_recon = kspaceFirstOrder2D(kgrid_recon, medium, source, sensor,input_args{:}); 

% visualize
show_result(p0_recon,p0_orig,kgrid,sensor.mask,sensor_data)

function [] = show_result(p0_recon,p0_orig,kgrid,cart_sensor_mask,sensor_data)
figure;

subplot(1,3,1);
imagesc(cart2grid(kgrid, cart_sensor_mask)+p0_orig, [-1, 1]);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
title('Original image');
axis image;
colormap(getColorMap);

subplot(1,3,2);
imagesc(p0_recon, [-1, 1]);
ylabel('x-position [mm]');
xlabel('y-position [mm]');
title('Reconstructed image');
axis image;
colormap(getColorMap);

% plot the simulated sensor data
subplot(1,3,3);
imagesc(sensor_data, [-1, 1]);
colormap(getColorMap);
ylabel('Sensor Position');
xlabel('Time Step');
colorbar;
end


