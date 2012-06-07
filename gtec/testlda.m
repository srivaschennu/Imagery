function testlda(P_C_S,trainname)

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

%% Randomly assign trials to classes
Attribute = P_C_S.Attribute;
Attribute(strcmp(class_names{1},P_C_S.AttributeName),:) = round(rand(1,length(P_C_S.TrialNumber)));
Attribute(strcmp(class_names{2},P_C_S.AttributeName),:) = ~logical(Attribute(strcmp(class_names{1},P_C_S.AttributeName),:));
P_C_S.Attribute = Attribute;

%% Feature Matrix
fprintf('Calculating feature matrix.\n');
targetwin = [0 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];

ChannelExclude=[];
Permutate=0;
FileName='';
ProgressBarFlag = 0;
FM_O_test = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Test Classifer
fprintf('Loading training results from %s_train.mat.\n',trainname);
load(sprintf('%s_train.mat',trainname));
C_O_train = C_O;%_S;
clear C_O;%_S

out_accu = zeros(1,length(Interval(1):Interval(2):Interval(3)));
out_x = zeros(2,length(Interval(1):Interval(2):Interval(3)));

out_err = C_O_train.out_err;

for i=1:size(out_err,2)
    thiserr = out_err{2,i};
    out_accu(1,i) = 100 - thiserr(1);
    out_x(1:2,i) = out_err{1,i};
end

targetwinidx = find(targetwin(1) <= out_x(2,:),1,'first'):find(targetwin(2) <= out_x(2,:),1,'first');

[~, bestidx] = max(out_accu(1,targetwinidx),[],2);
fprintf('Best training classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
ClassifierNumber = targetwinidx(bestidx);
PlotFeatures = [];
FileName = '';
ProgressBarFlag = 0;
C_O_test = gBStestclassifier(FM_O_test,C_O_train,ClassifierNumber,PlotFeatures,FileName,ProgressBarFlag);

out_clstest = C_O_test.out_clstest;

clres = zeros(length(out_clstest), length(P_C_S.TrialNumber));

for idx = 1:length(out_clstest)
    clstest = out_clstest{idx};
    clres(idx,:) = clstest(1,:);
end

pscarf = zeros(1,length(P_C_S.TrialNumber));
psig = zeros(1,length(P_C_S.TrialNumber));
for t= 1:length(P_C_S.TrialNumber)
    [phat pci] = binofit(sum(clres(targetwinidx,t)), length(clres(targetwinidx,t)));
%     [phat pci] = binofit(sum(clres(targetwinidx(bestidx-15:bestidx+10),t)), length(clres(targetwinidx(bestidx-15:bestidx+10),t)));
    if pci(1) > 0.5 || pci(2) < 0.5
        pscarf(t) = round(phat);
        psig(t) = true;
    else
        pscarf(t) = round(phat);
        psig(t) = false;
    end
end

blocklist = find(strncmp('BLOCK', P_C_S.AttributeName, length('BLOCK')));
ANS = cell(length(blocklist),3);
for b = 1:length(blocklist)
    trial_id=blocklist(b);
    channel_id=[];
    type_id=[];
    channelnr_id=[];
    flag_tr='tr_exc';
    flag_ch='ch_exc';
    flag_type='type_exc';
    flag_nr='nr_exc';
    [thisblock, ~]=gBSselect(P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
    pthread = pscarf(thisblock);
    pthread = pthread(logical(psig(thisblock)));
    [~, p95ci] = binofit(sum(pthread),length(pthread));
    [phat p99ci] = binofit(sum(pthread),length(pthread),0.01);

    siglevel = '';
    if p95ci(1) > 0.5 || p95ci(2) < 0.5
        siglevel = '*';
    end
    if p99ci(1) > 0.5 || p99ci(2) < 0.5
        siglevel = '**';
    end
    
    phat = round(phat);
    p95ci = p95ci .* 100;
    p99ci = p99ci .* 100;
        
    fprintf('Question %d: Answer over %d trials = %d%s.\n', b, length(pthread), phat, siglevel);
%     fprintf('Or maybe it''s %f 5 points\n',mean(mean(clres(bestidx+75-5:bestidx+75+5,thisblock))));
%     fprintf('Or maybe it''s %f 10 points\n',mean(mean(clres(bestidx+75-10:bestidx+75+10,thisblock))));
%     fprintf('Or maybe it''s %f 1 point\n',mean(mean(clres(bestidx+75:bestidx+75,thisblock))));
%     
    ANS{b,1} = phat;
    ANS{b,2} = p95ci;
    ANS{b,3} = p99ci;
end
save ANS.mat ANS
