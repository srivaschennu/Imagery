function aarlda(basename,trainortest,trainname)

loadpaths

datafile = [filepath basename '.mat'];
fprintf('\n');

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);
fprintf('Found %d trials, %d samples, %d channels.\n', length(P_C_S.TrialNumber), P_C_S.PreTrigger+P_C_S.PostTrigger, length(P_C_S.Channels));

%% downsample data
P_C_S = gBSdownupsampling(P_C_S,80,0);
eventlatency = 1500;
P_C_S.PreTrigger = eventlatency * (P_C_S.SamplingFrequency/1000);
P_C_S.PostTrigger = size(P_C_S.Data, 2) - P_C_S.PreTrigger;

%% Cut out all channels except the ones required
if length(P_C_S.Channels) == 129
    origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
%     origchan = [36 29 30 37 42 41 35 129 7 106 80 55 31];
    %origchan = [129 7 106 80 55 31 36 35 29 30 37 42 41];
    %origchan = [40 37];
    %origchan = [42 37 53 87 93 86 5];
%     origchan = [36 129];
        C3 = 36;
        C4 = 104;
        Cz = 129;
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
end

origchan = [C3 C4 Cz];
% origchan = [C3 Cz];


%% Pick out any bad channels
if strcmp(trainortest,'test') || strcmp(trainortest,'apply') || ...
        strcmp(trainortest,'boottest') || strcmp(trainortest,'logtest')
    load(sprintf('%s_bc.mat',trainname));
else
    [~, badchannels] = findbadtrialschannels(P_C_S);
    save(sprintf('%s_bc.mat', P_C_S.SubjectID), 'origchan', 'badchannels');
end

fprintf('Rejecting %d bad channels: %s.\n', length(intersect(origchan,badchannels)), num2str(intersect(origchan,badchannels)));
TrialExclude=[];
ChannelExclude = setdiff(origchan,badchannels);
ChannelExclude = setdiff(1:P_C_S.NumberChannels,ChannelExclude);
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
origchan = P_C_S.Channels;

%% Calculate AAR parameters

ChannelExclude = [];
Method = 'LMS2';
Order = 6;
UC = repmat(0.006,1,length(P_C_S.Channels));
Replace = 'replace all channels';
FileName = '';
ProgressBarFlag = 1;
fprintf('Calculating AAR parameters.\n');
P_C_S = gBSaar(P_C_S, ChannelExclude, Method, Order, UC, Replace, FileName, ProgressBarFlag);

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
end
