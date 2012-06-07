function mergefiles(basename)

class_names = {'RIGHTHAND';'TOES'};

loadpaths

rhfile = [filepath basename '_rh.mat'];
tofile = [filepath basename '_to.mat'];
mergedfile = [filepath basename '_merged.mat'];
tempfile = [filepath 'temp.mat'];

fprintf('Processing Right Hand data.\n');
RH = load(rhfile);
if isempty(nonzeros(strcmp(class_names{1}, RH.P_C_S.AttributeName)))
    class_info = [ones(1,length(RH.P_C_S.TrialNumber)); zeros(1,length(RH.P_C_S.TrialNumber))];
    use_rows = [1 2];
    RH.P_C_S = gBSloadclass(RH.P_C_S,class_info,class_names,use_rows);    
end

fprintf('Processing Toes data.\n');
TO = load(tofile);
if isempty(nonzeros(strcmp(class_names{2}, TO.P_C_S.AttributeName)))
    class_info = [zeros(1,length(TO.P_C_S.TrialNumber)); ones(1,length(TO.P_C_S.TrialNumber))];
    use_rows = [1 2];
    TO.P_C_S = gBSloadclass(TO.P_C_S,class_info,class_names,use_rows);
end

fprintf('Merging classes.\n');
save(tempfile,'-struct','TO');
clear TO

Concatenate='Trials';
AdoptChAttr=1;
AdoptTrialAttr=1;
AdoptMarkers=1;
RHTO_P_C = gBSmerge(RH.P_C_S,{tempfile},Concatenate,AdoptChAttr,AdoptTrialAttr,AdoptMarkers);
clear RH

RHTO_P_C.ParadigmCondition = 'RHTO';

%save merged data
fprintf('Saving %s.\n',mergedfile);
P_C_S = RHTO_P_C;
save(mergedfile,'P_C_S');
