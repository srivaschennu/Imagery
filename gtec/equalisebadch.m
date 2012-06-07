function equalisebadch(basename,basename2)

loadpaths

trainfile = [filepath basename '_merged.mat'];
testfile = [filepath basename2 '_merged.mat'];

traindata = load(trainfile);
testdata = load(testfile);

[~, trainbadch] = findbadtrialschannels(traindata.P_C_S);
[~, testbadch] = findbadtrialschannels(testdata.P_C_S);

allbadch = union(trainbadch,testbadch);

ChannelAttribute = traindata.P_C_S.ChannelAttribute;
ChannelAttribute(strcmp('BAD',traindata.P_C_S.ChannelAttributeName),allbadch) = 1;
traindata.P_C_S.ChannelAttribute = ChannelAttribute;

ChannelAttribute = testdata.P_C_S.ChannelAttribute;
ChannelAttribute(strcmp('BAD',testdata.P_C_S.ChannelAttributeName),allbadch) = 1;
testdata.P_C_S.ChannelAttribute = ChannelAttribute;

save(trainfile,'-struct','traindata','P_C_S');
save(testfile,'-struct','testdata','P_C_S');