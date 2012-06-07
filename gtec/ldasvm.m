function [bestaccu sig] = ldasvm(basename,trainortest,trainname)
filepath = 'D:\Data\Imagery\';

savefile = [filepath basename '_filtered.mat'];

% if exist(savefile,'file')
%     fprintf('Loading pre-filtered data...\n');
%     load(savefile);
%     win = [0.5 3];
%     tps = [50 P_C_S.SamplingFrequency + round(P_C_S.SamplingFrequency/2)];
%     P_C_S = fuckitall(P_C_S, win, tps);    
%     bestaccu = svmlda_b_all_boot(P_C_S);
%     return;
% end


datafile = [filepath basename '.mat'];
fprintf('\n');

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);
fprintf('Found %d trials, %d samples, %d channels.\n', length(P_C_S.TrialNumber), P_C_S.PreTrigger+P_C_S.PostTrigger, length(P_C_S.Channels));

%% downsample data
newRate = 125;
fprintf('Downsampling data to %sHz...\n',num2str(newRate));
%P_C_S = gBSdownupsampling(P_C_S,newRate,0);
data = P_C_S.Data;
dsdata = zeros(size(data,1),round(size(data,2)/2),size(data,3));
for t = 1:size(data,1)
    for c = 1:size(data,3)
        dsdata(t,:,c) = downsample(data(t,:,c),2);
    end
end
P_C_S.Data = dsdata;
P_C_S.SamplingFrequency = newRate;
eventlatency = 1500;
P_C_S.PreTrigger = eventlatency * (P_C_S.SamplingFrequency/1000);
P_C_S.PostTrigger = size(P_C_S.Data, 2) - P_C_S.PreTrigger;

%% Cut out all channels except the ones required
if length(P_C_S.Channels) == 129
    origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
% origchan = [6    7   13   20   28   29   30   31   34   35   36   37   40   41   42   46   47   52   53   54   55   79   80   86   87   92   93   98  102  103  104  105  106  109  110  111  112  116  117  118 129];

%         origchan = [36 129 104];
%         origchan = [36 29 30 37 42 41 35 129 7 106 80 55 31 104 103 105 110 111 87 93];
    %origchan = [129 7 106 80 55 31 36 35 29 30 37 42 41];
    %origchan = [40 37];
    %origchan = [42 37 53 87 93 86 5];
%     origchan = [36 129];
    %     C3 = 36;
    %     C4 = 104;
    %     Cz = 129;
    %     C3 = 40;
    %     %C4 = 93;
    %     Cz = 37;
    % % C3 = 64;
    % % Cz = 9;
elseif length(P_C_S.Channels) == 257
    %channel list with only 25 electrodes
    origchan = [8    9   17   43   44   45   52   53   58   65   66   80   81  131  132  144  164  182  184  185  186  195  197  198  257];
    %origchan = [8    9   17   43   44   45   51   52   53   58   59   60   64   65   66   71   72   78   79   80   81   89   90  130  131  132  143  144  154  155  164  173  181  182  183  184  185  186  194  195  196  197  198  257];
    %origchan = [8    9   17   42   43   44   45   50   51   52   53   57   58   59   60   64   65   66   71   72   78   79   80   81   90  131  132  144  185  186  198  257];
    %     C3 = 59;
    %     C4 = 183;
    %     Cz = 257;
    
elseif length(P_C_S.Channels) == 64
    origchan = [20 19 15 16 21 23 24 4 55 30 53 54 59 58 52 48 45 3 29 41 26 50 22 57];

end

%origchan = [C3 C4 Cz];
% origchan = [C3 Cz];
% origchan = [20 53];

% origchan = 1:64;
% % skipchan = [];
% skipchan = [1,5,6,8,9,11,12,13,17,31,32,33,35,36,37,38,39,40,42,43,44,46,49,63,64];
% origchan = setdiff(origchan,skipchan);

%% Pick out any bad channels
if strcmp(trainortest,'test') || strcmp(trainortest,'apply') || ...
        strcmp(trainortest,'boottest') || strcmp(trainortest,'logtest')
    load(sprintf('%s_bc.mat',trainname));
else
    [badtrials, badchannels] = findbadtrialschannels(P_C_S);
    save(sprintf('%s_bc.mat', P_C_S.SubjectID), 'origchan', 'badchannels');
end

fprintf('Rejecting %d bad channels: %s.\n', length(intersect(origchan,badchannels)), num2str(intersect(origchan,badchannels)));
TrialExclude=badtrials;
ChannelExclude = setdiff(origchan,badchannels);
ChannelExclude = setdiff(1:P_C_S.NumberChannels,ChannelExclude);
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
origchan = P_C_S.Channels;

%% Filter
% 
% clear Filter  % me
% Filter.Realization='butter';
% Filter.Type='BP';
% Filter.Order=5;
% Filter.f_low=7;
% Filter.f_high=30;
% TrialExclude=[];
% % ChannelExclude=badchannels;
% ChannelExclude=[];
% fprintf('Filtering between %d-%dHz.\n', Filter.f_low, Filter.f_high);
% P_C_S=gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);

