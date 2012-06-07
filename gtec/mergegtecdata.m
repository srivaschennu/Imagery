function mergegtecdata(basename)

loadpaths

mergedfile = [filepath basename '_merged.mat'];
destfile = [filepath basename '.mat'];

if exist(mergedfile, 'file')
    fprintf('Processing %s.\n', mergedfile);
    load(mergedfile);
    P_C_S = rejartifacts(P_C_S);
else
    fprintf('File not found: %s\n', mergedfile);
end

if strcmp(P_C_S.ParadigmCondition, 'RHTO');
    P_C_S = equaliseclass(P_C_S);
    P_C_S = mixclass(P_C_S);
end

%change reference
P_C_S = changeref(P_C_S);

fprintf('Saving %s.\n', destfile);
save(destfile,'P_C_S');


function P_C_S = equaliseclass(P_C_S)

class_names = {'RIGHTHAND';'TOES'};

%equalise number of epochs in both classes if necessary
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

if length(RHTrials) ~= length(TOTrials)
    fprintf('Equalising number of epochs for %s to %d.\n', P_C_S.SubjectID, min(length(RHTrials),length(TOTrials)));
    ChannelExclude = [];
    if length(RHTrials) > length(TOTrials)
        TrialExclude = RHTrials(length(TOTrials)+1:end);
        RHTrials = RHTrials(1:length(TOTrials));
        
    elseif length(TOTrials) > length(RHTrials)
        TrialExclude = TOTrials(length(RHTrials)+1:end);
        TOTrials = TOTrials(1:length(RHTrials));
    end
    P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
end


function P_C_S = mixclass(P_C_S)
fprintf('Interspersing epochs for %s.\n', P_C_S.SubjectID);

class_names = {'RIGHTHAND';'TOES'};

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

%reset random number generator
% reset(RandStream.getDefaultStream);
% %shuffle trials
% RHTrials = RHTrials(randperm(length(RHTrials)));
% TOTrials = TOTrials(randperm(length(TOTrials)));

%intersperse right hand and toes trials in merged dataset
epochmix = zeros(1,length(P_C_S.TrialNumber));
epochmix(1:2:end) = RHTrials;
epochmix(2:2:end) = TOTrials;

datacopy = P_C_S.Data;
P_C_S.Data = datacopy(epochmix,:,:);
datacopy = P_C_S.Attribute;
P_C_S.Attribute = datacopy(:,epochmix);
