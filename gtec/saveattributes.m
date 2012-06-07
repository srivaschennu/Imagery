function saveattributes(basename)

filepath = 'd:\data\imagery\';

datafile = [filepath basename '_rh.mat'];
destfile = [filepath basename '_rh_attr.mat'];
load(datafile);
TrialAttribute = P_C_S.Attribute;
ChannelAttribute = P_C_S.ChannelAttribute;
save(destfile,'TrialAttribute','ChannelAttribute');

datafile = [filepath basename '_to.mat'];
destfile = [filepath basename '_to_attr.mat'];
load(datafile);
TrialAttribute = P_C_S.Attribute;
ChannelAttribute = P_C_S.ChannelAttribute;
save(destfile,'TrialAttribute','ChannelAttribute');
