function dataimport_migrate(basename)

loadpaths

rawfile = [filepath basename '_merged.mat'];
chanlocfile = 'GSN-HydroCel-129.sfp';

blockcount = 15;
fprintf('\nNOTE: Assuming %d beeps per block\n', blockcount);

fprintf('Loading %s.\n',rawfile);

evalin('base','global Right_Hand Toes Questions');
global Right_Hand Toes Questions

load(rawfile);
Right_Hand = permute(P_C_S.data(logical(P_C_S.attribute(strcmp('RIGHTHAND',P_C_S.attributename),:)),:,:),[3 2 1]);
Toes = permute(P_C_S.data(logical(P_C_S.attribute(strcmp('TOES',P_C_S.attributename),:)),:,:),[3 2 1]);

if ~isempty(Right_Hand)
    fprintf('Importing Right_Hand data.\n');
    if size(Right_Hand,1) == 257
        load ELECS.mat
        Right_Hand = Right_Hand(keepchan,:,:);
    end
    
    RHEEG = pop_importdata('setname',basename,'data','Right_Hand','dataformat','array','chanlocs',[chanlocpath chanlocfile],...
        'nbchan',129,'pnts',1375,'srate',250,'ref','Cz','xmin',-1.5);
    
    evtype = repmat({'RIGHTHAND'},RHEEG.trials,1);
    evlat = num2cell(1.5:5.5:5.5*RHEEG.trials)';
    evepoch = num2cell((1:RHEEG.trials))';
    evbnum = num2cell(sort(repmat(1:ceil(RHEEG.trials/blockcount),1,blockcount)))';
    evbnum = evbnum(1:RHEEG.trials);
    eventinfo = cat(2,evtype,evlat,evepoch,evbnum);
    RHEEG = pop_importevent(RHEEG,'event',eventinfo,'fields', {'type','latency','epoch','bnum'},'timeunit',1);
end
clear global Right_Hand

if ~isempty(Toes)
    fprintf('Importing Toes data.\n');
    if size(Toes,1) == 257
        load ELECS.mat
        Toes = Toes(keepchan,:,:);
    end
    TOEEG = pop_importdata('setname',[basename '_orig'],'data','Toes','dataformat','array','chanlocs',[chanlocpath chanlocfile],...
        'nbchan',129,'pnts',1375,'srate',250,'ref','Cz','xmin',-1.5);
    
    evtype = repmat({'TOES'},TOEEG.trials,1);
    evlat = num2cell(1.5:5.5:5.5*TOEEG.trials)';
    evepoch = num2cell((1:TOEEG.trials))';
    evbnum = num2cell(sort(repmat(1:ceil(TOEEG.trials/blockcount),1,blockcount)))';
    evbnum = evbnum(1:TOEEG.trials);
    eventinfo = cat(2,evtype,evlat,evepoch,evbnum);
    TOEEG = pop_importevent(TOEEG,'event',eventinfo,'fields', {'type','latency','epoch','bnum'},'timeunit',1);
end
clear global Toes


if ~isempty(Questions)
    fprintf('Importing Questions data.\n');
    if size(Questions,1) == 257
        Questions = Questions(keepchan,:,:);
    end
    QSEEG = pop_importdata('setname',[basename '_orig'],'data','Questions','dataformat','array','chanlocs',[chanlocpath chanlocfile],...
        'nbchan',129,'pnts',1375,'srate',250,'ref','Cz','xmin',-1.5);
    
    evtype = repmat({'QUES'},QSEEG.trials,1);
    evlat = num2cell(1.5:5.5:5.5*QSEEG.trials)';
    evepoch = num2cell((1:QSEEG.trials))';
    evbnum = num2cell(sort(repmat(1:ceil(QSEEG.trials/blockcount),1,blockcount)))';
    evbnum = evbnum(1:QSEEG.trials);
    eventinfo = cat(2,evtype,evlat,evepoch,evbnum);
    QSEEG = pop_importevent(QSEEG,'event',eventinfo,'fields', {'type','latency','epoch','bnum'},'timeunit',1);
end
clear global Questions

if exist('RHEEG','var') && exist('TOEEG','var')
    EEG = pop_mergeset(RHEEG,TOEEG);
    EEG.condition = 'RHTO';
    clear RHEEG TOEEG
elseif exist('RHEEG','var') && ~exist('TOEEG','var')
    EEG = RHEEG;
    EEG.condition = 'RH';
    clear RHEEG
elseif ~exist('RHEEG','var') && exist('TOEEG','var')
    EEG = TOEEG;
    EEG.condition = 'TO';
    clear TOEEG
elseif exist('QSEEG','var')
    EEG = QSEEG;
    EEG.condition = 'QUES';
    clear QSEEG
end

EEG = pop_chanedit(EEG,'load',[chanlocpath chanlocfile]);
EEG = eeg_checkset(EEG);

%% ARTIFACT REJECTION AND INTERPOLATION
badtrials = find(P_C_S.attribute(strcmp('ARTIFACT',P_C_S.attributename),:));
badchannels = find(P_C_S.channelattribute(strcmp('BAD',P_C_S.channelattributename),:));
EEG.rejchan = zeros(1,EEG.nbchan);
EEG.rejchan(badchannels) = 1;

EEG = pop_select(EEG,'notrial',badtrials);
EEG = eeg_interp(EEG, badchannels);

%% RE-REFERENCING
EEG = rereference(EEG,2);

EEG.filepath = filepath;
EEG.setname = sprintf('%s',basename);
EEG.filename = sprintf('%s.set',basename);
fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);