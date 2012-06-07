function [rhout, toout] = cspdistance_fs(CSP_O, testgoodchannels, num2use, FS, CVrun, basename)

%% load template csps
load('csptemplate_ideal_bigtoe.mat');
montageinfo = load('GSN-HydroCel-129.mat');

% load('csptemplate_64_own.mat');
% montageinfo = load('64channelset.mat');

%% only compare same channels across both
allgood = union(testgoodchannels,goodchannels);
allskip = setdiff(1:length(goodchannels),allgood);

%% get filter data from test set
spf = struct(get(CSP_O.objects,'spf'));

%ROWS OF W_CSP ARE SPATIAL FILTERS
% W_CSP = real(spf.D.W);
%COLUMNS OF A_CSP ARE SPATIAL PATTERNS
A_CSP = real(spf.D.A);

rhfs = find(FS<0.5);
tofs = find(FS>0.5);

A_CSPrh = A_CSP(:,rhfs);
A_CSPto = A_CSP(:,tofs);

%% root mean square deviation
RMS_rh = zeros(1,size(A_CSPrh,2));
RMS_to = zeros(1,size(A_CSPto,2));
RMS_rh_inv = zeros(1,size(A_CSPrh,2));
RMS_to_inv = zeros(1,size(A_CSPto,2));

% versus actual maps RH only
for plotidx = 1:size(A_CSPrh,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPrh(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_rh(plotidx) = sqrt((sum((rhchans - plotchans).^2))/length(rhchans));    
%     RMS_rh(plotidx) = RMS_rh(plotidx) .* (abs(FS(rhfs(plotidx))-0.5)*2);
    
end
% versus actual maps TO only
for plotidx = 1:size(A_CSPto,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPto(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_to(plotidx) = sqrt((sum((toechans - plotchans).^2))/length(toechans));
%     RMS_to(plotidx) = RMS_to(plotidx) .* (abs(FS(tofs(plotidx))-0.5)*2);

end

%versus inverse maps since sign means nothing on maps
rhchans = -rhchans;
toechans = -toechans;

% versus inverse maps RH only
for plotidx = 1:size(A_CSPrh,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPrh(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_rh_inv(plotidx) = sqrt((sum((rhchans - plotchans).^2))/length(rhchans));
%         RMS_rh_inv(plotidx) = RMS_rh_inv(plotidx) .* (abs(FS(rhfs(plotidx))-0.5)*2);

end
% versus inverse maps TO only
for plotidx = 1:size(A_CSPto,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPto(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_to_inv(plotidx) = sqrt((sum((toechans - plotchans).^2))/length(toechans));
%             RMS_to_inv(plotidx) = RMS_to_inv(plotidx) .* (abs(FS(tofs(plotidx))-0.5)*2);

end

% RMS_rh = RMS_rh ./ mean(RMS_rh);
% RMS_rh_inv = RMS_rh_inv ./ mean(RMS_rh_inv);
% RMS_to = RMS_to ./ mean(RMS_to);
% RMS_to_inv = RMS_to_inv ./ mean(RMS_to_inv);

% RMS_rh = RMS_rh ./ max(RMS_rh);
% RMS_rh_inv = RMS_rh_inv ./ max(RMS_rh_inv);
% RMS_to = RMS_to ./ max(RMS_to);
% RMS_to_inv = RMS_to_inv ./ max(RMS_to_inv);

RMS_rh = [RMS_rh RMS_rh_inv];
RMS_to = [RMS_to RMS_to_inv];

%% sort them

[~, rhfilts] = sort(RMS_rh,'ascend');
[~, tofilts] = sort(RMS_to,'ascend');

% inverse filters will have larger idxs because they were cat'd
for i = 1:length(rhfilts)
    if rhfilts(i) > size(A_CSPrh,2)
        rhfilts(i) = rhfilts(i) - size(A_CSPrh,2);
    end
end

for i = 1:length(tofilts)
    if tofilts(i) > size(A_CSPto,2)
        tofilts(i) = tofilts(i) - size(A_CSPto,2);
    end
end

if length(rhfilts) < num2use
    rhout = unique(rhfilts);
elseif length(rhfilts) >= num2use
    rhout = unique(rhfilts(1:num2use));
end

if length(tofilts) < num2use
    toout = unique(tofilts);
elseif length(tofilts) >= num2use
    toout = unique(tofilts(1:num2use));
end

rhout = rhfs(rhout);
toout = tofs(toout);

%% optionally plot them
filts = [rhout; toout];


chanlocs = montageinfo.chanlocs;
% screensize = get(0,'ScreenSize');
% figsize = [1280 1024];

h = figure('Name',sprintf('Spatial Patterns'));

for plotid = 1:length(filts)
    subplot(2,num2use,plotid);
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSP(:,filts(plotid));
    topoplot(plotchans,chanlocs,'electrodes','off');
    title(sprintf('%d (%.2f)',filts(plotid), FS(filts(plotid))));
       
end
filepath = 'Figures\';
figurefilename = [filepath char(basename) '_CSPs' num2str(CVrun) '.fig'];
%exportfig(h,figurefilename, 'color', 'rgb');
%saveas(h,figurefilename);

%% CODE TO PLOT BEST FILTERS - SRIVAS
% bestfilt = selectlist(length(filts));
% splinefile = '129_spline.spl';
% 
% figure('Color','white');
% plotchans = zeros(1,length(rhchans));
% plotchans(testgoodchannels) = A_CSP(:,filts(bestfilt(1)));
% subplot(1,2,1); topoplot(plotchans,chanlocs,'electrodes','off'); colorbar;
% plotchans = zeros(1,length(rhchans));
% plotchans(testgoodchannels) = A_CSP(:,filts(bestfilt(2)));
% subplot(1,2,2); topoplot(plotchans,chanlocs,'electrodes','off'); colorbar;
% saveas(gcf,sprintf('%s%s_bestfilt.fig',filepath,char(basename)));
% exportfig(gcf,sprintf('%s%s_bestfilt.eps',filepath,char(basename)),'color','rgb');
% 
% figure('Color','white');
% plotchans = zeros(1,length(rhchans));
% plotchans(testgoodchannels) = A_CSP(:,filts(bestfilt(1)));
% subplot(1,2,1); headplot(plotchans,splinefile,'electrodes','off','view',[0 90]);
% subplot(1,2,2); headplot(plotchans,splinefile,'electrodes','off','view',[-136 44]); zoom(1.5);
% saveas(gcf,sprintf('%s%s_rhfilt.fig',filepath,char(basename)));
% exportfig(gcf,sprintf('%s%s_rhfilt.eps',filepath,char(basename)),'color','rgb');
% 
% figure('Color','white');
% plotchans = zeros(1,length(rhchans));
% plotchans(testgoodchannels) = A_CSP(:,filts(bestfilt(2)));
% subplot(1,2,1); headplot(plotchans,splinefile,'electrodes','off','view',[0 90]);
% subplot(1,2,2); headplot(plotchans,splinefile,'electrodes','off','view',[-136 44]); zoom(1.5);
% saveas(gcf,sprintf('%s%s_tofilt.eps',filepath,char(basename)));
% exportfig(gcf,sprintf('%s%s_tofilt.eps',filepath,char(basename)),'color','rgb');