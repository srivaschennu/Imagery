function [bestaccu sig] = svmlda_b(P_C_S)

class_names = {'RIGHTHAND';'TOES'};

%% Subtraction of baseline log power
% y = P_C_S.Data;
% subwin = [-0.5 0];
% %subwin = [0.1 2];
% fprintf('Subtracting baseline power within %.1f-%.1fs.\n',subwin(1),subwin(2));
% subwin = (subwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
% subwin = round(subwin);
% subwin = subwin - 62;
% for t = 1:size(y,1)
%     for c = 1:size(y,3)
%     y(t,:,c) = log(y(t,:,c) ./ mean(y(t,subwin(1):subwin(2),c),2));
% %     y(t,:,c) = log(y(t,:,c) ./ mean(y(t,:,c),2));
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

%% trial subaveraging to increase SNR
% y = P_C_S.Data;
% yrh = y(1:2:end,:,:);
% yto = y(2:2:end,:,:);
%
% groupsize = 3;
% groups = 1:groupsize:size(yrh,1);
% for g = 1:length(groups)-1
%     yrh(g,:,:) = mean(yrh(groups(g):groups(g+1)-1,:,:),1);
%     yto(g,:,:) = mean(yto(groups(g):groups(g+1)-1,:,:),1);
% end
%
% yrh(length(groups),:,:) = mean(yrh(groups(end):end,:,:),1);
% y(1:2:length(groups)*2,:,:) = yrh(1:length(groups),:,:);
% yto(length(groups),:,:) = m   ean(yto(groups(end):end,:,:),1);
% y(2:2:length(groups)*2,:,:) = yto(1:length(groups),:,:);
% P_C_S.Data = y;
%
% ChannelExclude = [];
% TrialExclude = length(groups)*2+1:length(P_C_S.TrialNumber);
% P_C_S = gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
% fprintf('%d trials left after subaveraging.\n', length(P_C_S.TrialNumber));

%% Feature Matrix
fprintf('Calculating feature matrix.\n');
targetwin = [0.1 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
% targetwin = [13 30];
%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
% Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];

% Interval=[125 25 1250];
% Interval=[125 1 1250];
% Interval = [62 1 625];
Interval = [1 1 size(P_C_S.Data,2)];
% Interval=[1 1 1375];
% Interval=[63 1 1313];
% Interval = [62 25 1312];
% Interval = [12 1 1362];
% Interval = [125 125 1250]
% ChannelExclude=[];
% Permutate=0;
% FileName='FM_O.mat';
% ProgressBarFlag = 0;
% FM_O = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Classification
TrainTestMethod = 'CV';
%TrainTestMethod = '100:0';
smoothwin = 0.2;
out_x = Interval(1):Interval(2):Interval(3);

if strcmp(TrainTestMethod,'CV')
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
%             if length(testtrials) < 10
%                 fprintf('Excluding block %d of %s with %d trials.\n', b, class_names{c},length(testtrials));
%             else
                CVtrials = cat(1, CVtrials, {testtrials});
%             end
        end
    end
    fprintf('Training and test classifier with %d-fold cross validation over %d trials.\n', ...
        length(CVtrials),length(P_C_S.TrialNumber));
elseif strcmp(TrainTestMethod,'100:0');
    fprintf('Training only run with %d trials: run   ', length(P_C_S.TrialNumber));
    CVtrials = {P_C_S.TrialNumber};
end
% 

% for k = 1:length(CVtrials)
%    
%     x = CVtrials{k};
%     x = x(1:round(length(x)/2));
%     CVtrials{k} = x;
%     
% end


%% 2 blocks at a time?

for i = 1:length(CVtrials)/2
    
   newCVtrials{i} = cat(2,CVtrials{i*2-1:i*2}); 
    
end

badCVs = [];

for k = 1:length(newCVtrials)
    if length(newCVtrials{k}) < 5
        badCVs = [badCVs k];
        fprintf('Excluding block %d with %d trials.\n', k, length(newCVtrials{k}));
    end
end

% if length(CVtrials) > 4
%     badCVs = [badCVs 5:length(CVtrials)];
% end


newCVtrials = newCVtrials(setdiff(1:length(newCVtrials),badCVs));

CVtrials = newCVtrials;

% %% make it 100:100
% clear CVtrials;
% CVtrials{1} = P_C_S.TrialNumber;
% CVtrials{2} = P_C_S.TrialNumber;

% features = FM_O.Features;
% classlabels = FM_O.ClassLabels;
% classlabels = classlabels(1,:);
% classlabels(classlabels == 0) = -1;

features = P_C_S.Data;

if iscell(features)
    features = cell2mat(features);
end

Attribute = P_C_S.Attribute;
classlabels = Attribute(find(strcmp('RIGHTHAND',P_C_S.AttributeName)),:);
classlabels = classlabels(1,:)';
% classlabels(classlabels == 0) = -1;

% numsamples = size(features,1);
% numfeatures = size(features{1},1);

numsamples = size(features,2);
numfeatures = size(features,3);

trainaccu = zeros(length(CVtrials),numsamples);
testaccu = zeros(length(CVtrials),numsamples);
% WM = zeros(length(CVtrials),numsamples,numfeatures);
WM = cell(numsamples,1);
% WV = zeros(length(CVtrials),numfeatures);
bestwvidx = zeros(length(CVtrials),1);
% F = [];
smoothwin = smoothwin .* P_C_S.SamplingFrequency;
smoothwin = find(out_x(1,:) - out_x(1,1) < smoothwin, 1, 'last');
% num2use = 25;
AllCoeffs = {};
allaccs = [];

for run = 1:length(CVtrials)
    fprintf('Testing trials %s.\n', num2str(CVtrials{run}));
    
%     %% train classifier
%     for t = 1:numsamples
% %         
%         trainfeatures = squeeze(features(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}),t,:));
%         trainlabels = classlabels(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}));
%         
% %         %% normalise for SVM
% %         
% %         for feat = 1:size(trainfeatures,2)            
% %             meanfeats(feat) = mean(trainfeatures(:,feat));
% %             stdfeats(feat) = std(trainfeatures(:,feat));
% %             normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);            
% %         end
% %         trainfeatures = normtrainfeats;
% %         
%         b = NaiveBayes.fit(trainfeatures,trainlabels);
%         WM{t,:} = b;
%         trainres = b.predict(trainfeatures);
%         
% %                 b = svmtrain(trainfeatures,trainlabels);
% %           trainres = (svmclassify(b,trainfeatures));
% %                 WM{t,:} = b;
% 
%         trainaccu(run,t) = (sum(~xor(trainres > 0, trainlabels > 0))/length(trainlabels)) * 100;
%     end
%     clear normtrainfeats;
%     %smoothing window average
%     smooth_accu = zeros(size(trainaccu(run,:)));
%     for t = 1:numsamples
%         swstart = max(1,t-floor(smoothwin/2));
%         swstop = min(t+floor(smoothwin/2),size(trainaccu,2));
%         smooth_accu(1,t) = mean(trainaccu(run,swstart:swstop),2);
%     end
%     trainaccu(run,:) = smooth_accu;
%     
        targetwinidx = find(targetwin(1) <= out_x(1,:),1,'first'):find(targetwin(2) <= out_x(1,:),1,'first');
