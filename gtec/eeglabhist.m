% EEGLAB history file generated on the 07-Jul-2011
% ------------------------------------------------
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[EEG ALLEEG CURRENTSET] = eeg_retrieve(ALLEEG,1);
EEG = eeg_checkset( EEG );
EEG = pop_loadset('filename','p1211_imagery.set','filepath','/Users/chennu/Data/Imagery/');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
eeglab redraw;
