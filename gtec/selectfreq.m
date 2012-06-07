function [f0, f1] = selectfreq(P_C_S)

Interval=[125 25 1250];
out_x = Interval(1):Interval(2):Interval(3);

f_low = 7;
f_step = 1;
f_high = 30;
fidx = f_low:f_step:f_high;

numchan = P_C_S.NumberChannels;

fprintf('Calculating bandpower in frequency bands between %d:%d:%dHz\n',f_low,f_step,f_high);
P_C_S = bandpower(P_C_S,P_C_S.SamplingFrequency,225,fidx);
fidx = fidx(1:end-1);

targetwin = [0 4]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
targetwinidx = find(targetwin(1) <= out_x(1,:),1,'first'):find(targetwin(2) <= out_x(1,:),1,'first');

Attribute = P_C_S.Attribute;
classlabels = Attribute(strcmp('RIGHTHAND',P_C_S.AttributeName),:);
classlabels(classlabels == 0) = -1;

data = P_C_S.Data;
data = log10(data);
score = zeros(numchan,length(fidx));
for c = 1:numchan
    for f=1:length(fidx)
        r = corrcoef(mean(data(:,targetwinidx,(c-1)*length(fidx)+f),2),classlabels');
        score(c,f) = r(1,2);
    end
end

[~, fmax] = max(sum(score,1));

for c = 1:numchan
    if score(c,fmax) <= 0
        score(c,:) = score(c,:) * -1;
    end
end
    
fscore = sum(score,1);
[~, fstarmax] = max(fscore);

f0 = fstarmax; f1 = fstarmax;

while f0 >= f_low && fscore(f0-1) >= fscore(fstarmax)*0.05
    f0  = f0 - 1;
end

while f1 <= f_high && fscore(f1+1) >= fscore(fstarmax)*0.05
    f1  = f1 + 1;
end

if f0 == f1
    if f0 > 1
        f0 = f0 - 1;
    end
    if f1 < length(fidx)
        f1 = f1 + 1;
    end
end

f0 = fidx(f0); f1 = fidx(f1);