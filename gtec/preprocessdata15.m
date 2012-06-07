function preprocessdata(basename)

loadpaths

rawname = [basename '_raw'];
datafile = [filepath rawname '.mat'];
tempfile = [filepath 'temp.mat'];

fprintf('Loading %s.\n',datafile);
load(datafile);

%permute data to suit g.tec convention
if exist('Right_Hand', 'var')
    Right_Hand = permute(Right_Hand, [3 2 1]);
    save(tempfile, 'Right_Hand');
    destfile = [filepath basename '_rh.mat'];
    fprintf('Creating and saving %s.\n',destfile);
    P_C_S = loaddata(basename,tempfile,samplingRate,destfile);
    save(destfile,'P_C_S');
end

if exist('Toes', 'var')
    Toes = permute(Toes, [3 2 1]);
    save(tempfile, 'Toes');
    destfile = [filepath basename '_to.mat'];
    fprintf('Creating and saving %s.\n',destfile);
    P_C_S = loaddata(basename,tempfile,samplingRate,destfile);
    save(destfile,'P_C_S');
end

function P_C_S = loaddata(basename,tempfile,samplingRate,destfile)

montagepath = '';
eventlatency = 1500; %milliseconds
bcwin = [-0.5 0]; %baseline window (in sec) relative to target onset time
keepinfo = true;
blocklength = 15;

P_C_S = data;
P_C_S = load(P_C_S,tempfile);
P_C_S.FileName = destfile;
P_C_S.SamplingFrequency = samplingRate;
P_C_S.PreTrigger = eventlatency * (P_C_S.SamplingFrequency/1000);
P_C_S.PostTrigger = size(P_C_S.Data, 2) - P_C_S.PreTrigger;
P_C_S.SubjectID = basename;

% load geometry information
if length(P_C_S.Channels) == 129
    montagefile = [montagepath 'GSN-HydroCel-129.mat'];
elseif length(P_C_S.Channels) == 257
    montagefile =[montagepath 'GSN-HydroCel-257.mat'];
else
    fprintf('Could not load montage file.\n');
    montagefile = '';
end

if ~strcmp(montagefile,'')
    montage = load(montagefile);
    P_C_S.MontageName = montagefile;
    P_C_S.ChannelName = montage.channame;
    P_C_S.XPosition = montage.chanloc(:,1)';
    P_C_S.YPosition = montage.chanloc(:,2)';
    P_C_S.ZPosition = montage.chanloc(:,3)';
end

%baseline data
P_C_S = bc(P_C_S,bcwin);

%filter data
% Filter.Realization='fft';
% Filter.Type='BP';
% Filter.Order=0;
% Filter.f_high=40;
% Filter.f_low=0.1;
% TrialExclude=[];
% ChannelExclude=[];
% 
% P_C_S = gBSfilter(P_C_S,Filter,ChannelExclude,TrialExclude);

if keepinfo == true && exist(destfile, 'file')
    fprintf('Reading existing attributes from %s.\n', destfile);
    olddata = load(destfile);
    P_C_S.Attribute = olddata.P_C_S.Attribute;
    P_C_S.AttributeName = olddata.P_C_S.AttributeName;
    P_C_S.AttributeColor = olddata.P_C_S.AttributeColor;
    P_C_S.ChannelAttribute = olddata.P_C_S.ChannelAttribute;
    P_C_S.ChannelAttributeName = olddata.P_C_S.ChannelAttributeName;
    P_C_S.ChannelAttributeColor = olddata.P_C_S.ChannelAttributeColor;
end

for b = 1:length(P_C_S.TrialNumber)/blocklength
    if isempty(nonzeros(strcmp(sprintf('BLOCK%d', b), P_C_S.AttributeName)))
        AttrVector = [zeros(1,blocklength*(b-1)) ones(1,blocklength) zeros(1,length(P_C_S.TrialNumber)-blocklength*b)];
        P_C_S.Attribute = cat(1, P_C_S.Attribute, AttrVector);
        P_C_S.AttributeName = cat(1, P_C_S.AttributeName, {sprintf('BLOCK%d', b)});
        P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, {'green'});
    end
end

% if isempty(nonzeros(strcmp('FIRST5', P_C_S.AttributeName)))
%     AttrVector = [ones(1,5) zeros(1,10)];
%     P_C_S.Attribute = cat(1, P_C_S.Attribute, repmat(AttrVector, 1, length(P_C_S.TrialNumber)/blocklength));
%     P_C_S.AttributeName = cat(1, P_C_S.AttributeName, {'FIRST5'});
%     P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, {'green'});
% end
% 
% if isempty(nonzeros(strcmp('SECOND5', P_C_S.AttributeName)))
%     AttrVector = [zeros(1,5) ones(1,5) zeros(1,5)];
%     P_C_S.Attribute = cat(1, P_C_S.Attribute, repmat(AttrVector, 1, length(P_C_S.TrialNumber)/blocklength));
%     P_C_S.AttributeName = cat(1, P_C_S.AttributeName, {'SECOND5'});
%     P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, {'green'});
% end
% 
% if isempty(nonzeros(strcmp('THIRD5', P_C_S.AttributeName)))
%     AttrVector = [zeros(1,10) ones(1,5)];
%     P_C_S.Attribute = cat(1, P_C_S.Attribute, repmat(AttrVector, 1, length(P_C_S.TrialNumber)/blocklength));
%     P_C_S.AttributeName = cat(1, P_C_S.AttributeName, {'THIRD5'});
%     P_C_S.AttributeColor = cat(1, P_C_S.AttributeColor, {'green'});
% end