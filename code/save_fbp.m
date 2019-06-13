function [] = save_fbp(img,padding,name)
    folder_name = ['img/' date];
    mkdir(folder_name)
    
    img = img(padding(1)+1:end-padding(1),...
              padding(2)+1:end-padding(2));
    
    imwrite(img,strcat('/fbp_',name,'.png'))
end

