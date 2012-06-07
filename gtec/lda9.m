function lda(basename,trainortest)

filepath = 'd:\data\imagery\';
montagepath = 'D:\EGI\';
datafile = [filepath basename '.mat'];
fprintf('\n');

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);

%% Cut out all channels except the ones required
if length(P_C_S.Channels) == 129
    origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
    %origchan = [129 7 106 80 55 31 36 35 29 30 37 42 41];
    %origchan = [40 37];
    %origchan = [42 37 53 87 93 86 5];
    %origchan = [36 129];
    %     C3 = 36;
    %     C4 = 104;
    %     Cz = 129;
    %     C3 = 40;
    %     %C4 = 93;
    %     Cz = 37;
    % % C3 = 64;
    % % Cz = 9;
elseif length(P_C_S.Channels) == 257
    origchan = [8    9   17   43   44   45   51   52   53   58   59   60   64   65   66   71   72   78   79   80   81   89   90  130  131  132  143  144  154  155  164  173  181  182  183  184  185  186  194  195  196  197  198  257];
    %origchan = [8    9   17   42   43   44   45   50   51   52   53   57   58   59   60   64   65   66   71   72   78   79   80   81   90  131  132  144  185  186  198  257];
    %     C3 = 59;
    %     C4 = 183;
    %     Cz = 257;
end

%origchan = [C3 C4 Cz];
% origchan = [C3 Cz];


%% Pick out any bad channels
if strcmp(trainortest,'test') || strcmp(trainortest,'apply')
    load BC.mat
else
    [~, badchannels] = findbadtrialschannels(P_C_S);
    save BC.mat origchan badchannels
end

fprintf('Rejecting bad channels: %s.\n', num2str(intersect(origchan,badchannels)));
TrialExclude=[];
ChannelExclude = setdiff(origchan,badchannels);
ChannelExclude = setdiff(1:P_C_S.NumberChannels,ChannelExclude);
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
origchan = P_C_S.Channels;

%% Bandpower in alpha range
ChannelExclude = [];
Filter.Name = 'ALPHA_BCI';
Filter.Type = 'BP';
Filter.f_low = 7;
Filter.f_high = 13;
Filter.Realization = 'butter';
Filter.Order = 4;
IntervalLength = P_C_S.SamplingFrequency;
Overlap = IntervalLength-1;
Replace = 'add channels';
FileName = '';
ProgressBarFlag = 0;
fprintf('Calculating bandpower in alpha band: %d-%dHz.\n',Filter.f_low,Filter.f_high);
P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
    Overlap, Replace, FileName, ProgressBarFlag);

%% Bandpower in beta range
ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
Filter.Name = 'BETA_BCI';
Filter.Type = 'BP';
Filter.f_low = 13;
Filter.f_high = 25;
Filter.Realization = 'butter';
Filter.Order = 4;
IntervalLength = P_C_S.SamplingFrequency;
Overlap = IntervalLength-1;
Replace = 'add channels';
FileName = '';
ProgressBarFlag = 0;
fprintf('Calculating bandpower in beta band: %d-%dHz.\n',Filter.f_low,Filter.f_high);
P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
    Overlap, Replace, FileName, ProgressBarFlag);

%
% %%  Bandpower in low beta range
% ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
% Filter.Name = 'LOW_BETA_BCI';
% Filter.Type = 'BP';
% Filter.f_low = 12;
% Filter.f_high = 16;
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
%
% %%  Bandpower in mid beta range
% ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
% Filter.Name = 'MID_BETA_BCI';
% Filter.Type = 'BP';
% Filter.f_low = 16;
% Filter.f_high = 20;
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

% %%  Bandpower in high beta range
% ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
% Filter.Name = 'HIGH_BETA_BCI';
% Filter.Type = 'BP';
% Filter.f_low = 6;
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

%% Keep only bandpower channels
TrialExclude=[];
ChannelExclude = origchan;
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

%% Train/test classifer
if strcmp(trainortest,'train')
    trainlda15(P_C_S);
elseif strcmp(trainortest,'test')
    testlda(P_C_S);
elseif strcmp(trainortest,'trainandtest')
    trainandtestlda(P_C_S);
elseif strcmp(trainortest,'bootstrap')
    bootstraplda(P_C_S);
elseif strcmp(trainortest,'apply')
    applylda(P_C_S);
elseif strcmp(trainortest,'logistic')
    logisticlda(P_C_S);
end
