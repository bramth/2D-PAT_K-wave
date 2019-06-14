% 2D FBP algorithm on input vascular data.
% TODO:
% x Add saving of FBP images to folder.
% - Add properties of sensor
% - Make function wise as to push settings (radius, num_sensor, etc)
% - Loop over all images
% - Fix FBP blurriness: ?
% - Fix FBP optical flow discrepancy due to different grid
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

padsize = [N_pre(1), N_pre(2)]; % padding on both sides
imgset = padarray(imgset, padsize,'both');

% define a Cartesian sensor mask of a centered circle with 50 sensor elements
sensor_radius = 45e-3;      % [m]
sensor_angle = pi;          % [rad]
sensor_pos = [0, 0];        % [m]
num_sensor_points = 64;     % 256;
sensor.mask = makeCartCircle(sensor_radius, num_sensor_points, sensor_pos, sensor_angle);
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
    waitbar(n/N,f,sprintf('%d of %d',n,N));
    
    % n = 12; % DANGER : CHANGE
    
    p0_orig = imgset(:,:,n);
    
    [sensor_data,kgrid] = forward(p0_orig,...
                                  sensor,...
                                  [x,y],...
                                  input_args,...
                                  'Threshold',true);
                             
    [p0_recon,kgrid_recon] = backward(sensor_data,...
                                      sensor,...
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
    p0_recon = unpad(p0_recon,true); 
    p0_recon = resize(p0_recon,size(p0_orig));
    
    save_fbp(p0_orig,p0_recon,cur_name,curdate,imtype); 
    
    % break
end
delete(f)
