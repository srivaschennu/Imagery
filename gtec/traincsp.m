function FilterScores = traincsp(basename,FilterNumbers)

%FilterNumbers = [122,78,65,75,13,52,59,46;];
%FilterNumbers = [1 2 3 124 125 126];
filepath = 'd:\data\imagery\';
datafile = [filepath basename '.mat'];
class_names = {'RIGHTHAND';'TOES'};

%% Load Data
load(datafile);

%% Reduce to 1020 electrodes only
P_C_S = select1020(P_C_S);

%% Pick out any bad channels
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

%% CSP
clear T;
Class1_nr=strmatch(class_names{1},P_C_S.AttributeName,'exact');
Class2_nr=strmatch(class_names{2},P_C_S.AttributeName,'exact');
T=[1.5*P_C_S.SamplingFrequency-1 2.5*P_C_S.SamplingFrequency-1];
TrialExclude=[];
ChannelExclude=badchannels;
FileName='';
CSP_O = gBScsp(P_C_S,T,Class1_nr,Class2_nr,TrialExclude,ChannelExclude,FileName,0);
save CSP_O.mat CSP_O;

if ~exist('FilterNumbers','var') ||  isempty(FilterNumbers)
    FileName = 'FS.mat';
    FilterScores = scorefilter(P_C_S,CSP_O,badchannels,FileName);
    gResult2d(CreateResult2D(CSP_O));
    return;
else
    save FN.mat FilterNumbers;
end

%% cut out bad channels
TrialExclude=[];
ChannelExclude=badchannels;
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

%% Spatial Filter
SpatialFilter = get(CSP_O,'objects');
Replace='replace all channels';
Transformation='Create temporal pattern';
P_C_S=gBSspatialfilter(P_C_S,SpatialFilter,FilterNumbers,Replace,Transformation);

%% Extract Weight-Matrix for CSPs
spfs = get(SpatialFilter,'spf');
spf_struct = struct(spfs);
W_CSP = spf_struct.D.W;
save W_CSP.mat W_CSP;

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

trainlda(P_C_S);