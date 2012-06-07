function lda(basename,trainortest,trainname)

loadpaths
disablewarnings

datafile = [filepath basename '.mat'];
fprintf('\n');

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);
fprintf('Found %d trials, %d samples, %d channels.\n', length(P_C_S.TrialNumber), P_C_S.PreTrigger+P_C_S.PostTrigger, length(P_C_S.Channels));

%% downsample data
% P_C_S = gBSdownupsampling(P_C_S,P_C_S.SamplingFrequency/2,0);
% eventlatency = 1500;
% P_C_S.PreTrigger = eventlatency * (P_C_S.SamplingFrequency/1000);
% P_C_S.PostTrigger = size(P_C_S.Data, 2) - P_C_S.PreTrigger;

%% Cut out all channels except the ones required
if length(P_C_S.Channels) == 129
%     origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
%     origchan = [36 104 129];
%         origchan = [36 29 30 37 42 41 35 129 7 106 80 55 31];
    %origchan = [129 7 106 80 55 31 36 35 29 30 37 42 41];
    %origchan = [40 37];
    %origchan = [42 37 53 87 93 86 5];
    origchan = [36 129];
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
end

%origchan = [C3 C4 Cz];
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

%% Bandpower in frequency bands
% f_low = 7;
% f_step = 2;
% f_high = 30;
% fprintf('Calculating bandpower in frequency bands between %d:%d:%dHz\n',f_low,f_step,f_high);
% P_C_S = bandpower(P_C_S,P_C_S.SamplingFrequency,225,f_low:f_step:f_high);

% fprintf('Calculating bandpower in frequency bands between %d:%d:%dHz:      ',f_low,f_step,f_high);
% for f = f_low:f_step:f_high-f_step
%     f_start = f;
%     f_stop = f+f_step;
%     fprintf('\b\b\b\b\b%02d-%02d',f_start,f_stop);
%     %ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
%     ChannelExclude = [];
%     Filter.Name = sprintf('%s-%s',f_start,f_stop);
%     Filter.Type = 'BP';
%     Filter.f_low = f_start;
%     Filter.f_high = f_stop;
%     Filter.Realization = 'butter';
%     Filter.Order = 4;
%     IntervalLength = P_C_S.SamplingFrequency;
%     Overlap = IntervalLength-25;
%     Replace = 'replace all channels';
%     FileName = [pwd '\' 'temp.mat'];
%     ProgressBarFlag = 0;
%     P_C_S_band = gBSbandpower(P_C_S, ChannelExclude, Filter, IntervalLength,...
%         Overlap, Replace, FileName, ProgressBarFlag);
%     
%     if exist('P_C_S_bp','var')
%         Concatenate='Channels';    %merge over samples
%         AdoptChAttr=1;			%merge channel attributes
%         AdoptTrialAttr=1;			%merge trial attributes
%         AdoptMarkers=1;			%merge markers
%         P_C_S_bp = gBSmerge(P_C_S_bp,{FileName},Concatenate,AdoptChAttr,AdoptTrialAttr,AdoptMarkers);
%     else
%         P_C_S_bp = P_C_S_band;
%     end
% end
% P_C_S = P_C_S_bp;
% fprintf('\n');

% Bandpower in alpha range
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

% Bandpower in beta range
ChannelExclude = setdiff(1:P_C_S.NumberChannels,origchan);
Filter.Name = 'BETA_BCI';
Filter.Type = 'BP';
Filter.f_low = 13;
Filter.f_high = 30;
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

%  Bandpower in low beta range
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
% 
% %%  Bandpower in mid beta range
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
% % 
% %%  Bandpower in high beta range
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

% Keep only bandpower channels
TrialExclude=[];
ChannelExclude = origchan;
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

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
elseif strcmp(trainortest,'logisticb')
    logisticlda_b(P_C_S);
end
