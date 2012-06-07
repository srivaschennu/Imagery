function mergegtecdata(basename)

loadpaths

class_names = {'RIGHTHAND';'TOES'};

datafile = [filepath basename '.mat'];
rhdatafile = [filepath basename '_rh.mat'];
todatafile = [filepath basename '_to.mat'];
tempfile = [filepath 'temp.mat'];

%keepattr = 'FIRST5';

if exist(rhdatafile, 'file')
    fprintf('Processing %s.\n', rhdatafile);
    RH = load(rhdatafile);
    
    if exist('keepattr', 'var')
        trial_id=find(strcmp(keepattr,RH.P_C_S.AttributeName));
        channel_id=[];
        type_id=[];
        channelnr_id=[];
        flag_tr='tr_inc';
        flag_ch='ch_exc';
        flag_type='type_exc';
        flag_nr='nr_exc';
        fprintf('Keeping only trials with attribute %s.\n', keepattr);
        [TrialExclude, ChannelExclude]=gBSselect(RH.P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
        RH.P_C_S = gBScuttrialschannels(RH.P_C_S,TrialExclude,ChannelExclude);
    end
    
    RH.P_C_S = rejartifacts(RH.P_C_S);
else
    fprintf('File not found: %s\n', rhdatafile);
end


if exist(todatafile, 'file')
    fprintf('Processing %s.\n', todatafile);
    TO = load(todatafile);
    
    if exist('keepattr', 'var')
        trial_id=find(strcmp(keepattr,TO.P_C_S.AttributeName));
        channel_id=[];
        type_id=[];
        channelnr_id=[];
        flag_tr='tr_inc';
        flag_ch='ch_exc';
        flag_type='type_exc';
        flag_nr='nr_exc';
        fprintf('Keeping only trials with attribute %s.\n', keepattr);
        [TrialExclude, ChannelExclude]=gBSselect(TO.P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
        TO.P_C_S = gBScuttrialschannels(TO.P_C_S,TrialExclude,ChannelExclude);
    end
    
    TO.P_C_S = rejartifacts(TO.P_C_S);
else
    fprintf('File not found: %s\n', todatafile);
end

%equalise number of epochs in both classes
if exist('RH', 'var') && exist('TO', 'var')
    if length(RH.P_C_S.TrialNumber) ~= length(TO.P_C_S.TrialNumber)
        fprintf('Equalising number of epochs for %s to %d.\n', basename, ...
            min(length(RH.P_C_S.TrialNumber),length(TO.P_C_S.TrialNumber)));
        ChannelExclude = [];
        
        if length(RH.P_C_S.TrialNumber) > length(TO.P_C_S.TrialNumber)
            TrialExclude = length(TO.P_C_S.TrialNumber)+1:length(RH.P_C_S.TrialNumber);
            RH.P_C_S=gBScuttrialschannels(RH.P_C_S,TrialExclude,ChannelExclude);
        elseif length(TO.P_C_S.TrialNumber) > length(RH.P_C_S.TrialNumber)
            TrialExclude = length(RH.P_C_S.TrialNumber)+1:length(TO.P_C_S.TrialNumber);
            TO.P_C_S=gBScuttrialschannels(TO.P_C_S,TrialExclude,ChannelExclude);
        end
    end
    
    class_info = ones(1,length(RH.P_C_S.TrialNumber));
    class_names = {'RIGHTHAND'};
    use_rows = 1;
    RH.P_C_S = gBSloadclass(RH.P_C_S,class_info,class_names,use_rows);
    
    class_info = ones(1,length(TO.P_C_S.TrialNumber));
    class_names = {'TOES'};
    use_rows = 1;
    TO.P_C_S = gBSloadclass(TO.P_C_S,class_info,class_names,use_rows);
    
    fprintf('Merging classes.\n');
    save(tempfile,'-struct','TO');
    clear TO
    
    Concatenate='Trials';
    AdoptChAttr=1;
    AdoptTrialAttr=1;
    AdoptMarkers=1;
    RHTO_P_C = gBSmerge(RH.P_C_S,{tempfile},Concatenate,AdoptChAttr,AdoptTrialAttr,AdoptMarkers);
    clear RH
    
    %intersperse right hand and toes trials in merged dataset
    epochcount = length(RHTO_P_C.TrialNumber);
    epochmix = zeros(1,epochcount);
    epochmix(1:2:end) = 1:epochcount/2;
    epochmix(2:2:end) = (epochcount/2)+1:epochcount;
    
    datacopy = RHTO_P_C.Data;
    RHTO_P_C.Data = datacopy(epochmix,:,:);
    datacopy = RHTO_P_C.Attribute;
    RHTO_P_C.Attribute = datacopy(:,epochmix);
    
    %change reference
    RHTO_P_C = changeref(RHTO_P_C);
    
    %save merged data
    fprintf('Saving %s.\n',datafile);
    P_C_S = RHTO_P_C;
    save(datafile,'P_C_S');
    
elseif exist('RH', 'var')
    % Randomly assign trials to classes
    class_info = zeros(2,length(RH.P_C_S.TrialNumber));
    class_info(1,:) = round(rand(1,length(RH.P_C_S.TrialNumber)));
    class_info(2,:) = 1 - class_info(1,:);
    use_rows = [1 2];
    RH.P_C_S = gBSloadclass(RH.P_C_S,class_info,class_names,use_rows);
    
    RH.P_C_S = changeref(RH.P_C_S);
    save(datafile,'-struct','RH');
    
elseif exist('TO', 'var')
    % Randomly assign trials to classes
    class_info = zeros(2,length(TO.P_C_S.TrialNumber));
    class_info(1,:) = round(rand(1,length(TO.P_C_S.TrialNumber)));
    class_info(2,:) = 1 - class_info(1,:);
    use_rows = [1 2];
    TO.P_C_S = gBSloadclass(TO.P_C_S,class_info,class_names,use_rows);
    
    TO.P_C_S = changeref(TO.P_C_S);
    save(datafile,'-struct','TO');
end
