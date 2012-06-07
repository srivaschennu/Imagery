function [rhout, toout] = cspdistance_eig(CSP_O, testgoodchannels, num2use, CVrun, basename)
fprintf('Using eigenvalue distance measure...\n');
%% load template csps
load('csptemplate_ideal.mat');

%% only compare same channels across both
allgood = union(testgoodchannels,goodchannels);
allskip = setdiff(1:129,allgood);

%% get filter data from test set
spf = struct(get(CSP_O.objects,'spf'));

%ROWS OF W_CSP ARE SPATIAL FILTERS
W_CSP = real(spf.D.W);
%COLUMNS OF A_CSP ARE SPATIAL PATTERNS
A_CSP = real(spf.D.A);

num2check = floor(size(W_CSP,2)/2);

A_CSPrheig = A_CSP(:,1:num2check);
A_CSPtoeig = A_CSP(:,end-num2check+1:end);

%% root mean square deviation
RMS_rh = zeros(1,size(A_CSPrheig,2));
RMS_to = zeros(1,size(A_CSPtoeig,2));
RMS_rh_inv = zeros(1,size(A_CSPrheig,2));
RMS_to_inv = zeros(1,size(A_CSPtoeig,2));

% versus actual maps: RH
for plotidx = 1:size(A_CSPrheig,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPrheig(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_rh(plotidx) = sqrt((sum((rhchans - plotchans).^2))/length(rhchans));
    
end
% versus actual maps: TO
for plotidx = 1:size(A_CSPtoeig,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPtoeig(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_to(plotidx) = sqrt((sum((toechans - plotchans).^2))/length(toechans));
    
end
rhchans = -rhchans;
toechans = -toechans;
% versus inverse maps: RH
for plotidx = 1:size(A_CSPrheig,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPrheig(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_rh_inv(plotidx) = sqrt((sum((rhchans - plotchans).^2))/length(rhchans));
    
end
% versus inverse maps: TO
for plotidx = 1:size(A_CSPtoeig,2)
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSPtoeig(:,plotidx);
    plotchans(allskip) = 0;
    
    RMS_to_inv(plotidx) = sqrt((sum((toechans - plotchans).^2))/length(toechans));
    
end

RMS_rh = [RMS_rh RMS_rh_inv];
RMS_to = [RMS_to RMS_to_inv];

%% sort them

[~, rhfilts] = sort(RMS_rh,'ascend');
[~, tofilts] = sort(RMS_to,'ascend');

% inverse filters will have larger idxs because they were cat'd
for i = 1:length(rhfilts)    
    if rhfilts(i) > size(A_CSPrheig,2)
        rhfilts(i) = rhfilts(i) - size(A_CSPrheig,2);
    end    
end
for i = 1:length(tofilts)
    if tofilts(i) > size(A_CSPtoeig,2)
        tofilts(i) = tofilts(i) - size(A_CSPtoeig,2);
    end
end

tofilts = size(A_CSP,2) - tofilts +1;

rhout = rhfilts(1:num2use);
toout = tofilts(1:num2use);

% filts = [rhfilts(1:num2use) tofilts(1:num2use)];
% filts = unique(filts);
% fprintf('Nearest filters are: %s\n', num2str(filts));

%% optionally plot them
filts = [rhout toout];
montageinfo = load('GSN-HydroCel-129.mat');
chanlocs = montageinfo.chanlocs;
screensize = get(0,'ScreenSize');
figsize = [1280 1024];

h = figure('Position',[screensize(3)/2-figsize(1)/2+20 screensize(4)/2-figsize(2)/2+20 figsize(1) figsize(2)],...
    'Name',sprintf('Spatial Patterns'));

for plotid = 1:length(filts)
    subplot(2,num2use,plotid);
    plotchans = zeros(1,length(rhchans));
    plotchans(testgoodchannels) = A_CSP(:,filts(plotid));
    topoplot(plotchans,chanlocs,'electrodes','on');
    title(sprintf('%d',filts(plotid)));
       
end
filepath = 'Figures\';
figurefilename = [filepath char(basename) '_CSPs' num2str(CVrun) '.eps'];
exportfig(h,figurefilename,'color','rgb');

figure;
splinefile = '129_spline.spl';
plotchans = zeros(1,length(rhchans));
plotchans(testgoodchannels) = A_CSP(:,filts(1));
subplot(1,2,1); headplot(plotchans,splinefile,'electrodes','off','view',[0 90]);
plotchans = zeros(1,length(rhchans));
plotchans(testgoodchannels) = A_CSP(:,filts(end));
subplot(1,2,2); headplot(plotchans,splinefile,'electrodes','off','view',[-136 44]); zoom(1.5);
