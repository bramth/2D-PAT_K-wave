% 2D FBP algorithm on input vascular data.
% TODO:
% x Add saving of FBP images to folder.
% x Add properties of sensor
% x Make function wise as to push settings (radius, num_sensor, etc)
% x Loop over all images
% x Fix FBP blurriness: ?
% x Fix FBP optical flow discrepancy due to different grid
% x COLORBAR grenzen aanpassen
% x interpolatie aanzetten, 64 uniform. 
% x proberen middelpunt aan onderzijde. 
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

% -------------------------------------------- %
                %%%%%%%%%%%%%%%%%
                %     INPUT     %
                %%%%%%%%%%%%%%%%%
% name ?
name = input('Runtime name: ','s');

% make saving folder
curdate = make_folder();

% plot ?
plotting = false;

% interpolate sensor mask ? FALSE not working at the moment.
interpolate = true;

% type ? 
%imtype = "train";
imtype = "test";

% sensorgeometry ? 
%geometry = "center"; 
geometry = "hemisphere"; 

% set the input options
input_args = {'Smooth', false, ...
              'PMLInside', false, ...
              'PlotPML', false, ...
              'PlotSim', plotting, ...
              'DataCast','gpuArray-single'};
              %'RecordMovie',true, ...
              %'DataCast','single'};
              
          
% SNR ratio
signal_to_noise_ratio = 40;	% [dB]

% max physical grid length?
l = 120e-3;

% -------------------------------------------- %
                %%%%%%%%%%%%%%%%
                %     INIT     %
                %%%%%%%%%%%%%%%%

% load the initial pressure distribution from an imageset
inputdata = load('data/vessel_2D_(DRIVE)/Vascular_set_c0_inhomogeneous_new_fixed_mu.mat');

% picking data set
switch imtype
    case "train"
        imgset = inputdata.Train_H;
    case "test"
        imgset = inputdata.Test_H; 
end

% -------------------------------------------- %
            %%%%%%%%%%%%%%%%%%%%%%%
            %     PREALLOCATE     %
            %%%%%%%%%%%%%%%%%%%%%%%

% Might be unnessary, but only fast way to acquire length of time array.
% Probably a lot faster than expanding the array a couple of hundred times.
% Also to create the binary sensor mask
N_pre = size(imgset);



% define a Cartesian sensor mask of a centered circle with x sensor elements
switch geometry
    case "center"
        % grid size
        x = l;      % total grid size [m]
        y = l;      % total grid size [m]

        
        % padding on both sides
        padsize = [N_pre(1),N_pre(1),N_pre(2),N_pre(2)];
        imgset = padarray(imgset, [N_pre(1), N_pre(2)],'both');
        
        imgsize = size(imgset);
        
        kgrid = kWaveGrid(imgsize(1), x/imgsize(1), imgsize(2), y/imgsize(2));
        kgrid.makeTime(1500);
        
        sensor_radius = 55e-3;      % [m]
        sensor_angle = 2*pi;        % [rad]
        sensor_pos = [0, 0];        % [m]
        sensor_points = 64;         % number of sensors, uniformly aligned;
        
        % create a binary sensor mask of an equivalent continuous circle 
        sensor_radius_grid_points = round(sensor_radius / kgrid.dx);
        binary_sensor_mask = makeCircle(kgrid.Nx, kgrid.Ny, kgrid.Nx/2 + 1, kgrid.Ny/2 + 1, sensor_radius_grid_points, sensor_angle);

    case "hemisphere"
        % grid size
        x = 2*l/3;      % total grid size [m]
        y = l;      % total grid size [m]

        
        % padding on one sides vertically
        padsize = [N_pre(1),0,N_pre(2),N_pre(2)];
        imgset = padarray(imgset,[0,N_pre(2)],0,'both');
        imgset = padarray(imgset,[N_pre(1),0],0,'pre');
        
        imgsize = size(imgset);
        
        kgrid = kWaveGrid(imgsize(1), x/imgsize(1), imgsize(2), y/imgsize(2));
        kgrid.makeTime(1500);
        
        sensor_radius = 55e-3;          % [m]
        sensor_angle = pi;              % [rad]
        sensor_pos = [x/2-x/100, 0];    % [m] % small offset to not be outside outer edge.
        sensor_points = 64;           % number of sensors, limited view
        
        % create a binary sensor mask of an equivalent continuous circle 
        %sensor_radius_grid_points = round(sensor_radius / kgrid.dx);
        %binary_sensor_mask = makeCircle(kgrid.Nx, kgrid.Ny, kgrid.Nx, kgrid.Ny/2 + 1, sensor_radius_grid_points, sensor_angle);
        
        temp_cart = makeCartCircle(sensor_radius, 1000, sensor_pos, sensor_angle);
        binary_sensor_mask = cart2grid(kgrid,temp_cart);
        clear temp_cart
