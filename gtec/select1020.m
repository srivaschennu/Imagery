function P_C_S = select1020(P_C_S)

montage = load(P_C_S.MontageName);
TrialExclude=[];
ChannelExclude=subset(P_C_S.Channels,montage.idx1020);
P_C_S = gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
P_C_S.ChannelName = montage.name1020;