function EEG = concatfeats_bsl(EEG)

data = EEG.data;

numfeats = size(data,1);
numsamples = size(data,2);

win = 0.5;
win = round(win * EEG.srate);

% outdata = zeros(size(data,1),numsamples,numfeats*win);
outdata = zeros(numfeats*win,1,size(data,3));
fprintf('Collapsing features..\n');
for chan = 1:size(data,1)
%     fprintf('Collapsing feature %s of %s...\n',num2str(chan),num2str(size(data,3)));
    for trial = 1:size(data,3)

        for t = round(EEG.srate/2); %1:numsamples-win
            swstart = t;
            swstop = t+win-1;
            d = squeeze(data(:,swstart:swstop,trial));
            d = reshape(d,1,size(d,1)*size(d,2));
%             outdata(trial,t,:) = d;
            outdata(:,1,trial) = d;

        end

    end
end

% outdata = outdata(:,1:numsamples-win,:);
EEG.data = outdata;
