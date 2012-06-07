function class = test(basename)

filepath = 'd:\data\imagery\';
datafile = [filepath basename '.mat'];

%% Load Data
load(datafile);

%% convert data to local average reference
P_C_S = changeref(P_C_S);

%% Cut out all channels except the ones required
%if length(P_C_S.Channels) == 129
%     C3 = 36;
%     C4 = 104;
%     Cz = 129;
    C3 = 41;
    C4 = 93;
    Cz = 37;
% elseif length(P_C_S.Channels) == 257
%     C3 = 59;
%     C4 = 183;
%     Cz = 257;
%     y = y([C3,C4,Cz,end],:);
%     C3 = 1;
%     C4 = 2;
%     Cz = 3;
% end
origchan = [C3 C4 Cz];

TrialExclude=[];
ChannelExclude = setdiff(1:P_C_S.NumberChannels,[origchan P_C_S.NumberChannels]);
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
origchan = P_C_S.Channels;

%%  Bandpower in alpha range
ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
Filter.Name = 'ALPHA_BCI';
Filter.Type = 'BP';
Filter.f_low = 6;
Filter.f_high = 12;
Filter.Realization = 'butter';
Filter.Order = 4;
IntervalLength = P_C_S.SamplingFrequency;
Overlap = P_C_S.SamplingFrequency-1;
Replace = 'add channels';
FileName = '';
ProgressBarFlag = 0;
P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
    Overlap, Replace, FileName, ProgressBarFlag);

%%  Bandpower in beta range
ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
Filter.Name = 'BETA_BCI';
Filter.Type = 'BP';
Filter.f_low = 12;
Filter.f_high = 30;
Filter.Realization = 'butter';
Filter.Order = 4;
IntervalLength = P_C_S.SamplingFrequency;
Overlap = P_C_S.SamplingFrequency-1;
Replace = 'add channels';
FileName = '';
ProgressBarFlag = 0;
P_C_S = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
    Overlap, Replace, FileName, ProgressBarFlag);

%% Keep only bandpower channels 
TrialExclude=[];
ChannelExclude = origchan;
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

%% Test classifier
class = testlda(P_C_S);