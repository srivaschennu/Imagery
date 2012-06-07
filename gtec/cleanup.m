files = dir('*_129_merged.mat');

for f = 1:length(files129)
    files{f} = strrep(files{f},'_129','');
    %delete(files{f});
end