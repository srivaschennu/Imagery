function P_C_S = fuckupdata(P_C_S)

data = P_C_S.Data;
data = permute(data,[3 2 1]);

numfeats = size(data,1);
numsamples = size(data,2);

win = 3;
win = round(win * P_C_S.SamplingFrequency);

% outdata = zeros(size(data,1),numsamples,numfeats*win);
outdata = zeros(numfeats*win,1,size(data,3));
fprintf('Collapsing features..\n');
for chan = 1:size(data,1)
%     fprintf('Collapsing feature %s of %s...\n',num2str(chan),num2str(size(data,3)));
    for trial = 1:size(data,3)

        for t = P_C_S.SamplingFrequency + round(P_C_S.SamplingFrequency/2); %1:numsamples-win
            swstart = t;
            swstop = t+win-1;
            d = squeeze(data(:,swstart:swstop,trial));
            d = reshape(d,1,size(d,1)*size(d,2));
%             outdata(trial,t,:) = d;
            outdata(:,1,trial) = d;

        end

    end
end

outdata = permute(outdata,[3 2 1]);

% outdata = outdata(:,1:numsamples-win,:);
P_C_S.Data = outdata;
