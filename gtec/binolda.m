function binolda(P_C_S)

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
fprintf('Calculating feature matrix.\n');
targetwin = [0.1 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];

ChannelExclude=[];
Permutate=0;
FileName='FM_O.mat';
ProgressBarFlag = 0;
FM_O = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Cross Validation
% CVchunksize = round(length(P_C_S.TrialNumber)/20)*2;
% CVruns = 1:CVchunksize:length(P_C_S.TrialNumber);
% CVruns = [CVruns length(P_C_S.TrialNumber)+1];
CVtrials = {};
blocklist = find(strncmp('BLOCK', P_C_S.AttributeName, length('BLOCK')));

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
    
    for c = 1:length(class_names)
        trial_id=find(strcmp(class_names{c}, P_C_S.AttributeName));
        channel_id=[];
        type_id=[];
        channelnr_id=[];
        flag_tr='tr_exc';
        flag_ch='ch_exc';
        flag_type='type_exc';
        flag_nr='nr_exc';
        [thisclass, ~]=gBSselect(P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
        
        testtrials = intersect(thisblock,thisclass);
        if length(testtrials) < 10
            fprintf('Excluding block %d of %s with %d trials.\n', b, class_names{c},length(testtrials));
        else
            CVtrials = cat(1, CVtrials, {testtrials});
        end
    end
end

fprintf('Training and test classifier with %d-fold cross validation over %d trials.\n', ...
    length(CVtrials),length(P_C_S.TrialNumber));

trialres = [];
smoothwin = 0.2;
smoothwin = smoothwin .* P_C_S.SamplingFrequency;
testaccu = zeros(length(CVtrials),length(Interval(1):Interval(2):Interval(3)));

for run = 1:length(CVtrials)
    
    FM_O_train = FM_O;
    FM_O_test = FM_O;
    
    fprintf('Testing trials %s.\n', num2str(CVtrials{run}));
    features = FM_O_train.Features;
    for t = 1:size(features,1)
        thisfeature = features{t};
        features{t} = thisfeature(:,setdiff(1:length(P_C_S.TrialNumber),CVtrials{run}));
    end
    FM_O_train.Features = features;
    classlabels = FM_O_train.ClassLabels;
    FM_O_train.ClassLabels = classlabels(:,setdiff(1:length(P_C_S.TrialNumber),CVtrials{run}));
    
    features = FM_O_test.Features;
    for t = 1:size(features,1)
        thisfeature = features{t};
        features{t} = thisfeature(:,CVtrials{run});
    end
    FM_O_test.Features = features;
    classlabels = FM_O_test.ClassLabels;
    FM_O_test.ClassLabels = classlabels(:,CVtrials{run});
    
    %% Linear Classifier
    PlotFeatures = [];
    ClassifierType='LDA';
    P.metric='';
    %TrainTestData='100:100';
    %TrainTestData='50:50';
    TrainTestData='100:100';
    FileName='';
    ProgressBarFlag = 0;
    C_O_train=gBSlinearclassifier(FM_O_train,ClassifierType,P,TrainTestData,PlotFeatures,FileName,ProgressBarFlag);
    
    %% test classifier
    
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
    %fprintf('Best classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
    ClassifierNumber = targetwinidx(bestidx);
    PlotFeatures = [];
    FileName = '';
    ProgressBarFlag = 0;
    C_O_test = gBStestclassifier(FM_O_test,C_O_train,ClassifierNumber,PlotFeatures,FileName,ProgressBarFlag);

    out_err = C_O_test.out_err;
    
    for i=1:size(out_err,2)
        thiserr = out_err{2,i};
        out_accu(1,i) = 100 - thiserr(1);
        out_x(1:2,i) = out_err{1,i};
    end
    testaccu(run,:) = out_accu;
    
    %smoothing window average
    smoothwin = find(out_x(1,:) - out_x(1,1) < smoothwin, 1, 'last');
    smooth_accu = zeros(size(testaccu(run,:)));
    for t = 1:size(testaccu(run,:),2)
        swstart = max(1,t-floor(smoothwin/2));
        swstop = min(t+floor(smoothwin/2),size(testaccu,2));
        smooth_accu(1,t) = mean(testaccu(run,swstart:swstop),2);
    end
    testaccu(run,:) = smooth_accu;
    
    out_clstest = C_O_test.out_clstest;
    trialcount = length(CVtrials{run});
    clres = zeros(length(targetwinidx), trialcount);
    
    for idx = 1:length(out_clstest)
        clstest = out_clstest{idx};
        clres(idx,:) = clstest(1,:);
    end
    
    pscarf = zeros(1,trialcount);
    psig = zeros(1,trialcount);
    
    %binomial fitting of samples in each trial
    for t = 1:trialcount
        [phat pci] = binofit(sum(nonzeros(clres(targetwinidx,t))), length(clres(targetwinidx,t)));
        if pci(1) > 0.5 || pci(2) < 0.5
            pscarf(t) = round(phat);
            psig(t) = true;
        end
    end
    
    classlabels = FM_O_test.ClassLabels;
    classlabels = classlabels(1,:);
    trialres = [trialres ~xor(classlabels(logical(psig)), pscarf(logical(psig)))];
end

finalaccu = mean(testaccu,1);
[bestaccu bestidx] = max(finalaccu(1,targetwinidx),[],2);
fprintf('\n%s: Best accuracy = %.1f at time %.1fs.\n\n', ...
    P_C_S.SubjectID, bestaccu, out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger/P_C_S.SamplingFrequency));

%binomial fitting of trials
[binoaccu bino95ci] = binofit(sum(trialres),length(trialres));
fprintf('Binomial accuracy over %d trials = %.1f. 95%% CI = [%.1f %.1f].\n', length(trialres), binoaccu * 100, bino95ci(1)*100, bino95ci(2)*100);

save(sprintf('%s_binolda.mat',P_C_S.SubjectID),'bestaccu','binoaccu','bino95ci');

%% Plot Figure
fprintf('Plotting classifier performance.\n');
ylim = [50 100];
scrsize = get(0,'ScreenSize');
fsize = [1000 660];
figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
    'Name',P_C_S.SubjectID,'NumberTitle','off');
x=(out_x(2,:) - P_C_S.PreTrigger) * (1/P_C_S.SamplingFrequency);
y=finalaccu;
a=axes;

plot(x,y,'Parent',a,'Marker','.','LineWidth',3);
set(a,'YLim',ylim);
set(a,'XLim',[x(1) x(end)]);

line([0 0],[0 ylim(2)],'Color','black');
ylabel('Accuracy (%)');
xlabel('Time (s)');
title(sprintf('Single-trial classification accuracy for %s', P_C_S.SubjectID), 'Interpreter', 'none');
grid on

maximumX=max(get(a,'XLim'));
minimumX=min(get(a,'XLim'));
line([minimumX maximumX],[90 90],'Color','green');
line([minimumX maximumX],[70 70],'Color','yellow');
text(maximumX+0.2,91,'EXCELLENT','Rotation',90);
text(maximumX+0.2,78,'GOOD','Rotation',90);
text(maximumX+0.2,55,'MORE TRAINING','Rotation',90);

exportfig(gcf, ['figures/' P_C_S.SubjectID '_binolda.jpg'], 'format', 'jpeg', 'Color', 'cmyk');
