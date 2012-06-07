function analyse_bino(basename)

% warning off; % handles annoying GLMFIT warnings
% origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
origchan = [13 36 54 79 104 112 129 ];
% origchan = [36 104 129];
datapath = 'd:\data\imagery\';
% datapath = '';

rawfile = [datapath basename '.mat'];

if ~exist(rawfile,'file')
    fprintf('File not found: %s\n', rawfile);
    return;
end

fprintf('Loading %s.\n',rawfile);
load(rawfile);

fs = P_C_S.SamplingFrequency;
data = P_C_S.Data;
Attribute = P_C_S.Attribute;
[~, badchannels] = findbadtrialschannels(P_C_S);
goodchan = setdiff(origchan,badchannels);
Right_Hand = data(find(Attribute(strcmp('RIGHTHAND',P_C_S.AttributeName),:)),:,goodchan);
Toes = data(find(Attribute(strcmp('TOES',P_C_S.AttributeName),:)),:,goodchan);

% num2av = 5;
% 
% for k = 1:floor(size(Right_Hand,1)/num2av)
%     
%     RHout(k,:,:) = mean(Right_Hand(k*num2av-num2av+1:k*num2av,:,:),1);
%     TOout(k,:,:) = mean(Toes(k*num2av-num2av+1:k*num2av,:,:),1);
%     
% end
% 
% Right_Hand = RHout;
% Toes = TOout;

clear data

%% quick and dirty power calculation

% filter

fprintf('Calculating features...\n');

basewin = 125:374;
actwin = 500:749;
% actwin = 425:674;
% actwin = 375:624;
% basewin = actwin;
fftlen = 256;

% RH_bw_Data = zeros(size(Right_Hand,1),fftlen/2+1,size(Right_Hand,3));
% RH_aw_Data = zeros(size(Right_Hand,1),fftlen/2+1,size(Right_Hand,3));
% RH_lr_Data = zeros(size(Right_Hand,1),fftlen/2+1,size(Right_Hand,3));
% 
% TO_bw_Data = zeros(size(Toes,1),fftlen/2+1,size(Toes,3));
% TO_aw_Data = zeros(size(Toes,1),fftlen/2+1,size(Toes,3));
% TO_lr_Data = zeros(size(Toes,1),fftlen/2+1,size(Toes,3));

plotrange = [7 30];

figure;
% 
% winlen = 250;
% overlap = 0;

for c = 1:size(Right_Hand,3)
    for t = 1:size(Right_Hand,1)
        [RH_bw_Data(t,:,c),frange] = pwelch(squeeze(Right_Hand(t,basewin,c)),[],[],[],fs);
        RH_aw_Data(t,:,c) = pwelch(squeeze(Right_Hand(t,actwin,c)),[],[],[],fs);
        TO_bw_Data(t,:,c) = pwelch(squeeze(Toes(t,basewin,c)),[],[],[],fs);
        TO_aw_Data(t,:,c) = pwelch(squeeze(Toes(t,actwin,c)),[],[],[],fs);

%         [~,frange,~,RH_bw_Data(t,:,c)] = spectrogram(Right_Hand(t, basewin, c),winlen,overlap,winlen,P_C_S.SamplingFrequency);
%         [~,~,~,RH_aw_Data(t,:,c)] = spectrogram(Right_Hand(t, actwin, c),winlen,overlap,winlen,P_C_S.SamplingFrequency);
%         [~,~,~,TO_bw_Data(t,:,c)] = spectrogram(Toes(t, basewin, c),winlen,overlap,winlen,P_C_S.SamplingFrequency);
%         [~,~,~,TO_aw_Data(t,:,c)] = spectrogram(Toes(t, actwin, c),winlen,overlap,winlen,P_C_S.SamplingFrequency);
    end
    
    RHbasespec = squeeze(mean(RH_bw_Data(:,:,c),1));
    RHactspec = squeeze(mean(RH_aw_Data(:,:,c),1));
    TObasespec = squeeze(mean(TO_bw_Data(:,:,c),1));
    TOactspec = squeeze(mean(TO_aw_Data(:,:,c),1));
    
    basespec = squeeze(mean(cat(1,RH_bw_Data(:,:,c),TO_bw_Data(:,:,c)),1));
    actspec = squeeze(mean(cat(1,RH_aw_Data(:,:,c),TO_aw_Data(:,:,c)),1));
    logratio = log(actspec ./ basespec);
    
    RHlogratio = log(RHactspec ./ RHbasespec);
    TOlogratio = log(TOactspec ./ TObasespec);
    
    plotidx = find(frange >= plotrange(1) & frange <= plotrange(2));
    subplot(5,5,c); hold all;
