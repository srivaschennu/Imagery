function P_C_S = rejartifacts(P_C_S)

alltrials = P_C_S.TrialNumber;
badtrials = findbadtrialschannels(P_C_S);

save(sprintf('%s_bt.mat',P_C_S.SubjectID),'badtrials','alltrials');

if ~isempty(badtrials)
    ChannelExclude = [];
    fprintf('Rejecting %d of %d trials from %s.\n', length(badtrials),length(alltrials),P_C_S.SubjectID);
    P_C_S=gBScuttrialschannels(P_C_S,badtrials,ChannelExclude);
end
