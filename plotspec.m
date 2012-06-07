function plotspec(basename)

loadpaths

EEG = pop_loadset(EEG,'filepath',filepath,'filename',[basename '.set']);

trialtype = zeros(1,length(EEG.epoch));
for e = 1:length(EEG.epoch)
    evlat = cell2mat(EEG.epoch(e).eventlatency);
    if strcmp('RIGHTHAND',EEG.epoch(e).eventtype{min(evlat) == evlat})
    trialtype(e) = 1;
    end
end

for typ = [1 0]
    tmpEEG = pop_select(EEG,'trial',find(trialtype == typ));
