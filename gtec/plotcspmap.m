function plotcspmap(CSP_O,filterscores,goodchannels,scorewise)

skipchan = [1    8   14   17   21   32   38   43   44   48   49   56   57   63   64   68   69   73   74   81   82   88   89   94   95   99  100  107  113  114  119  120  121  125  126  127  128];
plotcount = 20;
numcol = 5;

spf = struct(get(CSP_O.objects,'spf'));

%ROWS OF W_CSP ARE SPATIAL FILTERS
W_CSP = real(spf.D.W);
%COLUMNS OF A_CSP ARE SPATIAL PATTERNS
A_CSP = real(spf.D.A);

P_C_S = CSP_O.data;
montageinfo = load('GSN-HydroCel-129.mat');
chanlocs = montageinfo.chanlocs;
keepchan = setdiff(1:length(chanlocs),skipchan);

screensize = get(0,'ScreenSize');
figsize = [1280 1024];

if scorewise
    [~, sortidx] = sort(filterscores);
    plotfilt = [sortidx(1:plotcount/2); sortidx(end-plotcount/2+1:end)]';
else
    plotfilt = [1:plotcount/2 size(W_CSP,1)-plotcount/2+1:size(W_CSP,1)];
end


figure('Position',[screensize(3)/2-figsize(1)/2 screensize(4)/2-figsize(2)/2 figsize(1) figsize(2)],...
    'Name',sprintf('%s Spatial Filters',P_C_S.SubjectID));

for plotidx = 1:length(plotfilt)
    subplot(ceil(plotcount/numcol),numcol,plotidx);
    plotchans = zeros(1,length(chanlocs));
    plotchans(goodchannels) = W_CSP(plotfilt(plotidx),:);
    topoplot(plotchans(keepchan),chanlocs(keepchan),'electrodes','on');
    title(sprintf('%d (%.02f)',plotfilt(plotidx),filterscores(plotfilt(plotidx))));
end


figure('Position',[screensize(3)/2-figsize(1)/2+20 screensize(4)/2-figsize(2)/2+20 figsize(1) figsize(2)],...
    'Name',sprintf('%s Spatial Patterns',P_C_S.SubjectID));

for plotidx = 1:length(plotfilt)
    subplot(ceil(plotcount/numcol),numcol,plotidx);
    plotchans = zeros(1,length(chanlocs));
    plotchans(goodchannels) = A_CSP(:,plotfilt(plotidx));
    topoplot(plotchans(keepchan),chanlocs(keepchan),'electrodes','on');
    title(sprintf('%d (%.02f)',plotfilt(plotidx),filterscores(plotfilt(plotidx))));
end
