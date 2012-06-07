function selecttrials = equalisetrials(P_C_S,blocklist)

class_names = {'RIGHTHAND';'TOES'};

trial_id=blocklist;
channel_id=[];
type_id=[];
channelnr_id=[];
flag_tr='tr_exc';
flag_ch='ch_exc';
flag_type='type_exc';
flag_nr='nr_exc';
[blocktrials, ~]=gBSselect(P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);


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
RHTrials = intersect(RHTrials,blocktrials);

totrials_idx=find(strcmp(class_names{2},P_C_S.AttributeName));
channel_idx=[];
type_idx=[];
channelnr_idx=[];
flag_tr='tr_exc';
flag_ch='ch_exc';
flag_type='type_exc';
flag_nr='nr_exc';
[TOTrials, ~]=gBSselect(P_C_S,totrials_idx,flag_tr,channel_idx,flag_ch,type_idx,flag_type,channelnr_idx,flag_nr);
TOTrials = intersect(TOTrials,blocktrials);

if length(RHTrials) ~= length(TOTrials)
%     fprintf('Equalising number of epochs for %s to %d.\n', P_C_S.SubjectID, min(length(RHTrials),length(TOTrials)));
    if length(RHTrials) > length(TOTrials)
        RHTrials = RHTrials(1:length(TOTrials));
        
    elseif length(TOTrials) > length(RHTrials)
        TOTrials = TOTrials(1:length(RHTrials));
    end
end

selecttrials = cat(2,RHTrials,TOTrials);