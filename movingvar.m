function EEG = movingvar(EEG,winsize)

origdata = EEG.data;

if ndims(origdata) == 3
    for t = 1:EEG.trials
        swstart = 1;
        swstop = swstart+winsize*EEG.srate-1;
        while swstop <= size(origdata,2)
            EEG.data(:,swstart,t) = var(squeeze(origdata(:,swstart:swstop,t)),1,2);
            swstart = swstart+1; swstop = swstop+1;
        end
    end
    EEG = pop_select(EEG,'point',[1 swstart-1]);
end
EEG = eeg_checkset(EEG);


