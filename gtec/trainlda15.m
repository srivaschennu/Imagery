function trainlda(P_C_S)

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

%% Subtraction of baseline log power
% y = P_C_S.Data;
% subwin = [-0.5 0];
% subwin = (subwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
% for c = 1:size(y,1)
%     for t = 1:size(y,3)
%     y(c,:,t) = y(c,:,t) - mean(y(c,subwin,t),2);
%     end
% end
% P_C_S.Data = y;

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
% yto(length(groups),:,:) = mean(yto(groups(end):end,:,:),1);
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
Interval=[25 25 P_C_S.PreTrigger+P_C_S.PostTrigger];
ChannelExclude=[];
Permutate=0;
FileName='FM_O.mat';
ProgressBarFlag = 0;
FM_O = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Linear Classifier
PlotFeatures = [];
%PlotFeatures = [1 2];
% if ~isempty(PlotFeatures)
%     load BC.mat
%     origchan = subset(origchan, badchannels);
%     PlotFeatures = [find(origchan == PlotFeatures(1)) find(origchan == PlotFeatures(2))];
% end

ClassifierType='LDA';
P.metric='';
%TrainTestData='100:100';
%TrainTestData='50:50';
TrainTestData='CV';
FileName=sprintf('%s_train.mat',P_C_S.SubjectID);
ProgressBarFlag = 0;
fprintf('Generating %s classifier with train-test method: %s.\n', ClassifierType, TrainTestData);
C_O=gBSlinearclassifier(FM_O,ClassifierType,P,TrainTestData,PlotFeatures,FileName,ProgressBarFlag);

if ~isempty(PlotFeatures)
    gResult2d(CreateResult2D(C_O));
end

%% Store classifier weights for every step
fprintf('Saving classifier output.\n');
out_wv  = C_O.out_clssfyr;
out_err = C_O.out_err;

fid = fopen('clres.txt','w');
fprintf(fid,'Subject: %s\n', P_C_S.SubjectID);
fprintf(fid,'Classification Method: %s\n', ClassifierType);
fprintf(fid,'Training and test option: %s\n', TrainTestData);
fprintf(fid,'Number of trials: %d\n',length(P_C_S.TrialNumber));
fprintf(fid,'\nSecond\tSample\tMean Error\tErr Std Dev\tRuns:\n');

out_accu = zeros(1,size(out_err,2));
out_x = zeros(2,size(out_err,2));
for i=1:size(out_err,2)
    thiserr = out_err{2,i};
    out_accu(i)=100 - thiserr(1);
    out_x(1:2,i) = out_err{1,i};
    fprintf(fid,'%.1f\t%d\t', out_x(1,i), out_x(2,i));
    fprintf(fid,'%.2f\t', thiserr);
    fprintf(fid,'\n');
end

if ~isempty(out_wv{1,1})
    fprintf(fid,'\nBias value and Weight Vector:\n');
    out_wv_ = zeros(size(out_wv{1,2},1)+1,size(out_wv,1));
    for i=1:size(out_wv,1)
        out_wv_(:,i) = [out_wv{i,1} out_wv{i,2}'];
        fprintf(fid,'%.2f\t',[out_wv{i,1} out_wv{i,2}']);
        fprintf(fid,'\n');
    end
    save WV.mat Interval out_accu out_x out_wv_;
end
fclose(fid);

smoothwin = 0.2;
smoothwin = smoothwin .* P_C_S.SamplingFrequency;
smoothwin = find(out_x(2,:) - out_x(2,1) < smoothwin, 1, 'last');

%smoothing window average
for t = 1:size(out_accu,2)
    swstart = max(1,t-floor(smoothwin/2));
    swstop = min(t+floor(smoothwin/2),size(out_accu,2));
    out_accu(1,t) = mean(out_accu(1,swstart:swstop),2);
end

targetwinidx = find(targetwin(1) <= out_x(2,:),1,'first'):find(targetwin(2) <= out_x(2,:),1,'first');
[bestaccu bestidx] = max(out_accu(1,targetwinidx),[],2);
fprintf('\n%s: Best accuracy = %.1f at time %.1fs.\n\n', ...
    P_C_S.SubjectID, bestaccu, out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger/P_C_S.SamplingFrequency));

%% Plot Figure
fprintf('Plotting classifier performance.\n');
ylim = [50 100];
scrsize = get(0,'ScreenSize');
fsize = [1000 660];
figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
    'Name',P_C_S.SubjectID,'NumberTitle','off');
x=out_x(1,:) - P_C_S.PreTrigger * (1/P_C_S.SamplingFrequency);
y=out_accu;
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
