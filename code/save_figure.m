function [] = save_figure(fig,name)
    folder_name = ['img/' date];
    mkdir(folder_name)
    
    saveas(fig,strcat(folder_name,'/',name))
    saveas(fig,strcat(folder_name,'/',name,'.png'))
    return
end