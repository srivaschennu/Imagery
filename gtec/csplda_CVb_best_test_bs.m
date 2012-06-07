function bestaccu = csplda_CVb_best_test_bs(basename)


filepath = '\\vmware-host\Shared Folders\dcruse\Motor Imagery\Data\';
datafile = [filepath basename '.mat'];
class_names = {'RIGHTHAND';'TOES'};

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);

%% Pick out any bad channels

[~, badchannels] = findbadtrialschannels(P_C_S);
save(sprintf('%s_bc.mat', P_C_S.SubjectID),'badchannels');


% %% trial subaveraging to increase SNR
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

%% interpolate bad channels
% if ~isempty(badchannels)
%     P_C_S = interpBAD(P_C_S, badchannels);
%     badchannels = [];
% end

%% find the necessary channels that are good for fqbchans

% fqbchans = [36 129];
% % % fqbchans = [36 29 30 37 42 41 35 7 106 80 55 31];
% fqbchans = setdiff(fqbchans,badchannels);

%% find optimal time-window
cspwin = [1 3.5];
cspwin = (cspwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;

% cspwin = timewinselect(P_C_S,fqbchans);

%% find most reactive frequency band
fqb = [7 30];
% fqb = freqbandselect(P_C_S,fqbchans,cspwin);

%% cut out useless channels
% origchan = 1:129;
% 1020
% origchan = [9 11 22 24 33 36 45 52 58 62 70 75 83 92 96 104 108 122 124];
% the 25
% origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
% bigger 56
% origchan = [4    5    6    7   11   12   13   19   20   24   27   28   29   30   31   34   35   36   37   40   41   42   46   47   51   52   53   54   55   60   61   62   78   79   80   85   86   87   92   93   97   98  102  103  104  105  106  109  110  111  112  116  117  118  123  124  129];
% bigger 40ish
% origchan = [6    7   13   20   28   29   30   31   34   35   36   37   40   41   42   46   47   52   53   54   55   79   80   86   87   92   93   98  102  103  104  105  106  109  110  111  112  116  117  118  129];
% skipchan = [1    8   14   17   21   32   38   43   44   48   49   56   57   63   64   68   69   73   74   81   82   88   89   94   95   99  100  107  113  114  119  120  121  125  126  127  128 129];

% origchan = 1:65;
% 65 chan middle 28
% origchan = [4 54 51 41 7 16 21 34 15 20 22 26 27 28 25 24 19 14 53 50 57 56 49 46 42 45 48 52];
% skipchan = [1 61 55 47 43 32 29 23 64 17 63 62 65];

% origchan = [22 15 9 33 23 11 3 122 24 124 34 28 20 118 117 116 6 40 35 110 109 45 36 30 7 106 105 104 108 50 47 42 54 55 79 93 98 101 52 62 92 58 59 67 72 77 91 96 66 84 70 75 83 60 85 37 87 12 5 29 111 41 103 16];
% origchan = sort(origchan);
% skipchan = [22 15 9 23 16 3 33 24 11 124 122 70 75 83 66 84 58 59 60 67 72 77 85 91 96];
% skipchan = sort(skipchan);

% skipchan = [];

origchan = 1:64;
% skipchan = [];
skipchan = [1,5,6,8,9,11,12,13,17,31,32,33,35,36,37,38,39,40,42,43,44,46,49,63,64];


[~, chanix] = intersect(origchan,skipchan);
skipchan = chanix;
chans2plot = setdiff(1:length(origchan), skipchan);
origchan = setdiff(origchan,origchan(skipchan));
fprintf('CSPs will be calculated over %s channels\n',num2str(length(origchan)));
fprintf('Rejecting %d bad channels: %s.\n', length(intersect(origchan,badchannels)), num2str(intersect(origchan,badchannels)));
TrialExclude=[];
goodchannels = setdiff(origchan,badchannels);
ChannelExclude = setdiff(1:P_C_S.NumberChannels,goodchannels);

if ~isempty(ChannelExclude)
    P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
end

%% Randomly assign trials to classes
% Attribute = P_C_S.Attribute;
% Attribute(strcmp(class_names{1},P_C_S.AttributeName),:) = Attribute(strcmp(class_names{1},P_C_S.AttributeName),randperm(length(P_C_S.TrialNumber)));
% Attribute(strcmp(class_names{2},P_C_S.AttributeName),:) = ~logical(Attribute(strcmp(class_names{1},P_C_S.AttributeName),:));
% P_C_S.Attribute = Attribute;

%% Filter
clear Filter  % me
Filter.Realization='butter';
Filter.Type='BP';
Filter.Order=5;
Filter.f_low=fqb(1);
Filter.f_high=fqb(2);
TrialExclude=[];
% ChannelExclude=badchannels;
ChannelExclude=[];
fprintf('Filtering between %d-%dHz.\n', Filter.f_low, Filter.f_high);
P_C_S=gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);


