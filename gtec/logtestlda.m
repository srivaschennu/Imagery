function logtestlda(P_C_S,trainname)

class_names = {'RIGHTHAND';'TOES'};
%class_names = {'TOES'};

%% Log Transform
fprintf('Calculating log transform of bandpower channels.\n');
ApplyOn = 'multiple channels';
ChannelExclude_mult = [];
TrialExclude_mult = [];
Operation_mult = 'LOG10'; %log 10 operation so none of the parameters below matter!!
SecondOperand_mult(1) = 5;
Unit_mult = 'µV';
FirstOperand_two = 1;
Operation_two = 'SUB';
SecondOperand_two = 2;
ProgressBarFlag = 0;
P_C_S = gBSarithmetic(P_C_S, ApplyOn, ChannelExclude_mult,...
    TrialExclude_mult, Operation_mult, SecondOperand_mult,...
    Unit_mult, FirstOperand_two, Operation_two,...
    SecondOperand_two, ProgressBarFlag);

% y = P_C_S.Data;
% subwin = [-0.5 0];
% subwin = (subwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
% for c = 1:size(y,1)
%     for t = 1:size(y,3)
%     y(c,:,t) = y(c,:,t) - mean(y(c,subwin,t),2);
%     end
% end
% P_C_S.Data = y;

%% Randomly assign trials to classes
Attribute = P_C_S.Attribute;
Attribute(strcmp(class_names{1},P_C_S.AttributeName),:) = round(rand(1,length(P_C_S.TrialNumber)));
Attribute(strcmp(class_names{2},P_C_S.AttributeName),:) = ~logical(Attribute(strcmp(class_names{1},P_C_S.AttributeName),:));
P_C_S.Attribute = Attribute;

%% Feature Matrix
fprintf('Calculating feature matrix.\n');

%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];

ChannelExclude=[];
Permutate=0;
FileName='FM_O.mat';
ProgressBarFlag = 0;
FM_O = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Classification

targetwin = [0 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
fprintf('Applying target window of %.1f-%.1fs.\n', targetwin(1), targetwin(2));

out_x = Interval(1):Interval(2):Interval(3);

targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
targetwinidx = find(targetwin(1) <= out_x(1,:),1,'first'):find(targetwin(2) <= out_x(1,:),1,'first');

features = FM_O.Features;
% classlabels = FM_O.ClassLabels;
% classlabels = classlabels(1,:);
%classlabels(classlabels == 0) = 2;

numtrials = length(P_C_S.TrialNumber);
numsamples = size(features,1);

fprintf('Loading training data from %s_loglda.mat.\n',trainname);
% load(sprintf('%s_loglda.mat', trainname), 'WV', 'SV');
load(sprintf('%s_loglda.mat', trainname), 'WM', 'SM');
logres = [];
logressig = [];

for t = 1:numsamples
    testfeatures = features{t};
    testfeatures = testfeatures(:,P_C_S.TrialNumber)';
    
%     [thisres, thiscihi, thiscilo] = glmval(WV(1,:)',testfeatures,'logit',SV{1});
    [thisres, thiscihi, thiscilo] = glmval(WM(t,:)',testfeatures,'logit',SM{t});
    %logressig = cat(2,logressig, (thisres-thiscilo > 0.5 | thisres+thiscihi < 0.5));
    logressig = cat(2,logressig, ones(size(thisres)));
    thisres = round(thisres(:,1));
    logres = cat(2,logres,thisres);
end

%binomial fitting of samples in each trial
binoval = zeros(1,numtrials);
binosig = zeros(1,numtrials);
for t = 1:numtrials
    sigsamples = targetwinidx(logical(logressig(t,targetwinidx)));
    [phat pci] = binofit(sum(logres(t,sigsamples)),length(logres(t,sigsamples)));
    if pci(1) > 0.5 || pci(2) < 0.5
        binoval(t) = round(phat);
        binosig(t) = true;
    end
end

fprintf('\n');
%binomial fitting of trials
q = 1;
Attribute = P_C_S.Attribute;
binoans = [];
bino95ci = [];
bino99ci = [];
while true
    blockidx = strcmp(sprintf('BLOCK%d',q),P_C_S.AttributeName);
    if sum(blockidx) == 1
        trialidx = logical(Attribute(blockidx,:));

%         answers = binoval(trialidx & binosig);
        
        answers = logres(trialidx & binosig,targetwinidx);
        answers = answers(:);
        
        [~, this95ci] = binofit(sum(answers),length(answers),0.05);
        [thisans, this99ci] = binofit(sum(answers),length(answers),0.01);
        binoans = [binoans; round(thisans)];
        bino95ci = [bino95ci; this95ci];
        bino99ci = [bino99ci; this99ci];
        
        siglevel = '';
        if this95ci(1) > 0.5 || this95ci(2) < 0.5
            siglevel = '*';
        end
        if this99ci(1) > 0.5 || this99ci(2) < 0.5
            siglevel = '**';
        end
        fprintf('Question %d: Answer over %d trials: %d%s.\n', q, sum(trialidx & binosig), round(thisans), siglevel);
    else
        break
    end
    q = q+1;
end
fprintf('\n');

fprintf('Saving result.\n');
save(sprintf('%s_logtest.mat', P_C_S.SubjectID), 'binoans', 'bino95ci', 'bino99ci');