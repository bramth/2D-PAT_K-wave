function [] = save_figure(fig,name,curdate)
    folder_name = strcat('img/',curdate);
    
    saveas(fig,strcat(char(folder_name),'/',char(name)))
    saveas(fig,strcat(char(folder_name),'/',char(name),'.png'))
    return
end