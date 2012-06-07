function [bestaccu sig pci01 pci001] = lda(basename,bsloract,TrainTestMethod,TrainInfo)

loadpaths;

if ~exist('TrainInfo','var')
    TrainInfo = [];
end

%% Load Data
fprintf('Loading %s.set\n', basename);
EEG = pop_loadset('filepath',filepath,'filename',[basename '.set']);
fprintf('Found %d trials, %d samples, %d channels.\n', EEG.trials, EEG.pnts, EEG.nbchan);

%% downsample data
newRate = 100;
fprintf('Downsampling data to %sHz...\n',num2str(newRate));
EEG = pop_resample(EEG, newRate);
EEG.setname = basename;

%% Channels to use for analyses
origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
EEG = pop_select(EEG,'channel',origchan);

%% Bandpower in frequency bands  
f_low = 7;
f_step = 6;
f_high = 30;
winlen = EEG.srate;
overlap = winlen - 1;
freqrange = f_low:f_step:f_high;
if freqrange(end) < f_high
    freqrange = [freqrange f_high];
end
fprintf('Calculating bandpower in frequency bands between %d:%d:%dHz\n',f_low,f_step,f_high);
EEG = bandpower(EEG,winlen,overlap,freqrange);

% fprintf('Saving %s%s.\n', EEG.filepath, [basename '_filt.set']);
% pop_saveset(EEG,'filename', [basename '_filt.set'], 'filepath', EEG.filepath);

%% concatenate features
switch char(bsloract)
    case 'baseline'
        EEG = concatfeats(EEG,[-0.5 0]);
    case 'action'
        EEG = concatfeats(EEG,[0.5 3.5]);
end

%% Train/test classifer
[bestaccu sig pci01 pci001] = svmlda_b(EEG,origchan,bsloract,TrainTestMethod,TrainInfo);

end