boots = 200;
bs_accs = zeros(1,boots);
for bi = 1:boots

%% calculate which trials in which block and exclude blocks with low trial numbers
blocklist = find(strncmp('BLOCK', P_C_S.AttributeName, length('BLOCK')));

allAtts = P_C_S.Attribute;
blocks2exclude = [];
attNames = P_C_S.AttributeName;

for block = 1:length(blocklist)
    
    blocklength(block) = sum(allAtts(blocklist(block),:));
    
    if blocklength(block) < 15
        blocks2exclude = [blocks2exclude blocklist(block)];
        fprintf('Excluding %s due to too few trials...\n',char(attNames(blocklist(block))));
    end

%     numRH = sum(allAtts(strcmp(attNames,'RIGHTHAND'),logical(allAtts(blocklist(block),:))));
%     numTO = length(allAtts(strcmp(attNames,'RIGHTHAND'),logical(allAtts(blocklist(block),:)))) - numRH;
%     
%     if numRH < 10 || numTO < 10
%         blocks2exclude = [blocks2exclude blocklist(block)];
%         fprintf('Excluding %s due to too few trials...\n',char(attNames(blocklist(block))));
%     end

end

blocklist = setdiff(blocklist,blocks2exclude);

% fprintf('Running %s-fold cross validation: fold   ', num2str(length(blocklist)));
targetwin = [1 3.5]; %time window relative to stimulus onset within which to identify best classifier accuracy
fprintf('Applying target window of %.1f-%.1fs.\n', targetwin(1), targetwin(2));

Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];
smoothwin = 0.2;
% numsamples = size(features,1);
numsamples = 275;

out_x = Interval(1):Interval(2):Interval(3);   
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
targetwinidx = find(targetwin(1) <= out_x(1,:),1,'first'):find(targetwin(2) <= out_x(1,:),1,'first');

smoothwin = smoothwin .* P_C_S.SamplingFrequency;
smoothwin = find(out_x(1,:) - out_x(1,1) < smoothwin, 1, 'last');
    
trainaccu = zeros(length(blocklist),numsamples);
testaccu = zeros(length(blocklist),numsamples);
% WM = zeros(numsamples,numfeatures+1);
% WV = zeros(length(blocklist)-1,numfeatures+1);
% load(sprintf('%s_cspAllFilts.mat',char(basename)));
% load(sprintf('%s_cspExcludes.mat',char(basename)));
% excludes = x;
AllFilts = {};
for CVrun = 1:length(blocklist)
%     fprintf('\b\b%02d', CVrun);
    fprintf('Running %s-fold cross validation: fold %s\n',num2str(length(blocklist)),num2str(CVrun));
    traintrials = equalisetrials(P_C_S,setdiff(blocklist,blocklist(CVrun)));
    testtrials = equalisetrials(P_C_S,blocklist(CVrun));
    
    %% CSP
    
    clear T;
    Class1_nr=strmatch(class_names{1},P_C_S.AttributeName,'exact');
    Class2_nr=strmatch(class_names{2},P_C_S.AttributeName,'exact');
    T=cspwin;
    TrialExclude=[];
    %ChannelExclude=badchannels;
    ChannelExclude=[];
    FileName='';
    
