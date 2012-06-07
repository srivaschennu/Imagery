function preprocessdata(basename)

loadpaths

rawfile = [filepath basename '_raw.mat'];
mergedfile = [filepath basename '_merged.mat'];
tempfile = [filepath 'temp.mat'];

class_names = {'RIGHTHAND';'TOES'};

if ~exist(rawfile,'file')
    fprintf('File not found: %s\n', rawfile);
    return;
end

fprintf('Loading %s.\n',rawfile);
load(rawfile);

%keepattr = 'FIRST5';

%permute data to suit g.tec convention
if exist('Right_Hand', 'var')
    Right_Hand = permute(Right_Hand, [3 2 1]);
    save(tempfile, 'Right_Hand');
    fprintf('Processing Right Hand data.\n');
    RH.P_C_S = loaddata(basename,tempfile,samplingRate);
    
    class_info = [ones(1,length(RH.P_C_S.TrialNumber)); zeros(1,length(RH.P_C_S.TrialNumber))];
    use_rows = [1 2];
    RH.P_C_S = gBSloadclass(RH.P_C_S,class_info,class_names,use_rows);
    
    if exist('keepattr', 'var')
        trial_id=find(strcmp(keepattr,RH.P_C_S.AttributeName));
        channel_id=[];
        type_id=[];
        channelnr_id=[];
        flag_tr='tr_inc';
        flag_ch='ch_exc';
        flag_type='type_exc';
        flag_nr='nr_exc';
        fprintf('Keeping only trials with attribute %s.\n', keepattr);
        [TrialExclude, ChannelExclude]=gBSselect(RH.P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
        RH.P_C_S = gBScuttrialschannels(RH.P_C_S,TrialExclude,ChannelExclude);
    end
end

if exist('Toes', 'var')
    Toes = permute(Toes, [3 2 1]);
    save(tempfile, 'Toes');
    fprintf('Processing Toes data.\n');
    TO.P_C_S = loaddata(basename,tempfile,samplingRate);
    
    class_info = [zeros(1,length(TO.P_C_S.TrialNumber)); ones(1,length(TO.P_C_S.TrialNumber))];
    use_rows = [1 2];
    TO.P_C_S = gBSloadclass(TO.P_C_S,class_info,class_names,use_rows);
    
    if exist('keepattr', 'var')
        trial_id=find(strcmp(keepattr,TO.P_C_S.AttributeName));
        channel_id=[];
        type_id=[];
        channelnr_id=[];
        flag_tr='tr_inc';
        flag_ch='ch_exc';
        flag_type='type_exc';
        flag_nr='nr_exc';
        fprintf('Keeping only trials with attribute %s.\n', keepattr);
        [TrialExclude, ChannelExclude]=gBSselect(TO.P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
        TO.P_C_S = gBScuttrialschannels(TO.P_C_S,TrialExclude,ChannelExclude);
    end
end

if exist('RH', 'var') && exist('TO', 'var')
    fprintf('Merging classes.\n');
    save(tempfile,'-struct','TO');
    clear TO
    
    Concatenate='Trials';
    AdoptChAttr=1;
    AdoptTrialAttr=1;
    AdoptMarkers=1;
    RHTO_P_C = gBSmerge(RH.P_C_S,{tempfile},Concatenate,AdoptChAttr,AdoptTrialAttr,AdoptMarkers);
    clear RH
    
    RHTO_P_C = loadattr(RHTO_P_C,mergedfile);
    RHTO_P_C.ParadigmCondition = 'RHTO';
    
    %save merged data
    fprintf('Saving %s.\n',mergedfile);
    P_C_S = RHTO_P_C;
    save(mergedfile,'P_C_S');
    
elseif exist('RH', 'var')
    RH.P_C_S = loadattr(RH.P_C_S,mergedfile);
    RH.P_C_S.ParadigmCondition = 'RH';
    save(mergedfile,'-struct','RH','P_C_S');
    
elseif exist('TO', 'var')
    TO.P_C_S = loadattr(TO.P_C_S,mergedfile);
    TO.P_C_S.ParadigmCondition = 'TO';
    save(mergedfile,'-struct','TO','P_C_S');
end


function P_C_S = loaddata(basename,tempfile,samplingRate)

montagepath = '';
eventlatency = 1500; %milliseconds
bcwin = [-0.5 0]; %baseline window (in sec) relative to target onset time

P_C_S = data;
P_C_S = load(P_C_S,tempfile);

P_C_S.SamplingFrequency = samplingRate;
P_C_S.PreTrigger = eventlatency * (P_C_S.SamplingFrequency/1000);
P_C_S.PostTrigger = size(P_C_S.Data, 2) - P_C_S.PreTrigger;
P_C_S.SubjectID = basename;

% load geometry information
if length(P_C_S.Channels) == 129
    montagefile = [montagepath 'GSN-HydroCel-129.mat'];
elseif length(P_C_S.Channels) == 257
    montagefile =[montagepath 'GSN-HydroCel-257.mat'];
else
    fprintf('Could not load montage file.\n');
    montagefile = '';
end

if ~strcmp(montagefile,'')
    montage = load(montagefile);
    P_C_S.MontageName = montagefile;
    P_C_S.ChannelName = montage.channame;
    P_C_S.XPosition = montage.chanloc(:,1)';
    P_C_S.YPosition = montage.chanloc(:,2)';
    P_C_S.ZPosition = montage.chanloc(:,3)';
end

% %filter data
% Filter.Realization='fft';
% Filter.Type='BP';
% Filter.Order=8;
% Filter.f_high=40;
% Filter.f_low=1;
% TrialExclude=[];
% ChannelExclude=[];
% P_C_S = gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);

%baseline data
P_C_S = bc(P_C_S,bcwin);



function P_C_S = loadattr(P_C_S,destfile)

class_names = {'RIGHTHAND';'TOES'};
% keepinfo = true;
keepinfo = false;

% blocklength = 5;
blocklength = 15;

fprintf('\nNOTE: Assuming %d trials per block.\n\n', blocklength);

if length(P_C_S.Channels) == 129
    origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
elseif length(P_C_S.Channels) == 257
    origchan = [8    9   17   43   44   45   51   52   53   58   59   60   64   65   66   71   72   78   79   80   81   89   90  130  131  132  143  144  154  155  164  173  181  182  183  184  185  186  194  195  196  197  198  257];
end

if keepinfo == true && exist(destfile, 'file')
    fprintf('Reading existing attributes from %s.\n', destfile);
    olddata = load(destfile);
    P_C_S.Attribute = olddata.P_C_S.Attribute;
    P_C_S.AttributeName = olddata.P_C_S.AttributeName;
    P_C_S.AttributeColor = olddata.P_C_S.AttributeColor;
    P_C_S.ChannelAttribute = olddata.P_C_S.ChannelAttribute;
    P_C_S.ChannelAttributeName = olddata.P_C_S.ChannelAttributeName;
    P_C_S.ChannelAttributeColor = olddata.P_C_S.ChannelAttributeColor;
end

%mark channels to be kept for analysis with CUT attribute
ChannelAttribute = P_C_S.ChannelAttribute;
ChannelAttribute(strcmp('CUT',P_C_S.ChannelAttributeName),:) = 0;
ChannelAttribute(strcmp('CUT',P_C_S.ChannelAttributeName),origchan) = 1;
P_C_S.ChannelAttribute = ChannelAttribute;

%add block information
rhtrials_idx=find(strcmp(class_names{1},P_C_S.AttributeName));
channel_idx=[];
type_idx=[];
channelnr_idx=[];
flag_tr='tr_exc';
flag_ch='ch_exc';
flag_type='type_exc';
flag_nr='nr_exc';
[RHTrials, ~]=gBSselect(P_C_S,rhtrials_idx,flag_tr,channel_idx,flag_ch,type_idx,flag_type,channelnr_idx,flag_nr);

totrials_idx=find(strcmp(class_names{2},P_C_S.AttributeName));
channel_idx=[];
type_idx=[];
channelnr_idx=[];
flag_tr='tr_exc';
flag_ch='ch_exc';
flag_type='type_exc';
flag_nr='nr_exc';
[TOTrials, ~]=gBSselect(P_C_S,totrials_idx,flag_tr,channel_idx,flag_ch,type_idx,flag_type,channelnr_idx,flag_nr);

blockcount = ceil(max(length(RHTrials),length(TOTrials))/blocklength);
RHAttribute = [];
TOAttribute = [];
AttributeName = {};
AttributeColor = {};

for b = 1:blockcount
    if isempty(nonzeros(strcmp(sprintf('BLOCK%d', b), P_C_S.AttributeName)))
        RHAttribute(b,1:length(RHTrials)) = 0;
        RHAttribute(b,((b-1)*blocklength)+1:min(b*blocklength,end)) = 1;
        TOAttribute(b,1:length(TOTrials)) = 0;
        TOAttribute(b,((b-1)*blocklength)+1:min(b*blocklength,end)) = 1;
        AttributeName = cat(1, AttributeName, {sprintf('BLOCK%d', b)});
        AttributeColor = cat(1,AttributeColor, {'black'});
    end
end
P_C_S.Attribute = cat(1, P_C_S.Attribute, cat(2,RHAttribute,TOAttribute));
P_C_S.AttributeName = cat(1, P_C_S.AttributeName, AttributeName);
P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, AttributeColor);

