function [BadTrials BadChannels badtrial_idx badchannel_idx] = findbadtrialschannels(P_C_S)

badtrial_idx=strmatch('ARTIFACT',P_C_S.AttributeName,'exact');
badchannel_idx=strmatch('BAD',P_C_S.ChannelAttributeName,'exact');
type_idx=[];
channelnr_idx=[];
flag_tr='tr_exc';
flag_ch='ch_exc';
flag_type='type_exc';
flag_nr='nr_exc';
[BadTrials, BadChannels]=gBSselect(P_C_S,badtrial_idx,flag_tr,badchannel_idx,flag_ch,type_idx,flag_type,channelnr_idx,flag_nr);
