function [] = save_fbp(img,imgfbp,name,curdate,imtype)
    % save fbp
    if imtype == 'train'
        folder_name = strcat('img/',curdate,'/train');
    elseif imtype == 'test'
        folder_name = strcat('img/',curdate,'/test');
    end

    writedir = strcat(char(folder_name),'/',char(name),'.png');
    imwrite(img,writedir)
    writedir = strcat(char(folder_name),'/',char(name),'_fbp.png');
    imwrite(imgfbp,writedir)
end

