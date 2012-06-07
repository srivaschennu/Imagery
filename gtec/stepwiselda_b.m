function stepwiselda_b(P_C_S)

class_names = {'RIGHTHAND';'TOES'};

% %% Subtraction of baseline log power
% y = P_C_S.Data;
% subwin = [-1 0];
% %subwin = [0.1 2];
% fprintf('Subtracting baseline power within %.1f-%.1fs.\n',subwin(1),subwin(2));
% subwin = (subwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
% for t = 1:size(y,1)
%     for c = 1:size(y,3)
%     y(t,:,c) = log(y(t,:,c) ./ mean(y(t,2,c),2));
% %     y(t,:,c) = log(y(t,:,c) ./ mean(y(t,:,c),2));
%     end
% end
% P_C_S.Data = y;

% % Log Transform
% fprintf('Calculating log transform of bandpower channels.\n');
% ApplyOn = 'multiple channels';
% ChannelExclude_mult = [];
% TrialExclude_mult = [];
% Operation_mult = 'LOG10'; %log 10 operation so none of the parameters below matter!!
% SecondOperand_mult(1) = 5;
% Unit_mult = 'µV';
% FirstOperand_two = 1;
% Operation_two = 'SUB';
% SecondOperand_two = 2;
% ProgressBarFlag = 0;
% P_C_S = gBSarithmetic(P_C_S, ApplyOn, ChannelExclude_mult,...
%     TrialExclude_mult, Operation_mult, SecondOperand_mult,...
%     Unit_mult, FirstOperand_two, Operation_two,...
%     SecondOperand_two, ProgressBarFlag);

%% Feature Matrix
fprintf('Calculating feature matrix.\n');
targetwin = [0.1 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
% Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];
Interval=[125 25 1250];

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
            if length(testtrials) < 10
                fprintf('Excluding block %d of %s with %d trials.\n', b, class_names{c},length(testtrials));
            else
                CVtrials = cat(1, CVtrials, {testtrials});
            end
        end
    end
    fprintf('Training and test classifier with %d-fold cross validation over %d trials.\n', ...
        length(CVtrials),length(P_C_S.TrialNumber));
elseif strcmp(TrainTestMethod,'100:0');
    fprintf('Training only run with %d trials: run   ', length(P_C_S.TrialNumber));
    CVtrials = {P_C_S.TrialNumber};
end

% features = FM_O.Features;
% classlabels = FM_O.ClassLabels;
% classlabels = classlabels(1,:);
% classlabels(classlabels == 0) = -1;

features = P_C_S.Data;
Attribute = P_C_S.Attribute;
classlabels = Attribute(find(strcmp('RIGHTHAND',P_C_S.AttributeName)),:);
classlabels = classlabels(1,:)';
%classlabels(classlabels == 0) = -1;

% numsamples = size(features,1);
% numfeatures = size(features{1},1);

numsamples = size(features,2);
numfeatures = size(features,3);

trainaccu = zeros(length(CVtrials),numsamples);
testaccu = zeros(length(CVtrials),numsamples);
WM = zeros(length(CVtrials),numsamples,numfeatures+1);
WV = zeros(length(CVtrials),numfeatures);
bestwvidx = zeros(length(CVtrials),1);

% smoothwin = smoothwin .* P_C_S.SamplingFrequency;
% smoothwin = find(out_x(1,:) - out_x(1,1) < smoothwin, 1, 'last');

for run = 1:length(CVtrials)
    fprintf('Testing trials %s.\n', num2str(CVtrials{run}));

    usefeatures = false(size(features,2),size(features,3));

    %% train classifier
    for t = 1:numsamples
%         trainfeatures = features{t};
%         trainfeatures = trainfeatures(:,setdiff(1:length(P_C_S.TrialNumber),CVtrials{run}))';
%         trainlabels = classlabels(1,setdiff(1:length(P_C_S.TrialNumber),CVtrials{run}))';
         
%         trainfeatures = squeeze(features(setdiff(1:length(P_C_S.TrialNumber),runs(run):runs(run+1)-1),t,:));
%         trainlabels = classlabels(setdiff(1:length(P_C_S.TrialNumber),runs(run):runs(run+1)-1));
        
        trainfeatures = squeeze(features(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}),t,:));
        trainlabels = classlabels(cat(2,CVtrials{setdiff(1:length(CVtrials),run)}));

        r_pb = zeros(1,size(features,3));
        for f = 1:size(features,3)
            r_pb(f) = pointbiserial(trainlabels,trainfeatures(:,f));
        end
        
        [~,sortidx] = sort(r_pb,'descend');
        usefeatures(t,sortidx(1:round(size(trainfeatures,1)/10))) = true;

        %         [b,~,~,inmodel] = stepwisefit(trainfeatures,trainlabels,'display','off');
