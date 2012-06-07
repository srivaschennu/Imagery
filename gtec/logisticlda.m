function logisticlda(P_C_S)

class_names = {'RIGHTHAND';'TOES'};

% %% Subtraction of baseline log power
% y = P_C_S.Data;
% subwin = [-1 0];
% %subwin = [0.1 2];
% fprintf('Subtracting baseline power within %.1f-%.1fs.\n',subwin(1),subwin(2));
% subwin = (subwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
% for c = 1:size(y,1)
%     for t = 1:size(y,3)
%     y(c,:,t) = y(c,:,t) ./ mean(y(c,subwin(1):subwin(2),t),2);
%     end
% end
% P_C_S.Data = y;

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
%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];
ChannelExclude=[];
Permutate=0;
FileName='FM_O.mat';
ProgressBarFlag = 0;
fprintf('Calculating feature matrix over interval %d:%d:%d.\n',Interval(1),Interval(2),Interval(3));
FM_O = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Classification
targetwin = [1 3.5]; %time window relative to stimulus onset within which to identify best classifier accuracy
fprintf('Applying target window of %.1f-%.1fs.\n', targetwin(1), targetwin(2));

% TrainTestMethod = 'CV';
TrainTestMethod = '100:0';
smoothwin = 0.2;
out_x = Interval(1):Interval(2):Interval(3);

if strcmp(TrainTestMethod,'CV')
    fprintf('Running 10-fold cross validation over %d trials: fold   ', length(P_C_S.TrialNumber));
    CVchunksize = ceil(length(P_C_S.TrialNumber)/10);
    runs = 1:CVchunksize:length(P_C_S.TrialNumber);
    runs = [runs length(P_C_S.TrialNumber)+1];
elseif strcmp(TrainTestMethod,'100:0');
    fprintf('Training only run with %d trials: run   ', length(P_C_S.TrialNumber));
    runs = [1 1];
end

features = FM_O.Features;
classlabels = FM_O.ClassLabels;
classlabels = classlabels(1,:);
%classlabels(classlabels == 0) = 2;

numsamples = size(features,1);
numfeatures = size(features{1},1);
binores = [];

trainaccu = zeros(length(runs)-1,numsamples);
testaccu = zeros(length(runs)-1,numsamples);
WM = zeros(length(runs)-1,numsamples,numfeatures+1);
WV = zeros(length(runs)-1,numfeatures+1);
SM = cell(length(runs)-1,numsamples);
SV = cell(length(runs)-1);
bestwvidx = zeros(length(runs)-1,1);

targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
targetwinidx = find(targetwin(1) <= out_x(1,:),1,'first'):find(targetwin(2) <= out_x(1,:),1,'first');

smoothwin = smoothwin .* P_C_S.SamplingFrequency;
smoothwin = find(out_x(1,:) - out_x(1,1) < smoothwin, 1, 'last');

