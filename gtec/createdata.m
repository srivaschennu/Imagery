function createdata(basename)

filepath = 'd:\data\imagery\';
datafile = [filepath basename '.mat'];

P_C = data;
P_C = load(P_C,datafile);

load(datafile, 'samplingRate');
P_C.SamplingFrequency = samplingRate;

badchannels = 113;

chancount = size(data,1);
framecount = size(data,2);
epochcount = size(data,3);

markercode = 10;
eventtime = 1500; %millisec

markers = zeros(1,framecount,epochcount);
markpoint = eventtime * (fs / 1000);
markers(:,markpoint,:) = markercode;