function plotweightmap(basename)

loadpaths

datafile = [filepath basename '.mat'];
trainfile = [basename '_train.mat'];

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);
fprintf('Loading %s.\n', trainfile);
load(trainfile);
C_O_train = C_O_S;
clear C_O_S

% load FM_O.mat
% 
%   P.CBperclass=[2];
%   P.alpha=[0.05];
%   P.epochs=[1000];
%   P.bootstraps=[20];
%   P.evaluation=[50];
%   Method=['DSLVQ'];
%   FileName=[''];
%   ProgressBarFlag=[0];
%   C_O_train=gBSdslvqfeatureweighting(F_O_S,Method,P,FileName,ProgressBarFlag);
  
Interval = C_O_train.interval;
out_err = C_O_train.out_err;
out_wv = C_O_train.out_clssfyr;

bcfile = [basename '_bc.mat'];
load(bcfile);
goodchannels = setdiff(origchan,badchannels);

if length(origchan) == 25
    montagefile = [montagepath 'GSN-HydroCel-129.sfp'];
    splinefile = [montagepath '129_spline.spl'];
elseif length(origchan) == 44
    montagefile =[montagepath 'GSN-HydroCel-257.sfp'];
    splinefile = [montagepath '257_spline.spl'];
end
chanlocs = readlocs(montagefile,'filetype','sfp');

%% pick weights to plot
out_accu = zeros(1,length(Interval(1):Interval(2):Interval(3)));
out_x = zeros(2,length(Interval(1):Interval(2):Interval(3)));

for i=1:size(out_err,2)
    thiserr = out_err{2,i};
    out_accu(1,i) = 100 - thiserr(1);
    out_x(1:2,i) = out_err{1,i};
end

targetwin = [0.1 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
targetwinidx = find(targetwin(1) <= out_x(2,:),1,'first'):find(targetwin(2) <= out_x(2,:),1,'first');

[~, bestidx] = max(out_accu(1,targetwinidx),[],2);
fprintf('Best training classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
plotweights = out_wv{targetwinidx(bestidx),2}';
plotweights = (plotweights(1:length(goodchannels)) + plotweights(length(goodchannels)+1:end))/2;

%% Plot scalp maps
plotchans = zeros(1,length(chanlocs));
plotchans(goodchannels) = plotweights(1,1:length(goodchannels));
figure;
%title(sprintf('%s - %s - %.1f-%.1fHz',basename,class_names{l},freqrange(fr,1),freqrange(fr,2)),'Interpreter','none');
subplot(1,2,2); headplot(plotchans,splinefile,'electrodes','off','view',[-136 44]); zoom(1.5);
subplot(1,2,1); headplot(plotchans,splinefile,'electrodes','off','view',[0 90]);
%colorbar

% plotchans = zeros(1,length(chanlocs));
% plotchans(goodchannels) = plotweights(1,length(goodchannels)+1:end);
% figure;
% %title(sprintf('%s - %s - %.1f-%.1fHz',basename,class_names{l},freqrange(fr,1),freqrange(fr,2)),'Interpreter','none');
% subplot(1,2,2); headplot(plotchans,splinefile,'electrodes','off','view',[-136 44]); zoom(1.5);
% subplot(1,2,1); headplot(plotchans,splinefile,'electrodes','off','view',[0 90]);
% %colorbar