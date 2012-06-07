function migrateGTEC(basename)

loadpaths;

load([filepath basename '_merged.mat']);

[badtrials badchans] = findbadtrialschannels(P_C_S);
fprintf('%s bad trials and %s bad channels found\n',num2str(length(badtrials)),num2str(length(badchans)));

dataimport_migrate(basename,badtrials,badchans);


