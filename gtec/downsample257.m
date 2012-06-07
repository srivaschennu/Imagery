distances = 1; % filler so can iterate distances later
clear nearest

for currentElec = 1:129   ;
    
    [ThP1, PHP1] = (cart2sph(data_129(currentElec,1),data_129(currentElec,2),data_129(currentElec,3)));
    
    for countElec = 1:257 ;
        
        %         distances = [distances;sqrt((data_129(currentElec,1) - data_257(countElec,1)).^2 + (data_129(currentElec,2) - data_257(countElec,2)).^2 + (data_129(currentElec,3) - data_257(countElec,3)).^2)];
        
        
        [ThP2, PHP2] = (cart2sph(data_257(countElec,1),data_257(countElec,2),data_257(countElec,3)));
        
        P1 = radtodeg([ThP1,PHP1]);
        P2 = radtodeg([ThP2,PHP2]);
        
        distances(countElec) = distance('gc',P1(2),P1(1),P2(2),P2(1));
        
    end
    
%     distances = distances(2:length(distances));
    [sorted, indx] = sort(distances);
    
    if currentElec == 1
        
        nearest(currentElec,1) = indx(1);
        nearest(currentElec,2) = sorted(1);
        
    else
        
        current = find(nearest(:,1) == indx(1));
       
    
        if isempty(current)

            nearest(currentElec,1) = indx(1);
            nearest(currentElec,2) = sorted(1);

        else
            
            current = find(nearest(:,1) == indx(2));
            
            if isempty(current)
            
                nearest(currentElec,1) = indx(2);
                nearest(currentElec,2) = sorted(2);
                
            else
                
                nearest(currentElec,1) = indx(3);
                nearest(currentElec,2) = sorted(3);
            end

        end
    end
    
        
    distances = 1;
    
end

datavector = zeros(1,257);
figure; topoplot(datavector,'GSN-HydroCel-257.sfp','plotchans',nearest(:,1),'electrodes','on');