end
        
cart_sensor_mask = makeCartCircle(sensor_radius, sensor_points, sensor_pos, sensor_angle);

% sensor directivity
%sensor.directivity_angle =
%sensor.directivity_size =

sensordata = zeros(N_pre(3),sensor_points,size(kgrid.t_array,2));

p0_original = zeros(N_pre(3),N_pre(1),N_pre(2));
p0_reconstruct = zeros(N_pre(3),N_pre(1),N_pre(2));
p0_reconstruct_clip = zeros(N_pre(3),N_pre(1),N_pre(2));

% -------------------------------------------- %

                %%%%%%%%%%%%%%%%
                %     LOOP     %
                %%%%%%%%%%%%%%%%
f = waitbar(0,'Starting FBP...');

N = size(imgset,3);
for n = 1:N
    clc;
    waitbar(n/N,f,sprintf('FBP simulation: %d of %d',n,N));
    
    p0_orig = squeeze(imgset(:,:,n));
    
    % set mask to point mask
    sensor.mask = cart_sensor_mask;

    [sensor_data,kgrid] = forward(p0_orig,...
                                  sensor,...
                                  [x,y],...
                                  input_args,...
                                  'Threshold',false);
                              
    
    % add noise to the recorded sensor data
    sensor_data = addNoise(sensor_data, signal_to_noise_ratio, 'peak');
    
    % INSTEAD, filter sensor_data after full capture in sensor domain. 
    % filter the sensor data using a Gaussian filter
    % Fs = 1/kgrid.dt;        % [Hz]
    % center_freq = 6.25e6;      % [Hz]
    % bandwidth = 80;        % [%]
    % sensor_data = gaussianFilter(sensor_data, Fs, center_freq, bandwidth);

    
    if interpolate == true
        % switch to binary mask
        sensor.mask = binary_sensor_mask;

        % interpolate data to remove the gaps and assign to sensor structure
        sensor.time_reversal_boundary_data = interpCartData(kgrid, sensor_data, cart_sensor_mask, binary_sensor_mask);
    else
        % assign the time reversal data IF NOT INTERP
        sensor.time_reversal_boundary_data = sensor_data; 
    end
    
       
    [p0_recon,kgrid_recon] = backward(sensor,...
                                      kgrid,...
                                      [x,y],...
                                      input_args);
             
    % visualize
    cur_name = strcat(name,'_',num2str(n));
    
    if plotting == true
        fig = show_result(p0_orig,kgrid,p0_recon,kgrid_recon,cart_sensor_mask,binary_sensor_mask);
        save_figure(fig,cur_name,curdate);
        fig = show_slice(p0_orig,kgrid,p0_recon,kgrid_recon,'x','half');
        save_figure(fig,strcat(cur_name,'_slice'),curdate);
    end
    
    p0_orig = unpad(p0_orig,padsize);
    p0_recon = unpad(p0_recon,padsize); 
    
    % only if not inverse-crime
    %p0_recon = resize(p0_recon,size(p0_orig));
    
    p0_recon_clip = p0_recon .* (p0_recon>=0);
    
    % save fbp as png (but it scales according to png rules)
    % save_fbp(p0_orig,p0_recon_clip,cur_name,curdate,imtype);   
    
    % store results in mat file
    sensordata(n,:,:) = sensor_data;
    p0_original(n,:,:) = p0_orig;
    p0_reconstruct(n,:,:) = p0_recon;
    p0_reconstruct_clip(n,:,:) = p0_recon_clip;
    
end

% save fbp as mat file
save_data(sensordata,p0_original,p0_reconstruct,p0_reconstruct_clip,name,curdate,imtype);

delete(f)
