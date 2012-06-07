function boottestlda(P_C_S,trainname)

filepath = 'D:\Data\Imagery\';
class_names = {'RIGHTHAND';'TOES'};

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

%% Feature Matrix
targetwin = [0 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];
fprintf('Calculating feature matrix over interval %d:%d:%d.\n',Interval(1),Interval(2),Interval(3));

ChannelExclude=[];
Permutate=0;
FileName='';
ProgressBarFlag = 0;
FM_O_test = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Test Classifer
fprintf('Loading training results from %s_bs.mat.\n',trainname);
load(sprintf('%s_bs.mat',trainname));

targetwinidx = find(targetwin(1) <= out_x(2,:),1,'first'):find(targetwin(2) <= out_x(2,:),1,'first');

ANS = zeros(length(C_O_boot),length(P_C_S.TrialNumber));
clres = zeros(length(Interval(1):Interval(2):Interval(3)), length(P_C_S.TrialNumber));

fprintf('Bootstrap test iteration:    ');

for bi = 1:length(C_O_boot)
    fprintf('\b\b\b%03d',bi - 1);
    
    [~, bestidx] = max(out_accu(bi,targetwinidx),[],2);
    % fprintf('Best classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
    ClassifierNumber = targetwinidx(bestidx);
    PlotFeatures = [];
    FileName = '';
    ProgressBarFlag = 0;
    C_O_train = C_O_boot{bi};
    C_O_test = gBStestclassifier(FM_O_test,C_O_train,ClassifierNumber,PlotFeatures,FileName,ProgressBarFlag);
    
    out_clstest = C_O_test.out_clstest;
    clres = zeros(length(out_clstest), length(P_C_S.TrialNumber));
    
    for idx = 1:length(out_clstest)
        clstest = out_clstest{idx};
        clres(idx,:) = clstest(1,:);
    end
    
    for t = 1:length(P_C_S.TrialNumber)
        ANS(bi,t) = binofit(sum(clres(targetwinidx,t)), length(clres(targetwinidx,t)));
    end
end
fprintf('\n');

bootp = zeros(1,length(P_C_S.TrialNumber));
for t = 1:length(P_C_S.TrialNumber)
    if ANS(1,t) >= 0.5
        bootp(t) = sum(ANS(2:end,t) >= ANS(1,t)) / length(ANS(2:end,t));
    elseif ANS(1,t) < 0.5
        bootp(t) = sum(ANS(2:end,t) <= ANS(1,t)) / length(ANS(2:end,t));
    end
end

%binomial fitting of trials
alpha = 0.05;
bootp = (bootp < alpha);
q = 1;
Attribute = P_C_S.Attribute;
binoans = [];
bino95ci = [];
bino99ci = [];
while true
    blockidx = strcmp(sprintf('BLOCK%d',q),P_C_S.AttributeName);
    if sum(blockidx) == 1
        trialidx = logical(Attribute(blockidx,:));
        [~, this95ci] = binofit(sum(round(ANS(1,trialidx & bootp))),length(round(ANS(1,trialidx & bootp))),0.05);
        [thisans, this99ci] = binofit(sum(round(ANS(1,trialidx & bootp))),length(round(ANS(1,trialidx & bootp))),0.01);
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
        fprintf('Question %d: Answer over %d trials: %d%s. ', q, sum(trialidx & bootp), round(thisans), siglevel);
    else
        break
    end
    q = q+1;
end

fprintf('Saving result.\n');
save ANS.mat binoans bino95ci bino99ci