%badchannels = [3,4,5,14,19,56,79,88,111,112,113,117,118,124];
badchannels = 113;

chancount = size(data,1);
framecount = size(data,2);
epochcount = size(data,3);

markercode = 10;
eventtime = 1500; %millisec

markers = zeros(1,framecount,epochcount);
markpoint = eventtime * (fs / 1000);
markers(:,markpoint,:) = markercode;

data = reshape(data, [chancount, framecount * epochcount]);
data = reref(data,[],'exclude',badchannels);
markers = reshape(markers, [1, framecount * epochcount]);

y = [data; markers];
clear chancount framecount epochcount markercode eventtime markers markpoint data