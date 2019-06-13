function [] = save_fbp(img,padding,name)
    folder_name = strcat('img/',date);
    mkdir(folder_name)
    
    img = img(padding(1)+1:end-padding(1),...
              padding(2)+1:end-padding(2));
    
    writedir = strcat(char(folder_name),'/fbp_',char(name),'.png');
    imwrite(img,writedir)
end

