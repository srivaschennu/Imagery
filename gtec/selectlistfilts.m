function selectfilt = selectlistfilts(filtnums)

liststring = cell(length(filtnums),1);
for i = 1:length(filtnums)
    liststring{i} = sprintf('%d',filtnums(i));
end

selectfilt = listdlg('ListString',liststring,'Name','Filters to reject','PromptString',...
    'Select filters to reject:','ListSize',[160 450]);