% 
%     [~, bestidx] = max(trainaccu(run,targetwinidx),[],2);
%     bestwvidx(run,1) = targetwinidx(bestidx);
% %     WV = squeeze(WM(bestwvidx(CVrun,1),:))';
%     WV = WM{bestwvidx(run,1),:};
%     [~, bestidx] = max(trainaccu(run,targetwinidx),[],2);
%     bestwvidx(run,1) = targetwinidx(bestidx);
%     WV(run,:) = squeeze(WM(run,bestwvidx(run,1),:))';
    %fprintf('Best classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
    
    %% test classifier
%     num2use = 120;
    if strcmp(TrainTestMethod,'CV')
        for t = 1:numsamples
%             testfeatures = features{t};
%             testfeatures = testfeatures(:,CVtrials{run})';
%             testlabels = classlabels(1,CVtrials{run})';
            
%             testfeatures = squeeze(features(runs(run):runs(run+1)-1,t,:));
%             testlabels = classlabels(runs(run):runs(run+1)-1);
%             
        trainfeatures = squeeze(features(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}),t,:));
        trainlabels = classlabels(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}));

%         %% feature selection
% %         fprintf('Selecting best %s features\n',num2str(num2use));
%         logicallabels = trainlabels;
%         logicallabels(logicallabels == -1) = 0;
%         rhFeats = trainfeatures(logical(logicallabels),:);
%         toFeats = trainfeatures(logical(~logicallabels),:);
%         
% %         rhFeats = rhFeats(1:min(size(rhFeats,1),size(toFeats,1)),:);
% %         toFeats = toFeats(1:size(rhFeats,1),:);
%         
%         for feat = 1:size(trainfeatures,2)            
%             F(run,t,feat) = (mean(rhFeats(:,feat)) - mean(toFeats(:,feat))).^2 / (var(rhFeats(:,feat)) + var(toFeats(:,feat))); % Fisher distance
% %             F(run,t,feat) = sqrt(sum((rhFeats(:,feat) - toFeats(:,feat)))./size(rhFeats,2)); % RMS distance
%         end
%         
% %         [Fsort, Fidx] = sort(F(run,t,:),'descend');
% % %         figure; bar(squeeze(Fsort));
% %         trainfeatures = trainfeatures(:,Fidx(1:num2use));
%         
%         Fidx = find(F(run,t,:)>(mean(F(run,t,:))+std(F(run,t,:))));
%         if ~isempty(Fidx)
%             trainfeatures = trainfeatures(:,Fidx);
%         end

        %%
        
        testfeatures = squeeze(features(CVtrials{run},t,:));
        