%     fprintf('Calculating filters on training blocks...\n');
    P_C_S_ed = gBScuttrialschannels(P_C_S,testtrials,[]); % cut out the first half of trains and train on that
    
    CSP_O = gBScsp(P_C_S_ed,T,Class1_nr,Class2_nr,TrialExclude,ChannelExclude,FileName,0);
    
    %% Extract Weight-Matrix for CSPs
%     spf = struct(get(CSP_O.objects,'spf'));
%     W_CSP = real(spf.D.W);
  
%     fprintf('Scoring spatial filters.\n');
%     FileName = '';
%     FS = scorefilter(P_C_S,CSP_O,[],FileName); 
    
%     [~, FSix] = sort(FS,'ascend');
%     FilterNumbers = FSix([1 2 3 length(goodchannels)-2:length(goodchannels)]);
%     
% %     FilterNumbers = [1 2 3 length(goodchannels)-2:length(goodchannels)];
%    
% %     FilterNumbers = 1:length(goodchannels);
%     
%     spf = struct(get(CSP_O.objects,'spf'));
% 
%     %ROWS OF W_CSP ARE SPATIAL FILTERS
%     % W_CSP = real(spf.D.W);
%     %COLUMNS OF A_CSP ARE SPATIAL PATTERNS
%     A_CSP = real(spf.D.A);
%     
% %     montageinfo = load('GSN-HydroCel-65 1.0.mat');
%     montageinfo = load('64channelset.mat');
%     
%     chanlocs = montageinfo.chanlocs;
% %     screensize = get(0,'ScreenSize');
% %     figsize = [1280 1024];
%     
%     h = figure('Name',sprintf('Spatial Patterns'));
%     
%     for plotid = 1:length(FilterNumbers)
%         subplot(ceil(sqrt(length(FilterNumbers))),floor(sqrt(length(FilterNumbers))),plotid);
%         plotchans = zeros(1,length(chanlocs));
%         plotchans(chans2plot) = A_CSP(:,plotid);
%         topoplot(plotchans,chanlocs,'electrodes','off');
%         title(sprintf('%d',FilterNumbers(plotid)));
%         
%     end
%     filepath = 'Figures\';
%     figurefilename = [filepath char(basename) '_testCSPs64' num2str(CVrun) '.eps'];
%     exportfig(h,figurefilename, 'color', 'rgb');
    
% %     
    num2use = 3;
    [rhout, toout] = cspdistance(CSP_O, goodchannels, num2use, CVrun, basename); 
%     [rhout, toout] = cspdistance_fs(CSP_O, goodchannels, num2use, FS, CVrun, basename);
% %     [rhout, toout] = cspdistance_max(CSP_O, goodchannels, num2use);
% %     [rhout, toout] = cspdistance_max_fs(CSP_O, goodchannels, num2use, FS);
%         FilterNumbers = setdiff(AllFilts{CVrun},excludes{CVrun});
%     FilterNumbers = cspdistance_eig(CSP_O, goodchannels, num2use);

% 
%     num2classify = 2;
% 
%     if num2classify == 1        
%         [~, RHfilt] = min(FS(rhout));
%         [~, TOfilt] = max(FS(toout));
%         FilterNumbers = [rhout(RHfilt) toout(TOfilt)];    
%     else    
%         [~, rhsort] = sort(FS(rhout),'ascend');
%         [~, tosort] = sort(FS(toout),'descend');        
%         FilterNumbers = [rhout(rhsort(1:num2classify)) toout(tosort(1:num2classify))];
%     end

%     fprintf('Chosen filters for fold %s: %s(%s)\n',num2str(CVrun),num2str(FilterNumbers),num2str(FS(FilterNumbers)));
%     AllFilts{CVrun} = FilterNumbers;
    
    FilterNumbers = unique([rhout toout]);
    AllFilts{CVrun} = FilterNumbers;
    fprintf('Chosen filters for fold %s: %s\n',num2str(CVrun),num2str(FilterNumbers));
