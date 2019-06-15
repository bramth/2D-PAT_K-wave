% 2D FBP algorithm on input vascular data.
% TODO:
% x Add saving of FBP images to folder.
% x Add properties of sensor
% x Make function wise as to push settings (radius, num_sensor, etc)
% x Loop over all images
% x Fix FBP blurriness: ?
% - Fix FBP optical flow discrepancy due to different grid
% x COLORBAR grenzen aanpassen
% x interpolatie aanzetten, 64 uniform. 
% - proberen middelpunt aan onderzijde. 
% x of plaatje *2, of plaatje/2
% x inverse crime negeren !! (interpoleren)
% -------------------------------------------- %
                %%%%%%%%%%%%%%%%
                %     VARS     %
                %%%%%%%%%%%%%%%%

% delete old variables
clearvars;
close all;
clc;

% add subfolder to path
addpath './code'

% name ?
name = input('Runtime name: ','s');

% make saving folder
curdate = make_folder();

% plot ?
plotting = false;

% type
imtype = "train";

% set the input options
input_args = {'Smooth', false, ...
              'PMLInside', false, ...
              'PlotPML', false, ...
              'PlotSim', false, ...
              'DataCast','gpuArray-single'};
          
% grid size
x = 100e-3;      % total grid size [m]
y = 100e-3;      % total grid size [m]

% SNR ratio
signal_to_noise_ratio = 40;	% [dB]

% -------------------------------------------- %
                %%%%%%%%%%%%%%%%
                %     INIT     %
                %%%%%%%%%%%%%%%%

% load the initial pressure distribution from an imageset
data = load('data/vessel_2D_(DRIVE)/Vascular_set_c0_inhomogeneous_new_fixed_mu.mat');

if imtype == "train"
    imgset = data.Train_H;
elseif imtype == "test"
    imgset = data.Test_H; 
end

N_pre = size(imgset);

padsize = [N_pre(1), N_pre(2)];             % padding on both sides
imgset = padarray(imgset, padsize,'both');

% define a Cartesian sensor mask of a centered circle with 50 sensor elements
sensor_radius = 45e-3;      % [m]
sensor_angle = 2*pi;        % [rad]
sensor_pos = [0, 0];        % [m]
sensor_points = 64;     % number of sensors, uniformly aligned;
cart_sensor_mask = makeCartCircle(sensor_radius, sensor_points, sensor_pos, sensor_angle);

%sensor.frequency_response = [6.25e6, 80];   % [center freq [Hz], %]
%sensor.directivity_angle
%sensor.directivity_size

% -------------------------------------------- %

                %%%%%%%%%%%%%%%%
                %     LOOP     %
                %%%%%%%%%%%%%%%%
f = waitbar(0,'Starting FBP...');
N = length(imgset);
for n = 1:N
    clc;
    waitbar(n/N,f,sprintf('FBP simulation: %d of %d',n,N));
    
    p0_orig = imgset(:,:,n);
    
    sensor.mask = cart_sensor_mask;

    [sensor_data,kgrid] = forward(p0_orig,...
                                  sensor,...
                                  [x,y],...
                                  input_args,...
                                  'Threshold',false);
                              
    
    % add noise to the recorded sensor data
    sensor_data = addNoise(sensor_data, signal_to_noise_ratio, 'peak');
                          
    % assign the time reversal data IF NOT INTERP
    % sensor.time_reversal_boundary_data = sensor_data; 
    
    % create a binary sensor mask of an equivalent continuous circle 
    sensor_radius_grid_points = round(sensor_radius / kgrid.dx);
    binary_sensor_mask = makeCircle(kgrid.Nx, kgrid.Ny, kgrid.Nx/2 + 1, kgrid.Ny/2 + 1, sensor_radius_grid_points, sensor_angle);
    
    sensor.mask = binary_sensor_mask;
    
    % interpolate data to remove the gaps and assign to sensor structure
    sensor.time_reversal_boundary_data = interpCartData(kgrid, sensor_data, cart_sensor_mask, binary_sensor_mask);

       
    [p0_recon,kgrid_recon] = backward(sensor,...
                                      kgrid,...
                                      [x,y],...
                                      input_args);
             
    % visualize
    cur_name = strcat(name,'_',num2str(n));
    
    if plotting == true
        fig = show_result(p0_orig,kgrid,p0_recon,kgrid_recon,sensor.mask);
        save_figure(fig,cur_name,curdate);
        fig = show_slice(p0_orig,kgrid,p0_recon,kgrid_recon,'x','half');
        save_figure(fig,strcat(cur_name,'_slice'),curdate);
    end
    
    p0_orig = unpad(p0_orig,padsize);
    p0_recon = unpad(p0_recon,padsize); 

    %p0_recon = resize(p0_recon,size(p0_orig));
    
    p0_recon_clip = p0_recon .* (p0_recon>=0);
    
    save_fbp(p0_orig,p0_recon_clip,cur_name,curdate,imtype);   
    
end
delete(f)
