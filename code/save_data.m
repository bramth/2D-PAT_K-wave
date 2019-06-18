function [] = save_data(sensordata,p0_original,p0_reconstruct,p0_reconstruct_clip,name,curdate,imtype)
    % save fbp
    if imtype == 'train'
        folder_name = strcat('img/',curdate,'/train');
    elseif imtype == 'test'
        folder_name = strcat('img/',curdate,'/test');
    end

    writedir = strcat(char(folder_name),'/',char(name),'.mat');
    
    save(writedir,'sensordata','p0_original','p0_reconstruct','p0_reconstruct_clip');
end