for run = 1:length(runs)-1
    fprintf('\b\b%02d', run);
    
    trainlabels = classlabels(1,setdiff(1:length(P_C_S.TrialNumber),runs(run):runs(run+1)-1))';
    
    %% train classifier
    for t = 1:numsamples
        trainfeatures = features{t};
        trainfeatures = trainfeatures(:,setdiff(1:length(P_C_S.TrialNumber),runs(run):runs(run+1)-1))';
        
        [b,~,stats] = glmfit(trainfeatures,trainlabels,'binomial','link','logit');
        %[b,~,stats] = mnrfit(trainfeatures,trainlabels);
        
        SM{run,t} = stats;
        WM(run,t,:) = b;
        
        trainres = glmval(b,trainfeatures,'logit');
        %trainres = mnrval(b,trainfeatures);
        
        trainres = round(trainres(:,1));
        trainaccu(run,t) = (sum(~xor(trainres == 1, trainlabels == 1))/length(trainlabels)) * 100;
    end
    
    %smoothing window average
    smooth_accu = zeros(size(trainaccu(run,:)));
    for t = 1:numsamples
        swstart = max(1,t-floor(smoothwin/2));
        swstop = min(t+floor(smoothwin/2),size(trainaccu,2));
        smooth_accu(1,t) = mean(trainaccu(run,swstart:swstop),2);
    end
    trainaccu(run,:) = smooth_accu;
    
    [~, bestidx] = max(trainaccu(run,targetwinidx),[],2);
    bestwvidx(run,1) = targetwinidx(bestidx);
    WV(run,:) = squeeze(WM(run,bestwvidx(run,1),:))';
    SV{run} = SM{run,bestwvidx(run,1)};
    %fprintf('Best classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
    
    trainfeatures = features{bestwvidx(run,1)}';
    figure; hold all;
    scatter(trainfeatures(find(trainlabels),1),(trainfeatures(find(trainlabels),2)));
    scatter(trainfeatures(find(~trainlabels),1),(trainfeatures(find(~trainlabels),2)));
    figure; hold all;
    scatter(trainfeatures(find(trainlabels),3),(trainfeatures(find(trainlabels),4)));
    scatter(trainfeatures(find(~trainlabels),3),(trainfeatures(find(~trainlabels),4)));

    %% test classifier
    if strcmp(TrainTestMethod,'CV')
        logres = [];
        testlabels = classlabels(1,runs(run):runs(run+1)-1)';
        testtrials = length(runs(run):runs(run+1)-1);
        
        for t = 1:numsamples
            testfeatures = features{t};
            testfeatures = testfeatures(:,runs(run):runs(run+1)-1)';
            
            %test with the best weight vector found during training
            %testres = glmval(WV(run,:)',testfeatures,'logit',SV{run});
            %[testres, thiscilo, thiscihi] = mnrval(WV(run,:)',testfeatures,SV{run});
            
            %test with corresponding weight vectors
            testres = glmval(squeeze(WM(run,t,:)),testfeatures,'logit',SM{run,t});
                        
            testres = round(testres(:,1));
            logres = cat(2,logres,testres);
            testaccu(run,t) = (sum(~xor(testres == 1, testlabels == 1))/length(testlabels)) * 100;
        end
        
        %binomial fitting of samples in each trial
        binoval = zeros(1,testtrials);
        binosig = zeros(1,testtrials);
        for t = 1:testtrials
            [phat pci] = binofit(sum(logres(t,targetwinidx)),length(logres(t,targetwinidx)));
            binoval(t) = round(phat);
            if pci(1) > 0.5 || pci(2) < 0.5
                binosig(t) = true;
            end
        end
        
        %consider only significantly classified trials
        binores = [binores ~xor(testlabels(logical(binosig))', binoval(logical(binosig)))];
        
        %consider all trials
        %binores = [binores ~xor(testlabels', binoval)];
        
        %smoothing window average
        smooth_accu = zeros(size(testaccu(run,:)));
        for t = 1:numsamples
            swstart = max(1,t-floor(smoothwin/2));
            swstop = min(t+floor(smoothwin/2),size(testaccu,2));
            smooth_accu(1,t) = mean(testaccu(run,swstart:swstop),2);
        end
        testaccu(run,:) = smooth_accu;
    end
end
fprintf('\n');

WM = squeeze(WM);
WV = squeeze(WV);

if strcmp(TrainTestMethod,'CV')
    finalaccu = mean(testaccu,1);
    
    % binomial fitting of trials
    [~, bino95ci] = binofit(sum(binores),length(binores),0.05);
    [binoaccu bino99ci] = binofit(sum(binores),length(binores),0.01);
    
    binoaccu = binoaccu * 100;
    bino95ci = bino95ci * 100;
    bino99ci = bino99ci * 100;
    
    siglevel = '';
    if bino95ci(1) > 50
        siglevel = '*';
    end
    if bino99ci(1) > 50
        siglevel = '**';
    end
    
    fprintf('\n%s: Accuracy over %d trials: %.1f%s. ', P_C_S.SubjectID, length(binores), binoaccu, siglevel);
    
    fprintf('95%% CI: [%.1f %.1f]. 99%% CI: [%.1f %.1f].\n\n', bino95ci(1), bino95ci(2), bino99ci(1), bino99ci(2));
    save(sprintf('%s_loglda.mat', P_C_S.SubjectID), 'WV', 'SV', 'binores', 'bestwvidx', 'trainaccu', 'testaccu', 'binoaccu', 'bino95ci', 'bino99ci');
    
elseif strcmp(TrainTestMethod,'100:0')
    finalaccu = trainaccu;
    save(sprintf('%s_loglda.mat', P_C_S.SubjectID), 'WM', 'SM', 'WV', 'SV', 'bestwvidx', 'trainaccu');
end

%% Plot Figure
fprintf('Plotting classifier performance.\n');
ylim = [50 100];
scrsize = get(0,'ScreenSize');
fsize = [1000 660];
figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
    'Name',P_C_S.SubjectID,'NumberTitle','off');
x=(out_x(1,:) - P_C_S.PreTrigger) * (1/P_C_S.SamplingFrequency);
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

exportfig(gcf, ['figures/' P_C_S.SubjectID '_loglda.jpg'], 'format', 'jpeg', 'Color', 'cmyk');
% close(gcf);
