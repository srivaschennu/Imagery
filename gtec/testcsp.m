function class = testcsp(basename,FilterNumbers)

filepath = 'd:\data\imagery\';
datafile = [filepath basename '.mat'];
class_names = {'RIGHTHAND';'TOES'};

%% Load Data
load(datafile);

%% convert data to local average reference
P_C_S = changeref(P_C_S);

%% Reduce to 1020 electrodes only
P_C_S = select1020(P_C_S);

%% Find bad channels
badchannels = P_C_S.ChannelAttribute;
badchannels = find(badchannels(1,:) == 1);

%% Filter
clear Filter  % me
Filter.Realization='butter';
Filter.Type='BP';
Filter.Order=5;
Filter.f_high=30;
Filter.f_low=6;
TrialExclude=[];
ChannelExclude=badchannels;
P_C_S=gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);

%% cut out bad channels
TrialExclude=[];
ChannelExclude=badchannels;
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

%% Spatial Filter
load('CSP_O.mat');
SpatialFilter = get(CSP_O,'objects');
load('FN.mat');
Replace='replace all channels';
Transformation='Create temporal pattern';
P_C_S=gBSspatialfilter(P_C_S,SpatialFilter,FilterNumbers,Replace,Transformation);

%% Variance
ChannelExclude = [];
IntervalLength = 128;
GrowingWindow = 1;
Overlap = IntervalLength-1;
Replace = 'replace all channels';
FileName = '';
ProgressBarFlag = 0;
P_C_S = gBSvariance(P_C_S, ChannelExclude, IntervalLength, GrowingWindow,...
    Overlap, Replace, FileName, ProgressBarFlag);

%% Test classifier
class = testlda(P_C_S);