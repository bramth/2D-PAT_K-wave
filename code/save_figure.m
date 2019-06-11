function [] = save_figure(fig,name)
    folder_name = ['img/' date];
    mkdir(folder_name)
    
    saveas(fig,[folder_name, '/', name])
    saveas(fig,[folder_name, '/', name,'.png'])
    return
end