%     plot(frange(plotidx),cat(1,RHlogratio(plotidx),TOlogratio(plotidx)));
%     plot(frange(plotidx),RHlogratio(plotidx),'r',frange(plotidx),TOlogratio(plotidx),'b');
    plot(frange(plotidx),logratio(plotidx));
    set(gca,'XLim',plotrange);
end

num2av = 3;

for k = 1:floor(size(Right_Hand,1)/num2av)
    
    RHawout(k,:,:) = mean(RH_aw_Data(k*num2av-num2av+1:k*num2av,:,:),1);
    RHbwout(k,:,:) = mean(RH_bw_Data(k*num2av-num2av+1:k*num2av,:,:),1);
    
    TOawout(k,:,:) = mean(TO_aw_Data(k*num2av-num2av+1:k*num2av,:,:),1);
    TObwout(k,:,:) = mean(TO_bw_Data(k*num2av-num2av+1:k*num2av,:,:),1);
    
end

RH_aw_Data = RHawout;
RH_bw_Data = RHbwout;
TO_aw_Data = TOawout;
TO_bw_Data = TObwout;

plotidx = find(frange >= plotrange(1) & frange <= plotrange(2));
RH_lr_Data = (RH_aw_Data(:,plotidx,:) ./ RH_bw_Data(:,plotidx,:));
TO_lr_Data = (TO_aw_Data(:,plotidx,:) ./ TO_bw_Data(:,plotidx,:));

RH_lr_Data = log(mean(RH_lr_Data,2));
TO_lr_Data = log(mean(TO_lr_Data,2));

% muband = [7 13];
% betaband = [13 25];
% muband = find(frange >= muband(1) & frange <= muband(2));
% betaband = find(frange >= betaband(1) & frange <= betaband(2));
% 
% 
% RH_mu_Data = squeeze(log(sum(RH_aw_Data(:,muband,:),2)./sum(RH_bw_Data(:,muband,:),2)));
% RH_beta_Data = squeeze(log(sum(RH_aw_Data(:,betaband,:),2)./sum(RH_bw_Data(:,betaband,:),2)));
% TO_mu_Data = squeeze(log(sum(TO_aw_Data(:,muband,:),2)./sum(TO_bw_Data(:,muband,:),2)));
% TO_beta_Data = squeeze(log(sum(TO_aw_Data(:,betaband,:),2)./sum(TO_bw_Data(:,betaband,:),2)));
    

% RH_features = cat(2,RH_mu_Data,RH_beta_Data);
% TO_features = cat(2,TO_mu_Data,TO_beta_Data);


% RH_features = reshape(RH_lr_Data,size(RH_lr_Data,1),size(RH_lr_Data,2)*size(RH_lr_Data,3));
RH_features = [];
for t = 1:size(RH_lr_Data,1)
    RH_features = cat(1,RH_features,RH_lr_Data(t,:));
end

TO_features = [];
for t = 1:size(TO_lr_Data,1)
    TO_features = cat(1,TO_features,TO_lr_Data(t,:));
end

features = zeros(size(RH_features,1)*2,size(RH_features,2));
features(1:2:end,:) = RH_features;
features(2:2:end,:) = TO_features;

classlabels = zeros(size(RH_features,1)*2,1);
classlabels(1:2:end) = 1;
% classlabels(classlabels == 0) = -1;
clear RH_features TO_features;

% run classification

CVchunksize = ceil(size(features,1)/10);
runs = 1:CVchunksize:size(features,1);
runs = [runs size(features,1)+1];
numfeatures = size(features,2);