%         %% feature selection
% %         testfeatures = testfeatures(:,Fidx(1:num2use));
%         if ~isempty(Fidx)
%             testfeatures = testfeatures(:,Fidx);
%         end
        %%
        
        %             testfeatures = testfeatures(:,Fidx(t,1:num2use));
        
        %% normalise for SVM        
        for feat = 1:size(trainfeatures,2)            
            meanfeats(feat) = mean(trainfeatures(:,feat));
            stdfeats(feat) = std(trainfeatures(:,feat));
            normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);            
        end
        trainfeatures = normtrainfeats;
        
        for feat = 1:size(testfeatures,2)
            normtestfeats(:,feat) = (testfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        end
        testfeatures = normtestfeats;
        clear meanfeats stdfeats normtrainfeats normtestfeats;
%         
        
        testlabels = classlabels(CVtrials{run});
        %             testres = svmclassify(WV,testfeatures);
        %             testres = svmclassify(WM{t,:},testfeatures);
        %% use time point wise classifier
%         testlabels(testlabels == 0) = -1;
%         [b, ~, ~, inmodel] = stepwisefit(trainfeatures,trainlabels,'display','off');
%         testres = testfeatures*(b.*inmodel');
        
        b = svmtrain(trainfeatures,trainlabels,'autoscale','false');
        AllCoeffs{run} = b;
        testres = svmclassify(b,testfeatures);
%         [testres,~,~,~,coefs] = classify(testfeatures,trainfeatures,trainlabels,'diaglinear');
%         AllCoeffs{run} = coefs;
        allaccs = [allaccs; ~xor(testres > 0, testlabels > 0)];
        testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
        
%         %% use best classifier
%         testres = classify(trainfeatures,trainfeatures,trainlabels,'linear');
%         testaccu(run,t) = (sum(~xor(testres > 0, trainlabels > 0))/length(trainlabels)) * 100;

        %%
        
        %             testres = WV.predict(testfeatures);
        %             testres = WM{t,:}.predict(testfeatures);
        %             %testres = testfeatures * squeeze(WM(run,bestwvidx(run,1),:));
        % %             testres = testfeatures * squeeze(WM(run,t,:));
        %             testres = testfeatures * squeeze(cell2mat(WX{run,t})');
        %             testres = round(glmval(cell2mat(WX{run,t})',testfeatures,'logit'));

        end
        clear normtestfeats;
        %smoothing window average
%         smooth_accu = zeros(size(testaccu(run,:)));
%         for t = 1:numsamples
%             swstart = max(1,t-floor(smoothwin/2));
%             swstop = min(t+floor(smoothwin/2),size(testaccu,2));
%             smooth_accu(1,t) = mean(testaccu(run,swstart:swstop),2);
%         end
%         testaccu(run,:) = smooth_accu;
        
%         %% use best classifier instead?
%         [~, bestidx] = max(testaccu(run,targetwinidx),[],2);
%         bestwvidx(run,1) = targetwinidx(bestidx);
%         
%         for t = 1:numsamples
%             
%             trainfeatures = squeeze(features(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}),bestwvidx(run,1),:));
%             trainlabels = classlabels(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}));
%             testfeatures = squeeze(features(CVtrials{run},t,:));
%             testlabels = classlabels(CVtrials{run});
%             testres = classify(testfeatures,trainfeatures,trainlabels,'linear');
%             testaccuout(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
%            
%         end
%         
%         smooth_accu = zeros(size(testaccuout(run,:)));
%         for t = 1:numsamples
%             swstart = max(1,t-floor(smoothwin/2));
%             swstop = min(t+floor(smoothwin/2),size(testaccuout,2));
%             smooth_accu(1,t) = mean(testaccuout(run,swstart:swstop),2);
%         end
%         testaccuout(run,:) = smooth_accu;
        
    end
    
    %% plot coeffs at best accuracy point?
%     [~, bestidx] = max(smooth_accu(1,targetwinidx),[],2);
%     trainfeatures = squeeze(features(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}),targetwinidx(bestidx),:));
%     trainlabels = classlabels(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}));
%     testfeatures = squeeze(features(CVtrials{run},targetwinidx(bestidx),:));
%     
%     [~,~,~,~,coeffs] = classify(testfeatures,trainfeatures,trainlabels,'diaglinear');
%     AllCoeffs{run} = coeffs;
%     plotcoeffs(coeffs);

    
end
fprintf('\n');

