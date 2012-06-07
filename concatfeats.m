function EEG = concatfeats(EEG,timewin)

numfeats = size(EEG.data,1);
numsamples = size(EEG.data,2);

times = EEG.times / 1000;

samplewin = find(abs(timewin(1)-times) == min(abs(timewin(1)-times))) : ...
    find(abs(timewin(end)-times) == min(abs(timewin(end)-times)));

% outdata = zeros(size(data,1),numsamples,numfeats*win);
outdata = zeros(numfeats*length(samplewin),1,size(EEG.data,3));

fprintf('Collapsing features between %.1f-%.1f sec..\n',times(samplewin(1)),times(samplewin(end)));
for chan = 1:size(EEG.data,1)
    %     fprintf('Collapsing feature %s of %s...\n',num2str(chan),num2str(size(data,3)));
    for trial = 1:size(EEG.data,3)
        outdata(:,1,trial) = reshape(EEG.data(:,samplewin,trial),...
            1,size(EEG.data,1)*length(samplewin));
    end
end

% outdata = outdata(:,1:numsamples-win,:);
EEG.data = outdata;