% %% Hilbert
% fprintf('Calculating Hilbert transform...\n');
% y = P_C_S.Data;
% 
% for trial = 1:size(y,1)
%     for chan = 1:size(y,3)
%         
%         yhilba(trial,:,chan) = abs(hilbert(y(trial,:,chan)));
%         
%     end
% end

%% Filter
% clear Filter  % me
% Filter.Realization='butter';
% Filter.Type='BP';
% Filter.Order=5;
% Filter.f_low=13;
% Filter.f_high=19;
% TrialExclude=[];
% % ChannelExclude=badchannels;
% ChannelExclude=[];
% fprintf('Filtering between %d-%dHz.\n', Filter.f_low, Filter.f_high);
% P_C_S=gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);
% 
% %% Hilbert
% fprintf('Calculating Hilbert transform...\n');
% y = P_C_S.Data;
% 
% for trial = 1:size(y,1)
%     for chan = 1:size(y,3)
%         
%         yhilbb(trial,:,chan) = abs(hilbert(y(trial,:,chan)));
%         
%     end
% end
% 
% %% Filter
% clear Filter  % me
% Filter.Realization='butter';
% Filter.Type='BP';
% Filter.Order=5;
% Filter.f_low=19;
% Filter.f_high=24;
% TrialExclude=[];
% % ChannelExclude=badchannels;
% ChannelExclude=[];
% fprintf('Filtering between %d-%dHz.\n', Filter.f_low, Filter.f_high);
% P_C_S=gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);
% 
% %% Hilbert
% fprintf('Calculating Hilbert transform...\n');
% y = P_C_S.Data;
% 
% for trial = 1:size(y,1)
%     for chan = 1:size(y,3)
%         
%         yhilbc(trial,:,chan) = abs(hilbert(y(trial,:,chan)));
%         
%     end
% end
% 
% %% Filter
% clear Filter  % me
% Filter.Realization='butter';
% Filter.Type='BP';
% Filter.Order=5;
% Filter.f_low=24;
% Filter.f_high=30;
% TrialExclude=[];
% % ChannelExclude=badchannels;
% ChannelExclude=[];
% fprintf('Filtering between %d-%dHz.\n', Filter.f_low, Filter.f_high);
% P_C_S=gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);
% 
% %% Hilbert
% fprintf('Calculating Hilbert transform...\n');
% y = P_C_S.Data;
% 
% for trial = 1:size(y,1)
%     for chan = 1:size(y,3)
%         
%         yhilbd(trial,:,chan) = abs(hilbert(y(trial,:,chan)));
%         
%     end
% end
% 
% P_C_S.Data = cat(3,yhilba,yhilbb,yhilbc,yhilbd);
% P_C_S.Data = yhilba;

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

%% Bandpower in frequency bands  

f_low = 7;
f_step = 6;
f_high = 30;
winlen = P_C_S.SamplingFrequency;
overlap = winlen - 1;
freqrange = f_low:f_step:f_high;
if freqrange(end) < f_high
    freqrange = [freqrange f_high];
end
fprintf('Calculating bandpower in frequency bands between %d:%d:%dHz\n',f_low,f_step,f_high);
P_C_S = bandpower(P_C_S,winlen,overlap,freqrange);
% P_C_S = bandpower_olap(P_C_S,winlen,overlap,f_low,f_step,f_high);

%% guger-style power
% P_C_S = gugerpower(P_C_S);
%
save(savefile,'P_C_S');

P_C_S = fuckupdata(P_C_S);
% % P_C_S = mergetimes(P_C_S);
% 
savefile = [filepath basename '_fuckedup.mat'];
% 
save(savefile,'P_C_S');

% ChannelExclude = []; 
% Method = 'RLS'; 
% Order = 6; 
% % UC(1) = [0.006]; 
% % UC(2) = [0.006]; 
% UC(1:length(origchan)) = 0.006;
% Replace = 'replace all channels'; 
% FileName = ''; 
% ProgressBarFlag = 1; 
% P_C_S = gBSaar(P_C_S, ChannelExclude, Method, Order, UC, Replace, FileName, ProgressBarFlag);
% for f = f_low:f_step:f_high
%     f_start = f;
%     f_stop = min(f_start+f_step,f_high);
%     fprintf('\b\b\b\b\b%02d-%02d',f_start,f_stop);
%     ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
%     Filter.Name = sprintf('%s-%s',f_start,f_stop);
%     Filter.Type = 'BP';
%     Filter.f_low = f_start;
%     Filter.f_high = f_stop;
%     Filter.Realization = 'butter';
%     Filter.Order = 4;
%     IntervalLength = P_C_S.SamplingFrequency;
%     Overlap = IntervalLength/2;
%     Replace = 'replace all channels';
%     FileName = '';
%     ProgressBarFlag = 0;
%     P_C_S_bp = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
%         Overlap, Replace, FileName, ProgressBarFlag);
% end
% fprintf('\n');