% trainaccu = zeros(length(runs)-1,numsamples);
testaccu = zeros(length(runs)-1,1);
WM = zeros(numfeatures+1,length(runs)-1);
% WM = zeros(numfeatures,length(runs)-1);
% WV = zeros(length(runs)-1,numfeatures+1);

% bestwvidx = zeros(length(runs)-1,1);

fprintf('Running 10-fold cross validation over %d trials.\n', size(features,1));

for run = 1:length(runs)-1
%     fprintf('Run %d: %s.\n',run,num2str(runs(run):runs(run+1)-1));
    
    %% train classifier
    trainfeatures = features(setdiff(1:size(features,1),runs(run):runs(run+1)-1),:);
    trainlabels = classlabels(setdiff(1:size(features,1),runs(run):runs(run+1)-1));
    
%             [b,~,~,inmodel] = stepwisefit(trainfeatures,trainlabels,'display','off');
%             WM(:,run) = b.*inmodel';
    
    %         b = regress(trainlabels,trainfeatures);
    %         WM(run,t,:) = b';
    
    b = glmfit(trainfeatures,trainlabels,'binomial');
    WM(:,run) = b;
    
    %         trainres = glmval(WM(run,t,:),trainfeatures, 'logit');
    % %         trainres = trainfeatures * squeeze(WM(run,t,:));
    %         trainaccu(run,t) = (sum(~xor(trainres > 0, trainlabels > 0))/length(trainlabels)) * 100;
    
    %     %smoothing window average
    %     smooth_accu = zeros(size(trainaccu(run,:)));
    %     for t = 1:numsamples
    %         swstart = max(1,t-floor(smoothwin/2));
    %         swstop = min(t+floor(smoothwin/2),size(trainaccu,2));
    %         smooth_accu(1,t) = mean(trainaccu(run,swstart:swstop),2);
    %     end
    %     trainaccu(run,:) = smooth_accu;
    %
    %     [~, bestidx] = max(trainaccu(run,:),[],2);
    %     bestwvidx(run,1) = bestidx;
    %     WV(run,:) = squeeze(WM(run,bestwvidx(run,1),:))';
    %fprintf('Best classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
    
    %% test classifier
    testfeatures = features(runs(run):runs(run+1)-1,:);
    testlabels = classlabels(runs(run):runs(run+1)-1);
    
%             testres = testfeatures * squeeze(WM(:,run));
    
    testres = round(glmval(WM(:,run),testfeatures,'logit'));
    
    testaccu(run) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
    
end

finalaccu = mean(testaccu);

fprintf('\n');
fprintf('Best accuracy: %.1f\n',finalaccu);

if max(finalaccu) > 60
    
    fprintf('Good accuracy. Try questions if you can...\n');
    
else
    
    fprintf('Poor accuracy. Probably not worth trying questions...\n');
    
end

%% print classifier plot

% fprintf('Plotting classifier performance.\n');
% ylim = [50 100];
% scrsize = get(0,'ScreenSize');
% fsize = [1000 660];
% figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
%     'Name',basename,'NumberTitle','off');
% x=1:20:2000; %(out_x(1,:) - P_C_S.PreTrigger) * (1/P_C_S.SamplingFrequency);
% y=finalaccu;
% a=axes;
%
% plot(x,y,'Parent',a,'Marker','.','LineWidth',3);
% set(a,'YLim',ylim);
% set(a,'XLim',[x(1) x(end)]);
%
% line([0 0],[0 ylim(2)],'Color','black');
% ylabel('Accuracy (%)');
% xlabel('Time (s)');
% title(sprintf('Single-trial classification accuracy for %s', basename), 'Interpreter', 'none');
% grid on
%
% maximumX=max(get(a,'XLim'));
% minimumX=min(get(a,'XLim'));
% line([minimumX maximumX],[90 90],'Color','green');
% line([minimumX maximumX],[70 70],'Color','yellow');
% text(maximumX+0.2,91,'EXCELLENT','Rotation',90);
% text(maximumX+0.2,78,'GOOD','Rotation',90);
% text(maximumX+0.2,55,'MORE TRAINING','Rotation',90);

warning on;

end