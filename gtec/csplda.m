function csplda(basename,trainortest,FilterNumbers)

filepath = 'D:\Data\Imagery\';
datafile = [filepath basename '.mat'];
class_names = {'RIGHTHAND';'TOES'};

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);

%% Pick out any bad channels
if strcmp(trainortest,'test')
    load(sprintf('%s_bc.mat',trainname));
else
    [~, badchannels] = findbadtrialschannels(P_C_S);
    save(sprintf('%s_bc.mat', P_C_S.SubjectID),'badchannels');
end

%origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
%origchan = [4    5    6    7   11   12   13   19   20   24   27   28   29   30   31   34   35   36   37   40   41   42   46   47   51   52   53   54   55   60   61   62   78   79   80   85   86   87   92   93   97   98  102  103  104  105  106  109  110  111  112  116  117  118  123  124  129];
origchan = [6    7   13   20   28   29   30   31   34   35   36   37   40   41   42   46   47   52   53   54   55   79   80   86   87   92   93   98  102  103  104  105  106  109  110  111  112  116  117  118];
fprintf('Rejecting %d bad channels: %s.\n', length(intersect(origchan,badchannels)), num2str(intersect(origchan,badchannels)));
TrialExclude=[];
goodchannels = setdiff(origchan,badchannels);
ChannelExclude = setdiff(1:P_C_S.NumberChannels,goodchannels);
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

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
Filter.f_low=7;
Filter.f_high=30;
TrialExclude=[];
% ChannelExclude=badchannels;
ChannelExclude=[];
fprintf('Filtering between %d-%dHz.\n', Filter.f_low, Filter.f_high);
P_C_S=gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);

%% CSP
cspwin = [0.1 2];
cspwin = (cspwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;

if strcmp(trainortest,'test')
    load(sprintf('%s_csp.mat',P_C_S.SubjectID),'CSP_O');
    load(sprintf('%s_fn.mat',P_C_S.SubjectID),'FilterNumbers');
elseif ~exist('FilterNumbers','var')
    fprintf('Calculating spatial filters.\n');
    clear T;
    Class1_nr=strmatch(class_names{1},P_C_S.AttributeName,'exact');
    Class2_nr=strmatch(class_names{2},P_C_S.AttributeName,'exact');
    T=cspwin;
    TrialExclude=[];
    %ChannelExclude=badchannels;
    ChannelExclude=[];
    FileName='';
    CSP_O = gBScsp(P_C_S,T,Class1_nr,Class2_nr,TrialExclude,ChannelExclude,FileName,0);
    
    %% Extract Weight-Matrix for CSPs
    spf = struct(get(CSP_O.objects,'spf'));
    W_CSP = real(spf.D.W);
    fprintf('Scoring spatial filters.\n');
    FileName = '';
    %FS = scorefilter(P_C_S,CSP_O,badchannels,FileName);
    FS = scorefilter(P_C_S,CSP_O,[],FileName);
    
    save(sprintf('%s_csp.mat',P_C_S.SubjectID),'origchan','CSP_O','W_CSP','FS');
    [~, sortidx] = sort(FS);
    
    if strcmp(trainortest,'train')
        FilterNumbers = [sortidx(1) sortidx(2) sortidx(end-1) sortidx(end)];
        save(sprintf('%s_fn.mat',P_C_S.SubjectID),'FilterNumbers');
    else
        plotcspmap(CSP_O,FS,goodchannels,0);
        return;
    end
elseif exist('FilterNumbers','var')
    load(sprintf('%s_csp.mat',P_C_S.SubjectID),'CSP_O','FS');
end

%% Spatial Filter
fprintf('Applying spatial filters:');
fprintf(' %d(%.2f)',cat(1,FilterNumbers,FS(FilterNumbers)'));
fprintf('\n');
SpatialFilter = get(CSP_O,'objects');
Replace='replace all channels';
Transformation='Create temporal pattern';
P_C_S=gBSspatialfilter(P_C_S,SpatialFilter,FilterNumbers,Replace,Transformation);

%% Variance
fprintf('Calculating filter variance.\n');
ChannelExclude = [];
IntervalLength = 128;
GrowingWindow = 1;
Overlap = IntervalLength-1;
Replace = 'replace all channels';
FileName = '';
ProgressBarFlag = 0;
P_C_S = gBSvariance(P_C_S, ChannelExclude, IntervalLength, GrowingWindow,...
    Overlap, Replace, FileName, ProgressBarFlag);

%% Train/test classifer
if strcmp(trainortest,'train')
    trainlda(P_C_S);
elseif strcmp(trainortest,'test')
    testlda(P_C_S);
elseif strcmp(trainortest,'trainandtest')
    trainandtest(P_C_S);
end