% %% best classifier
% testaccu = testaccuout;
%%

save([P_C_S.SubjectID '_tempcoeffs.mat'], 'AllCoeffs');

%plotcoeffs(AllCoeffs);

if strcmp(TrainTestMethod,'CV')
    finalaccu = mean(testaccu,1);
elseif strcmp(TrainTestMethod,'100:0')
    finalaccu = trainaccu;
end

% figure;plot(finalaccu);
% return;

if numsamples == 1
    [phat, pci05] = binofit(sum(allaccs),length(allaccs),0.05);
    [~, pci01] = binofit(sum(allaccs),length(allaccs),0.01);
        [~, pci001] = binofit(sum(allaccs),length(allaccs),0.001);
    bestaccu = phat*100;
%     bestaccu = finalaccu;
    
    sig = 'x';
    
    if pci05(1) > 0.5
        sig = '*';
    end
    if pci01(1) > 0.5
        sig = '**';
    end   
    if pci001(1) > 0.5
        sig = '***';
    end
    fprintf('Mean classification accuracy for %s: %.1f %s across %s trials\n',P_C_S.SubjectID,bestaccu,char(sig),num2str(length(allaccs)));

    return;
elseif numsamples == 2
    bestaccu = finalaccu;
    fprintf('Baseline: %.1f  Action: %.1f  Difference: %.1f\n',bestaccu(1),bestaccu(2),bestaccu(2)-bestaccu(1));
    return;
end


[bestaccu bestidx] = max(finalaccu(1,targetwinidx),[],2);
fprintf('\n%s: Best accuracy = %.1f at time %.1fs.\n\n', ...
    P_C_S.SubjectID, bestaccu, (out_x(1,targetwinidx(bestidx)) - P_C_S.PreTrigger)/P_C_S.SamplingFrequency);



% WM = squeeze(WM);
% WV = squeeze(WV);
save(sprintf('%s_bayeslda.mat',P_C_S.SubjectID),'bestwvidx','trainaccu','testaccu','finalaccu','bestaccu');

%% Plot Figure
fprintf('Plotting classifier performance.\n');
ylim = [50 100];
scrsize = get(0,'ScreenSize');
fsize = [1000 660];
j = figure('Name',P_C_S.SubjectID,'NumberTitle','off');
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

filepath = 'Figures\';
figurefilename = [filepath char(P_C_S.SubjectID) '_bayes.eps'];
exportfig(j,figurefilename, 'color', 'rgb');