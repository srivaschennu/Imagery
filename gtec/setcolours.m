function P_C_S = setcolours(P_C_S)

class_names = {'RIGHTHAND';'TOES'};

loadpaths

if ischar(P_C_S)
    mergedfile = [filepath P_C_S '_merged.mat'];
    %this will overwrite P_C_S in memory
    load(mergedfile);
end

fprintf('Setting Attribute Colours for %s.\n', P_C_S.SubjectID);

AttributeColor = P_C_S.AttributeColor;

if ~isempty(nonzeros(strcmp(class_names{1}, P_C_S.AttributeName)))
    AttributeColor{strcmp(class_names{1}, P_C_S.AttributeName)} = 'green';
end

if ~isempty(nonzeros(strcmp(class_names{2}, P_C_S.AttributeName)))
    AttributeColor{strcmp(class_names{2}, P_C_S.AttributeName)} = 'green';
end

if ~isempty(nonzeros(strncmp('BLOCK', P_C_S.AttributeName, 5)))
    AttributeColor(strncmp('BLOCK', P_C_S.AttributeName, 5)) = {'black'};
end

P_C_S.AttributeColor = AttributeColor;

if exist('mergedfile','var')
    save(mergedfile, 'P_C_S');
end