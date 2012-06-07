function Imagery(RHCount,TOCount)

%catch invalid arguments, print help message and quit
if nargin ~= 2
    [RHCount TOCount] = PopupDialog;
    if isempty(RHCount) || isempty(TOCount)
        fprintf('ABORTED.\n');
        return;
    end
end

if ~isnumeric(RHCount) || RHCount < 0 || ~isnumeric(TOCount) || TOCount < 0
    error('Invalid block counts specified!');
end

%%%%%%%% PARAMETERS %%%%%%%%%
% number of beeps per block
numtrials = 15;

%netstation address
nshost = '10.0.0.42';

%netstation port
nsport = 55513;

%% global variables to track total number of blocks that have been run
global blockhist RHtot TOtot

if isempty(RHtot)
    RHtot = 0;
end

if isempty(TOtot)
    TOtot = 0;
end

%% connect to netstation the first time
if and(RHtot == 0, TOtot == 0)
    fprintf('Connecting to Net Station...\n');
    NetStation('Connect', nshost, nsport);
    pause(1);
end

%% setup block order to run
blocklist = {'RH','TO'};
blockorder = blocklist([ones(1,RHCount) ones(1,TOCount)+1]);

% maximum number of RH or TO blocks that are allowed to be consecutive
maxconsec = 2;
while true
    blockorder = blockorder(randperm(length(blockorder)));
    allblocks = [blockhist blockorder];
    if isempty(strfind(cell2mat(allblocks),repmat(blocklist{1},1,maxconsec+1))) && ...
            isempty(strfind(cell2mat(allblocks),repmat(blocklist{2},1,maxconsec+1)))
        break;
    end
end

%% run blocks
for b = 1:length(blockorder)
    IMtype = blockorder{b};
    
    if strcmp(IMtype,'RH')
        RHtot = RHtot+1;
    elseif strcmp(IMtype,'TO')
        TOtot = TOtot+1;
    end
    blockhist = [blockhist blockorder(b)];
    
    runblock(IMtype,numtrials);

    fprintf('Block of %s complete. Total RH = %d, Total TO = %d.\n\n', IMtype, RHtot, TOtot);
    if pausefor(10)
        break
    end
end

fprintf('DONE!\n');
end


function runblock(IMtype,numtrials)
%% run one block of imagery
global RHtot TOtot

fprintf('Running block %s', IMtype);

NetStation('Synchronize');
NetStation('StartRecording');
pause(1);

%load instruction
if strcmp(IMtype, 'RH')
    NetStation('Event', 'BGIN', GetSecs, 0.001, 'TYPE',1, 'BNUM',RHtot);
    [Inst, InstFS] = wavread('RHInst.wav');
    CurTot = RHtot;
elseif strcmp(IMtype, 'TO')
    NetStation('Event', 'BGIN', GetSecs, 0.001, 'TYPE',2, 'BNUM',TOtot);
    [Inst, InstFS] = wavread('TOInst.wav');
    CurTot = TOtot;
end

InstWAV = audioplayer(Inst, InstFS);

%load relax
[Rel, RelFS] = wavread('Relax.wav');
RelWAV = audioplayer(Rel, RelFS);

tone = sin(1:1323) * pi/6;
toneFS = 11025;

ToneWAV = audioplayer(tone, toneFS);


pause(5);

NetStation('Event', 'INST');
playblocking(InstWAV);

pause(4);

fprintf(': trial %02d', 0);
for i = 1:numtrials;
    fprintf('\b\b%02d', i);
    
    NetStation('Event', IMtype, GetSecs, 0.001, 'BNUM', CurTot, 'TNUM',i);
    
    playblocking(ToneWAV);
    
    x = 6500-3500*rand(1);
    pause(x/1000); % pause for ITI in seconds
    
end
fprintf('\n');

pause(2);

NetStation('Event', 'BEND');

playblocking(RelWAV);

NetStation('StopRecording');

pause(3);

end