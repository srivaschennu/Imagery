function selectfilt = selectlist(numfilters)

liststring = cell(numfilters,1);
for i = 1:numfilters
    liststring{i} = sprintf('%d',i);
end

selectfilt = listdlg('ListString',liststring,'Name','Filter Section','PromptString',...
    'Select filters to keep:','ListSize',[160 450]);