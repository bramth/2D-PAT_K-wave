% 2D FBP algorithm on input vascular data.
% TODO:
% x Add saving of FBP images to folder.
% - Add properties of sensor
% - Make function wise as to push settings (radius, num_sensor, etc)
% - Loop over all images

clear all, close all, clc;

name = input('Runtime name: ','s');

% load the initial pressure distribution from an image and scale
data = load('data/vessel_2D_(DRIVE)/Vascular_set_c0_inhomogeneous_new_fixed_mu.mat');

N_pre = size(data.Train_H);

x = 100e-3;                     % total grid size [m]
y = 100e-3;                     % total grid size [m]
padsize = [N_pre(1), N_pre(2)];            % padding on both sides
data.Train_H = padarray(data.Train_H, padsize,'both');
data.Test_H = padarray(data.Test_H, padsize,'both');

N = size(data.Train_H);

% create the computational grid
Nx = N(1);       % number of grid points in the x (row) direction
Ny = N(2);       % number of grid points in the y (column) direction
dx = x / Nx;     % grid point spacing in the x direction [m]
dy = y / Ny;     % grid point spacing in the y direction [m]
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% set the input options
input_args = {'Smooth', false, ...
              'PMLInside', false, ...
              'PlotPML', false, ...
              'PlotSim', false, ...
              'DataCast','gpuArray-double'};

% define a Cartesian sensor mask of a centered circle with 50 sensor elements
sensor_radius = 45e-3; % [m]
sensor_angle = pi;        % [rad]
sensor_pos = [0, 0];        % [m]
num_sensor_points = 64; % 256; %
sensor.mask = makeCartCircle(sensor_radius, num_sensor_points, sensor_pos, sensor_angle);
%sensor.frequency_response = [6.25e6, 80];   % [center freq [Hz], %]
%sensor.directivity_angle
%sensor.directivity_size

% -------------------------------------------- %

% take an image
source.p0 = data.Train_H(:,:,12);

% smooth the initial pressure distribution and restore the magnitude
source.p0 = smooth(kgrid, source.p0, true);

% define the medium properties
%medium.sound_speed = 1500*ones(Nx, Ny);             % [m/s]
%medium.sound_speed(source.p0>0.02) = 1600;          % [m/s]
%medium.density = 1040*ones(Nx,Ny);                  % [kg/m^3]
medium.sound_speed = 1500;

% create the time array
kgrid.makeTime(medium.sound_speed);

% run the simulation
sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor,input_args{:});


% -------------------------------------------- %

% add noise to the recorded sensor data
signal_to_noise_ratio = 40;	% [dB]
sensor_data = addNoise(sensor_data, signal_to_noise_ratio, 'peak');

% create a new computation grid to avoid inverse crime
Nx = ceil(Nx/50)*50;           % number of grid points in the x direction
Ny = ceil(Ny/50)*50;           % number of grid points in the y direction
dx = x/Nx;          % grid point spacing in the x direction [m]
dy = y/Ny;          % grid point spacing in the y direction [m]
kgrid_recon = kWaveGrid(Nx, dx, Ny, dy);

% use the same time array for the reconstruction
kgrid_recon.setTime(kgrid.Nt, kgrid.dt);

% reset the initial pressure
p0_orig = source.p0;
source.p0 = 0;

% assign the time reversal data
sensor.time_reversal_boundary_data = sensor_data;

% run the time reversal reconstruction
p0_recon = kspaceFirstOrder2D(kgrid_recon, medium, source, sensor, input_args{:}); 

p0_recon = gather(p0_recon);

% visualize
fig = show_result(p0_recon,p0_orig,kgrid,kgrid_recon,sensor.mask,sensor_data);
save_figure(fig,name);
save_fbp(p0_recon,padsize,name)

function [fig] = show_result(p0_recon,p0_orig,kgrid,kgrid_recon,cart_sensor_mask,sensor_data)
    fig = figure;
    pause(0.00001);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
    pause(0.00001);

    subplot(1,3,1);
    imagesc(cart2grid(kgrid, cart_sensor_mask)+p0_orig, [-1, 1]);
    ylabel('x-position [mm]');
    xlabel('y-position [mm]');
    title('Original image');
    axis image;
    colormap(getColorMap);

    subplot(1,3,2);
    imagesc(cart2grid(kgrid_recon, cart_sensor_mask)+p0_recon, [-1, 1]);
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
   
    return
end

function [] = save_figure(fig,name)
    folder_name = ['img/' date];
    mkdir(folder_name)
    
    saveas(fig,[folder_name, '/', name])
    saveas(fig,[folder_name, '/', name,'.png'])
    return
end

function [] = save_fbp(img,padding,name)
    folder_name = ['img/' date];
    mkdir(folder_name)
    
    img = img(padding(1)+1:end-padding(1),...
              padding(2)+1:end-padding(2));
    
    imwrite(img,[folder_name, '/fbp_', name,'.png'])
end


