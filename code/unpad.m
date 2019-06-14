function [img] = unpad(img,padding)
    % unpad the image
    if padding == true
        imgsize = size(img);
        padding = [round(imgsize(1)/3), round(imgsize(2)/3)];
    end
    img = img(padding(1)+1:end-padding(1),...
              padding(2)+1:end-padding(2));
    
end