%     close all;
    %% Spatial Filter
    
%     fprintf('Applying spatial filters to all trials:');
%     fprintf(' %d',FilterNumbers);
%     fprintf('\n');
    SpatialFilter = get(CSP_O,'objects');
    Replace='replace all channels';
    Transformation='Create temporal pattern';
    
    P_C_S_CSP=gBSspatialfilter(P_C_S,SpatialFilter,FilterNumbers,Replace,Transformation);
    
    %% Variance
%     fprintf('Calculating filter variance.\n');
    ChannelExclude = [];
    IntervalLength = 128;
    GrowingWindow = 1;
    Overlap = IntervalLength-1;
    Replace = 'replace all channels';
    FileName = '';
    ProgressBarFlag = 0;
    P_C_S_CSP = gBSvariance(P_C_S_CSP, ChannelExclude, IntervalLength, GrowingWindow,...
        Overlap, Replace, FileName, ProgressBarFlag);
    
    
    %% Log Transform
%     fprintf('Calculating log transform of channels.\n');
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
    P_C_S_CSP = gBSarithmetic(P_C_S_CSP, ApplyOn, ChannelExclude_mult,...
        TrialExclude_mult, Operation_mult, SecondOperand_mult,...
        Unit_mult, FirstOperand_two, Operation_two,...
        SecondOperand_two, ProgressBarFlag);
    
    %% Subtraction of baseline log power
%     y = P_C_S_CSP.Data;
%     subwin = [-1 0];
%     % subwin = [0.1 2];
%     fprintf('Removing baseline variance within %.1f-%.1fs.\n',subwin(1),subwin(2));
%     subwin = (subwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
%     for t = 1:size(y,1)
%         for c = 1:size(y,3)
%             y(t,:,c) = y(t,:,c) ./ mean(y(t,subwin(1):subwin(2),c),2);
%         end
%     end
%     P_C_S_CSP.Data = y;
    
    %% Feature Matrix
    fprintf('Calculating feature matrix.\n');
%     targetwin = [1 3.5]; %time window relative to stimulus onset within which to identify best classifier accuracy
%     targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
%     Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];
    ChannelExclude=[];
    Permutate=0;
    FileName='FM_O.mat';
    ProgressBarFlag = 0;
    warning('off','MATLAB:fileparts:VersionToBeRemoved'); %turn off annoying fileparts error
    FM_O = gBSfeaturematrix(P_C_S_CSP,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);
    
    
    %% Train/test classifer
%     targetwin = [1 3.5]; %time window relative to stimulus onset within which to identify best classifier accuracy
%     fprintf('Applying target window of %.1f-%.1fs.\n', targetwin(1), targetwin(2));
    
    % TrainTestMethod = 'CV';
    %TrainTestMethod = '100:0';
%     smoothwin = 0.1;
%     smoothwin = smoothwin .* P_C_S.SamplingFrequency;
%     out_x = Interval(1):Interval(2):Interval(3);
%     smoothwin = find(out_x(1,:) - out_x(1,1) < smoothwin, 1, 'last');
% 
%     
    features = FM_O.Features;
    
    classlabels = FM_O.ClassLabels;
    classlabels = classlabels(1,:);
    
%     numsamples = size(features,1);
%     numfeatures = size(features{1},1);
        
%     trainaccu = zeros(1,numsamples);
%     testaccu = zeros(1,numsamples);
%     WM = zeros(1,numsamples,numfeatures+1);
%     WV = zeros(1,numfeatures+1);
    % SM = cell(1,numsamples);
    % SV = cell(length(runs)-1);
    bestwvidx = zeros(1,1);
    
    
