function [t0, t1] = selecttime(P_C_S)

numchan = P_C_S.NumberChannels;
data = P_C_S.Data;

targetwinidx = 375:1375;
data = data(:,targetwinidx,:);

numpoints = size(data,2);

for c = 1:P_C_S.NumberChannels
    for t = 1:length(P_C_S.TrialNumber)
       data(t,:,c) = smoothdata(abs(hilbert(squeeze(data(t,:,c)))));
    end
end
P_C_S.Data = data;

Attribute = P_C_S.Attribute;
classlabels = Attribute(strcmp('RIGHTHAND',P_C_S.AttributeName),:);
classlabels(classlabels == 0) = -1;

data = P_C_S.Data;
score = zeros(numchan,numpoints);
for c = 1:numchan
    for t=1:numpoints
        r = corrcoef(data(:,t,c),classlabels');
        score(c,t) = r(1,2);
    end
end

[~, tmax] = max(sum(abs(score),1));

for c = 1:numchan
    if max(score(c,tmax-25:tmax+25) > 0) == 0
        score(c,:) = score(c,:) * -1;
    end
end
    
tscore = sum(score,1);
[~, tstarmax] = max(tscore);

thresh = 0.8 * sum(tscore(tscore > 0));

t0 = tstarmax; t1 = tstarmax;

while t0 > 1 && t1 < numpoints && sum(tscore(t0:t1)) < thresh
    if sum(tscore(tscore < t0)) > sum(tscore(tscore > t1))
        t0 = t0 - 1;
    else
        t1 = t1 + 1;
    end
end

t0 = targetwinidx(t0); t1 = targetwinidx(t1);
end

function smoothed_data = smoothdata(data)
    smoothwin = 50;
       numsamples = length(data);
       smoothed_data = zeros(size(data));
        for t = 1:numsamples
            swstart = max(1,t-floor(smoothwin/2));
            swstop = min(t+floor(smoothwin/2),length(data));
            smoothed_data(t) = mean(data(swstart:swstop),2);
        end
end
