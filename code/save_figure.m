function [] = save_figure(fig,name)
    folder_name = strcat('img/',date);
    mkdir(folder_name)
    
    saveas(fig,strcat(char(folder_name),'/',char(name)))
    saveas(fig,strcat(char(folder_name),'/',char(name),'.png'))
    return
end