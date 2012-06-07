function P_C_S = bandpower(P_C_S,winlen,overlap,freqranges)

data = P_C_S.Data;
% 
% if rem(winlen,2) == 0
%     fftlen = nfft/2+1;
% else
%     fftlen = (nfft+1)/2;
% end

[~,F,T,P] = spectrogram(squeeze(data(1,:,1)),winlen,overlap,winlen,P_C_S.SamplingFrequency);

bpdata = zeros(size(data,1),length(T),length(freqranges)-1*size(data,3));

for t = 1:size(data,1)
    for c = 1:size(data,3)
        [~,F,T,P] = spectrogram(squeeze(data(t,:,c)),winlen,overlap,winlen,P_C_S.SamplingFrequency);

        for fr = 1:length(freqranges)-1
            freqidx = find(F >= freqranges(fr) & F <= freqranges(fr+1));
            bpdata(t,:,(length(freqranges)-1)*(c-1) + fr) = mean(P(freqidx,:),1);
        end
    end
end

fprintf('Time-points: %s:%s:%s\n',num2str(T(1)),num2str(T(2)-T(1)),num2str(T(end)));
P_C_S.Data = bpdata;