%     fprintf('Testing with trained filters...\n');
    trainlabels = classlabels(traintrials)';
    testlabels = classlabels(testtrials)';
    testlabels = testlabels(randperm(length(testlabels)));
    WM = zeros(numsamples,length(FilterNumbers)+1);
    %% train and test classifier
    for t = 1:numsamples
        trainfeatures = features{t};
        %         trainfeatures = squeeze(features(:,t,:));
        trainfeatures = trainfeatures(:,traintrials)';
        
        b = glmfit(trainfeatures,trainlabels,'binomial');
        WM(t,:) = b;
        
        trainres = round(glmval(b,trainfeatures,'logit'));

        trainaccu(CVrun,t) = (sum(~xor(trainres == 1, trainlabels == 1))/length(trainlabels)) * 100;        
                
    end
    
    %smoothing window average
    smooth_accu = zeros(size(trainaccu(CVrun,:)));
    for t = 1:numsamples
        swstart = max(1,t-floor(smoothwin/2));
        swstop = min(t+floor(smoothwin/2),size(trainaccu,2));
        smooth_accu(1,t) = mean(trainaccu(CVrun,swstart:swstop),2);
    end
    trainaccu(CVrun,:) = smooth_accu;
    
    [~, bestidx] = max(trainaccu(CVrun,targetwinidx),[],2);
    bestwvidx(CVrun,1) = targetwinidx(bestidx);
    WV = squeeze(WM(bestwvidx(CVrun,1),:))';
    
    for t = 1:numsamples
        
        testfeatures = features{t};
        %         testfeatures = squeeze(features(:,t,:));
        testfeatures = testfeatures(:,testtrials)';
        testres = round(glmval(WV,testfeatures,'logit'));
        
        testaccu(CVrun,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
    end
   
    
    smooth_accu = zeros(size(testaccu(CVrun,:)));
        for t = 1:numsamples
            swstart = max(1,t-floor(smoothwin/2));
            swstop = min(t+floor(smoothwin/2),size(testaccu,2));
            smooth_accu(1,t) = mean(testaccu(CVrun,swstart:swstop),2);
        end
    testaccu(CVrun,:) = smooth_accu;

    
end
fprintf('\n');

overall_accu = mean(testaccu,1);
% save(sprintf('%s_cspicatt.mat',char(basename)),'overall_accu','testaccu','AllFilts');



% targetwinidx = find(targetwin(1) <= out_x(:),1,'first'):find(targetwin(2) <= out_x(:),1,'first');
[bestaccu bestidx] = max(overall_accu(1,targetwinidx),[],2);
fprintf('\n%s: Best accuracy = %.1f at time %.1fs.\n\n', ...
    P_C_S.SubjectID, bestaccu, (out_x(1,targetwinidx(bestidx))*(1000/P_C_S.SamplingFrequency))/1000 - (P_C_S.PreTrigger/P_C_S.SamplingFrequency));

fprintf('Iteration %s done\n',num2str(bi));
bs_accs(bi) = bestaccu;
save('boot_outs.mat','bs_accs');

end


% %% Plot Figure
% fprintf('Plotting classifier performance.\n');
% ylim = [50 100];
% scrsize = get(0,'ScreenSize');
% fsize = [1000 660];
% figure('Name',P_C_S.SubjectID,'NumberTitle','off');
% x=(out_x(1,:) - P_C_S.PreTrigger) * (1/P_C_S.SamplingFrequency);
% y=overall_accu;
% a=axes;
% 
% plot(x,y,'Parent',a,'Marker','.','LineWidth',3);
% set(a,'YLim',ylim);
% set(a,'XLim',[x(1) x(end)]);
% 
% line([0 0],[0 ylim(2)],'Color','black');
% ylabel('Accuracy (%)');
% xlabel('Time (s)');
% title(sprintf('Single-trial classification accuracy for %s', P_C_S.SubjectID), 'Interpreter', 'none');
% grid on
% 
% maximumX=max(get(a,'XLim'));
% minimumX=min(get(a,'XLim'));
% line([minimumX maximumX],[90 90],'Color','green');
% line([minimumX maximumX],[70 70],'Color','yellow');
% text(maximumX+0.2,91,'EXCELLENT','Rotation',90);
% text(maximumX+0.2,78,'GOOD','Rotation',90);
% text(maximumX+0.2,55,'MORE TRAINING','Rotation',90);
