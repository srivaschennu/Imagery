function Data = lar(Data,chanlocs,badchannels)
%Data assumed in format: epochs X frames X channels

numneighbours = 4;
OrigData = Data;

goodchannels = setdiff(1:size(Data,3),badchannels);

[THETA PHI] = cart2sph(chanlocs(:,1),chanlocs(:,2),chanlocs(:,3));
chanlocs = radtodeg([PHI THETA]);

for chan = goodchannels
%     dist = pdist2(chanlocs(chan,:), chanlocs);
    dist = distance(chanlocs(chan,:),chanlocs);
    [~, sortidx] = sort(dist);
    sortidx = subset(sortidx, chan);
    sortidx = subset(sortidx, badchannels);
    neighbours = sortidx(1:numneighbours);
    
    for n = 1:length(neighbours)
      Data(:,:,chan) = Data(:,:,chan) - (((1./dist(neighbours(n)))/sum(1./dist(neighbours))) .* OrigData(:,:,n));
    end
end