%         WM(run,t,:) = b'.*inmodel;
        
        b = glmfit(trainfeatures(:,usefeatures(t,:)),trainlabels,'binomial','link','logit');
        WM(run,t,1:sum(usefeatures(t,:))+1) = b;

        %         b = regress(trainlabels,trainfeatures);
        %         WM(run,t,:) = b';
        
%         trainres = trainfeatures * squeeze(WM(run,t,:));
        trainres = glmval(squeeze(WM(run,t,1:sum(usefeatures(t,:))+1)),trainfeatures(:,usefeatures(t,:)),'logit');

        trainaccu(run,t) = (sum(~xor(trainres > 0, trainlabels > 0))/length(trainlabels)) * 100;
    end
    
%     %smoothing window average
%     smooth_accu = zeros(size(trainaccu(run,:)));
%     for t = 1:numsamples
%         swstart = max(1,t-floor(smoothwin/2));
%         swstop = min(t+floor(smoothwin/2),size(trainaccu,2));
%         smooth_accu(1,t) = mean(trainaccu(run,swstart:swstop),2);
%     end
%     trainaccu(run,:) = smooth_accu;
    
    targetwinidx = find(targetwin(1) <= out_x(1,:),1,'first'):find(targetwin(2) <= out_x(1,:),1,'first');
    [~, bestidx] = max(trainaccu(run,targetwinidx),[],2);
    bestwvidx(run,1) = targetwinidx(bestidx);
%     WV(run,:) = squeeze(WM(run,bestwvidx(run,1),:))';
    %fprintf('Best classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
    
    %% test classifier
    if strcmp(TrainTestMethod,'CV')
        for t = 1:numsamples
%             testfeatures = features{t};
%             testfeatures = testfeatures(:,CVtrials{run})';
%             testlabels = classlabels(1,CVtrials{run})';
            
%             testfeatures = squeeze(features(runs(run):runs(run+1)-1,t,:));
%             testlabels = classlabels(runs(run):runs(run+1)-1);
%
            testfeatures = squeeze(features(CVtrials{run},t,:));
            testlabels = classlabels(CVtrials{run});
                       
            %testres = testfeatures * squeeze(WM(run,bestwvidx(run,1),:));
%             testres = testfeatures * squeeze(WM(run,t,:));

            testres = glmval(squeeze(WM(run,t,1:sum(usefeatures(t,:))+1)),testfeatures(:,usefeatures(t,:)),'logit');
            
            testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
        end
        
%         %smoothing window average
%         smooth_accu = zeros(size(testaccu(run,:)));
%         for t = 1:numsamples
%             swstart = max(1,t-floor(smoothwin/2));
%             swstop = min(t+floor(smoothwin/2),size(testaccu,2));
%             smooth_accu(1,t) = mean(testaccu(run,swstart:swstop),2);
%         end
%         testaccu(run,:) = smooth_accu;
    end
end
fprintf('\n');

if strcmp(TrainTestMethod,'CV')
    finalaccu = mean(testaccu,1);
elseif strcmp(TrainTestMethod,'100:0')
    finalaccu = trainaccu;
end

[bestaccu bestidx] = max(finalaccu(1,targetwinidx),[],2);
fprintf('\n%s: Best accuracy = %.1f at time %.1fs.\n\n', ...
    P_C_S.SubjectID, bestaccu, (out_x(1,targetwinidx(bestidx)) - P_C_S.PreTrigger)/P_C_S.SamplingFrequency);

WM = squeeze(WM);
WV = squeeze(WV);
save(sprintf('%s_swlda.mat',P_C_S.SubjectID),'WM','WV','bestwvidx','trainaccu','testaccu','finalaccu','bestaccu');

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

exportfig(gcf, ['figures/' P_C_S.SubjectID '_swlda.jpg'], 'format', 'jpeg', 'Color', 'cmyk');