% % Bandpower in alpha range
% % targetwin = [0.1 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
% % targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
% % 
% % [f0 f1] = selectfreq(P_C_S, targetwin);
% % ChannelExclude = [];
% % Filter.Name = 'ALPHA_BCI';
% % Filter.Type = 'BP';
% % Filter.f_low = f0;
% % Filter.f_high = f1;
% % Filter.Realization = 'butter';
% % Filter.Order = 4;
% % IntervalLength = P_C_S.SamplingFrequency;
% % Overlap = IntervalLength-1;
% % Replace = 'add channels';
% % FileName = '';
% % ProgressBarFlag = 0;
% % fprintf('Calculating bandpower in alpha band: %d-%dHz.\n',Filter.f_low,Filter.f_high);
% % P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
% %     Overlap, Replace, FileName, ProgressBarFlag);
% % % 
% % % % Bandpower in beta range
% % ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
% % Filter.Name = 'BETA_BCI';
% % Filter.Type = 'BP';
% % Filter.f_low = 13;
% % Filter.f_high = 30;
% % Filter.Realization = 'butter';
% % Filter.Order = 4;
% % IntervalLength = P_C_S.SamplingFrequency;
% % Overlap = IntervalLength-1;
% % Replace = 'add channels';
% % FileName = '';
% % ProgressBarFlag = 0;
% % fprintf('Calculating bandpower in beta band: %d-%dHz.\n',Filter.f_low,Filter.f_high);
% % P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
% %     Overlap, Replace, FileName, ProgressBarFlag);

% % %% Bandpower in low beta range
% ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
% Filter.Name = 'LOW_BETA_BCI';
% Filter.Type = 'BP';
% Filter.f_low = 13;
% Filter.f_high = 19;
% Filter.Realization = 'butter';
% Filter.Order = 4;
% IntervalLength = P_C_S.SamplingFrequency;
% Overlap = P_C_S.SamplingFrequency-1;
% Replace = 'add channels';
% FileName = '';
% ProgressBarFlag = 0;
% fprintf('Calculating bandpower in low beta band: %d-%dHz.\n',Filter.f_low,Filter.f_high);
% P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
%     Overlap, Replace, FileName, ProgressBarFlag);
% % 
% % %%  Bandpower in mid beta range
% ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
% Filter.Name = 'MID_BETA_BCI';
% Filter.Type = 'BP';
% Filter.f_low = 19;
% Filter.f_high = 24;
% Filter.Realization = 'butter';
% Filter.Order = 4;
% IntervalLength = P_C_S.SamplingFrequency;
% Overlap = P_C_S.SamplingFrequency-1;
% Replace = 'add channels';
% FileName = '';
% ProgressBarFlag = 0;
% fprintf('Calculating bandpower in mid beta band: %d-%dHz.\n',Filter.f_low,Filter.f_high);
% P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
%     Overlap, Replace, FileName, ProgressBarFlag);
% % % 
% % %%  Bandpower in high beta range
% ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
% Filter.Name = 'HIGH_BETA_BCI';
% Filter.Type = 'BP';
% Filter.f_low = 24;
% Filter.f_high = 30;
% Filter.Realization = 'butter';
% Filter.Order = 4;
% IntervalLength = P_C_S.SamplingFrequency;
% Overlap = P_C_S.SamplingFrequency-1;
% Replace = 'add channels';
% FileName = '';
% ProgressBarFlag = 0;
% fprintf('Calculating bandpower in high beta band: %d-%dHz.\n',Filter.f_low,Filter.f_high);
% P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
%     Overlap, Replace, FileName, ProgressBarFlag);
% 
% %% Keep only bandpower channels
% TrialExclude=[];
% ChannelExclude = origchan;
% P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

%% Train/test classifer
if strcmp(trainortest,'train')
    trainlda(P_C_S);
elseif strcmp(trainortest,'test')
    testlda(P_C_S,trainname);
elseif strcmp(trainortest,'trainandtest')
    trainandtestlda(P_C_S);
elseif strcmp(trainortest,'bootstrap')
    bootstraplda(P_C_S);
elseif strcmp(trainortest,'apply')
    applylda(P_C_S);
elseif strcmp(trainortest,'bino')
    binolda(P_C_S);
elseif strcmp(trainortest,'boottest')
    boottestlda(P_C_S,trainname);
elseif strcmp(trainortest,'stepwise')
    stepwiselda(P_C_S);
elseif strcmp(trainortest,'logistic')
    logisticlda(P_C_S);
elseif strcmp(trainortest,'logtest')
    logtestlda(P_C_S,trainname);
elseif strcmp(trainortest,'stepwiseb')
    stepwiselda_b(P_C_S);
elseif strcmp(trainortest,'svmb')
    [bestaccu sig] = svmlda_b(P_C_S);
elseif strcmp(trainortest,'svm')
    bestaccu = svmlda(P_C_S);
elseif strcmp(trainortest,'svmb_boot')
    boots = 200;
    bootaccs = zeros(1,boots);
    for bi = 1:boots
        
        bootaccs(bi) = svmlda_b_boot(P_C_S);
        close all;
    end
    
    save 'bootouts.mat' bootaccs;

end
