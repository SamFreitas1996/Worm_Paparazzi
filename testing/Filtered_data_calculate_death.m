% filtered death test

load('setup.mat');

bw_diff = (raw_sess_data_aft_bw-raw_sess_data_bef_bw);

x = 1:125;

for i = 1:240
    
    bw = abs(bw_diff(:,i));
    
    bw_filt = medfilt1(bw,10);
    
    for j = 2:length(bw)-2
        
        if bw(j-1)>0 && bw(j+1)>0 && bw(j)==0
            
            bw(j) = mean([bw(j-1),bw(j+1)]);
        end
        if bw(j-1)<0 && bw(j+1)<0 && bw(j)==0
            
            bw(j) = mean([bw(j-1),bw(j+1)]);
        end
        
        if bw(j)==0 && bw(j+1)==0 && bw(j+2)>0
            bw(j:j+1)=1;
        end
        
    end
    if (bw(1)==0 && bw(2)>0) || (bw(1)==0 && bw(2)==0 && bw(3)>0)
        bw(1:3)=(bw(1:3)+1);
    end
    
    try
        d_bw(i) = find(bw==0,1,'first');
    catch
        d_bw(i) = length(x);
    end
    
    try
        d_filt_bw(i) = find(bw_filt==0,1,'first');
    catch
        d_filt_bw(i) = length(x);
    end
    
        plot(x,bw,'b',x,bw_filt,'r',d_bw(i),5,'b*',d_filt_bw(i),0,'r*')
        title(i)
    
    
end