P_C_S = setcolours(P_C_S);

% if isempty(nonzeros(strcmp('FIRST5', P_C_S.AttributeName)))
%     AttrVector = [ones(1,5) zeros(1,10)];
%     P_C_S.Attribute = cat(1, P_C_S.Attribute, repmat(AttrVector, 1, length(P_C_S.TrialNumber)/blocklength));
%     P_C_S.AttributeName = cat(1, P_C_S.AttributeName, {'FIRST5'});
%     P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, {'green'});
% end
%
% if isempty(nonzeros(strcmp('SECOND5', P_C_S.AttributeName)))
%     AttrVector = [zeros(1,5) ones(1,5) zeros(1,5)];
%     P_C_S.Attribute = cat(1, P_C_S.Attribute, repmat(AttrVector, 1, length(P_C_S.TrialNumber)/blocklength));
%     P_C_S.AttributeName = cat(1, P_C_S.AttributeName, {'SECOND5'});
%     P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, {'green'});
% end
%
% if isempty(nonzeros(strcmp('THIRD5', P_C_S.AttributeName)))
%     AttrVector = [zeros(1,10) ones(1,5)];
%     P_C_S.Attribute = cat(1, P_C_S.Attribute, repmat(AttrVector, 1, length(P_C_S.TrialNumber)/blocklength));
%     P_C_S.AttributeName = cat(1, P_C_S.AttributeName, {'THIRD5'});
%     P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, {'green'});
% end
