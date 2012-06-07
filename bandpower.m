function EEG = bandpower(EEG,winlen,overlap,freqranges)

data = EEG.data;
% 
% if rem(winlen,2) == 0
%     fftlen = nfft/2+1;
% else
%     fftlen = (nfft+1)/2;
% end

data = double(data);

[~,F,T,P] = spectrogram(squeeze(data(1,:,1)),winlen,overlap,winlen,EEG.srate);

bpdata = zeros((length(freqranges)-1)*size(data,1),length(T),size(data,3));

for t = 1:size(data,3)
    for c = 1:size(data,1)
        [~,F,T,P] = spectrogram(squeeze(data(c,:,t)),winlen,overlap,winlen,EEG.srate);

        for fr = 1:length(freqranges)-1
            freqidx = find(F >= freqranges(fr) & F <= freqranges(fr+1));
            bpdata((length(freqranges)-1)*(c-1) + fr,:,t) = mean(P(freqidx,:),1);
        end
    end
end
bpdata = single(bpdata);

T = T - abs(EEG.xmin);
EEG = pop_select(EEG,'time',[T(1) T(end)]);
EEG.data = bpdata(:,1:end-1,:);