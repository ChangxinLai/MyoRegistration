% This script is used for registering tif to dicom

datadir = 'E:\JHU\Data\data_test';%Dataset directory

showresults = true;
saveresults = false;
errornum = [];%Number of patients that potentially have errors when registering

for i = 1:10 %Patient number
    dicomdir = dir([datadir,'\P',num2str(i,'%03d'),'*\DICOM\*.dcm']);
    
    scale_all = [];%Scaling factor of each slice
    tx_all = [];%Translation distance of each slice
    ty_all = [];
    
    dirTransmatrix = [dicomdir(i).folder(1:end-6),'\Transmatrix'];
    if ~exist(dirTransmatrix,'dir')
        mkdir(dirTransmatrix);
    end
    dirScale = [dicomdir(i).folder(1:end-6),'\Scale'];
    if ~exist(dirScale,'dir')
        mkdir(dirScale);
    end
    
    for n = 1:length(dicomdir)
        slice_num = num2str(str2num(dicomdir(n).name(1:end-4)));
        
        tifdir = dir([datadir,'\P',num2str(i,'%03d'),'*\tif\image',slice_num,'.tif']);
        if isempty(tifdir)
            tifdir = dir([datadir,'\P',num2str(i,'%03d'),'*\tif\*image',slice_num,'.tif']);
        end
        
        %load images
        movingimg = im2double(imread([tifdir(end).folder,'\',tifdir(end).name]));
        movingimg = movingimg(:,:,3);
        fixedimg = im2double(dicomread([dicomdir(n).folder,'\',dicomdir(n).name]));
        %image processing
        movingimg = (movingimg - min(movingimg(:)))/(max(movingimg(:))-min(movingimg(:)));
        movingimg = imdiffusefilt(histeq(movingimg));

        fixedimg = (fixedimg - min(fixedimg(:)))/(max(fixedimg(:))-min(fixedimg(:)));
        fixedimg = imdiffusefilt(histeq(fixedimg));
        %registration
        RegResult=RegAlgorithm(movingimg,fixedimg);
        
        if showresults
            figure
            subplot(2,2,1),imshow(fixedimg),axis off,title('DICOM');
            subplot(2,2,2),imshow(movingimg),axis off,title('TIF');
            subplot(2,2,3),imshowpair(fixedimg,RegResult.RegisteredImage),axis off;
            title('Overlaped Image after Registration');
            subplot(2,2,4),imshow(fixedimg-RegResult.RegisteredImage),axis off;
            title('Difference Image after Registration');
            pause(0.1);
        end
        
        Transmatrix  = (RegResult.Transformation.T)';

        ss = Transmatrix(2,1);
        sc = Transmatrix(1,1);
        scale = double(sqrt(ss*ss + sc*sc));
        theta = double(atan2(ss,sc)*180/pi);
        tx = Transmatrix(1,3)-Transmatrix(1,1);
        ty = Transmatrix(2,3)-Transmatrix(1,1);
        
        scale_all = cat(1,scale_all,scale);
        tx_all = cat(1,tx_all,tx);
        ty_all = cat(1,ty_all,ty); 
        
        if saveresults
            dlmwrite([dirTransmatrix,'\T-',slice_num,'.txt'],Transmatrix,'delimiter','\t');
            save([dirScale,'\S-',slice_num,'.txt'],'scale','-ascii','-double');
        end
    
    end
    %error detectiom: if standard deviation of translation distance is
    %above 1.5, this patient should be double checked
    if (std(ty_all)>1.5)||(std(tx_all)>1.5)
        errornum = cat(1,errornum,i);
        
        figure,
        subplot(3,1,1),plot(1:length(dicomdir),scale_all,'o',...
            1:length(dicomdir),ones(length(dicomdir),1)*mean(scale_all),...
            1:length(dicomdir),ones(length(dicomdir),1)*(mean(scale_all)+std(scale_all)),'g--',...
            1:length(dicomdir),ones(length(dicomdir),1)*(mean(scale_all)-std(scale_all)),'g--');
        ylabel('Scale');
        title(['Patient ',num2str(i)]);
        subplot(3,1,2),plot(1:length(dicomdir),tx_all,'o',...
            1:length(dicomdir),ones(length(dicomdir),1)*mean(tx_all),...
            1:length(dicomdir),ones(length(dicomdir),1)*(mean(tx_all)+std(tx_all)),'g--',...
            1:length(dicomdir),ones(length(dicomdir),1)*(mean(tx_all)-std(tx_all)),'g--');    
        ylabel('tx');
        subplot(3,1,3),plot(1:length(dicomdir),ty_all,'o',...
            1:length(dicomdir),ones(length(dicomdir),1)*mean(ty_all),...
            1:length(dicomdir),ones(length(dicomdir),1)*(mean(ty_all)+std(ty_all)),'g--',...
            1:length(dicomdir),ones(length(dicomdir),1)*(mean(ty_all)-std(ty_all)),'g--');    
        xlabel('slice'),ylabel('ty');
    end
    
end



