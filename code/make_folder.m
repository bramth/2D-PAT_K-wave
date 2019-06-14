function [curdate] = make_folder()
    %MAKE_FOLDER Summary of this function goes here
    
    curdate = date;
    
    folder_name = strcat('img/',curdate,'/train');
    mkdir(folder_name)
    folder_name = strcat('img/',curdate,'/test');
    mkdir(folder_name)

end

