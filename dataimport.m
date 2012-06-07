function dataimport(basename)

loadpaths

chanvarthresh = 500;
trialvarthresh = 500;

filenames = dir(sprintf('%s%s*', filepath, basename));

if isempty(filenames)
    error('No files found to import!\n');
end

if length(filenames) > 1
    error('Expected 1 file. Found %d.',length(filenames));
end

fprintf('\nProcessing %s.\n\n', filenames.name);
EEG = pop_readegimff(sprintf('%s%s', filepath, filenames.name));

RHcount = 0;
TOcount = 0;
Qcount = 0;
for e = 1:length(EEG.event)
    switch EEG.event(e).type
        case 'BGIN'
            switch EEG.event(e+2).type
                case 'RH  '
                    RHcount = RHcount+1;
                    EEG.event(e).bnum = RHcount;
                    
                case 'TO  '
                    TOcount = TOcount+1;
                    EEG.event(e).bnum = TOcount;
                    
                case 'QUES'
                    Qcount = Qcount + 1;
                    EEG.event(e).bnum = Qcount;
                    
                otherwise
                    error('Unknown block type %s.', EEG.event(e+1).type);
            end
            
        case 'RH  '
            EEG.event(e).type = 'RIGHTHAND';
            EEG.event(e).bnum = RHcount;

        case 'TO  '
            EEG.event(e).type = 'TOES';
            EEG.event(e).bnum = TOcount;
            
        case 'QUES'
            EEG.event(e).bnum = Qcount;
    end
end
fprintf('\nFound %d RH, %d TO, %d QUES blocks.\n',RHcount,TOcount,Qcount);

if EEG.nbchan == 128
    chanlocmat = 'GSN-HydroCel-128.mat';
elseif EEG.nbchan == 256
    chanlocmat = 'GSN-HydroCel-256.mat';
end

load([chanlocpath chanlocmat]);
for i = 1:length(idx1020)
    EEG.chanlocs(idx1020(i)).labels = name1020{i};
end

if EEG.nbchan == 256
    load ELECS.mat
    EEG = pop_select(EEG,'channel',keepchan);
end

EEG = eeg_checkset(EEG);

locutoff = 1; hicutoff = 40;

fprintf('Filtering between %d-%dHz.\n',locutoff,hicutoff);
EEG = pop_eegfilt(EEG,locutoff,0);
EEG = pop_eegfilt(EEG,0,hicutoff);

EEG = pop_epoch(EEG,{'RIGHTHAND','TOES'},[-1.5 4]);
EEG = pop_rmbase(EEG, [-500 0]);

EEG.filepath = filepath;
EEG.setname = sprintf('%s',basename);
EEG.filename = sprintf('%s.set',basename);

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

%% ARTIFACT REJECTION AND INTERPOLATIONS
markartifacts(EEG.setname,chanvarthresh,trialvarthresh,1,1);
EEG = pop_loadset('filepath',filepath,'filename',EEG.filename);
EEG = ipbadchan(EEG);

%% RE-REFERENCING
EEG = rereference(EEG,2);

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

evalin('base','eeglab');
assignin('base','EEG',EEG);
evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
evalin('base','eeglab redraw');
