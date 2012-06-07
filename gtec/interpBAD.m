function P_C_S = interpBAD(P_C_S, badchannels)

fprintf('Interpolating bad channels...\n');
data = P_C_S.Data;
data = permute(data,[3 2 1]);

numChannels = size(data,1);

if numChannels == 129
    EEG = pop_importdata( 'dataformat', 'array', 'data', data, 'srate',P_C_S.SamplingFrequency, 'pnts', size(data,2), 'xmin', -1.5, 'nbchan',size(data,1), 'chanlocs', 'GSN-HydroCel-129.sfp');
elseif numChannels == 257
    EEG = pop_importdata( 'dataformat', 'array', 'data', data, 'srate',P_C_S.SamplingFrequency, 'pnts', size(data,2), 'xmin', -1.5, 'nbchan',size(data,1), 'chanlocs', 'GSN-HydroCel-257.sfp');
end

EEG.trials = size(data,3);
EEG = eeg_interp(EEG, badchannels);

dataout = double(EEG.data);
dataout = permute(dataout,[3 2 1]);

chanattributes = P_C_S.ChannelAttribute;
chanattributename = P_C_S.ChannelAttributeName;

chanattributes(strcmp(chanattributename,'BAD'),:) = 0;

P_C_S.ChannelAttribute = chanattributes;
P_C_S.Data = dataout;




