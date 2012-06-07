function P_C = avref(P_C)

badchannels = P_C.ChannelAttribute;
badchannels = find(badchannels(1,:) == 1);
Data = permute(P_C.Data,[3 2 1]);
Data = reref(Data,[],'exclude',badchannels);
P_C.Data = permute(Data,[3 2 1]);
