function Questions

%% Question order
qs = {
    'brothers'
    'sisters'
    'children'
%     'pain'
%     'month'
%     'home'
    };

answers = {
    'YRH'
    'YRH'
    };

%%%%%%%% PARAMETERS %%%%%%%%%
% number of beeps per block
numtrials = 15;

%netstation address
nshost = '10.0.0.42';

%netstation port
nsport = 55513;

%% global variables to track total number of blocks that have been run
global Qtot

if isempty(Qtot)
    Qtot = 0;
end

%% connect to netstation the first time
if Qtot == 0
    fprintf('Connecting to Net Station...\n');
    NetStation('Connect', nshost, nsport);
    pause(1);
end

%% run block
for answer = 1:length(answers)
    for q = 1:length(qs)
        
        IMtype = 'QUES';
        Qtot = Qtot+1;
        
        [question, qFS] = wavread([char(qs{q}) '.wav']);
        qWAV = audioplayer(question, qFS);
        
        [how2answer, h2aFS] = wavread([char(answers{answer}) '.wav']);
        ansWAV = audioplayer(how2answer, h2aFS);
        
        playblocking(qWAV);
        playblocking(ansWAV);
        playblocking(qWAV);        
        
        runblock(IMtype,numtrials);
        
        fprintf('Question %s with %s mapping complete.\n', num2str(q),char(answers{answer}));
        
        if answer == length(answers) && q == length(qs); 
            fprintf('All standard questions asked\n');
        else
            h = msgbox('Click OK when ready to move to the next question','Play next question?','modal');
            uiwait(h);
        end
        
    end
end
end

function runblock(IMtype,numtrials)
%% run one block of questions

global Qtot

fprintf('Running block %s', IMtype);

NetStation('Synchronize');
NetStation('StartRecording');
pause(1);

%send begin marker
NetStation('Event', 'BGIN', GetSecs, 0.001, 'TYPE',3, 'BNUM',Qtot);

%load relax
[Rel, RelFS] = wavread('Relax.wav');
RelWAV = audioplayer(Rel, RelFS);

tone = sin(1:1323) * pi/6;
toneFS = 11025;

ToneWAV = audioplayer(tone, toneFS);


pause(2);

fprintf(': trial %02d', 0);
for i = 1:numtrials;
    fprintf('\b\b%02d', i);
    
    NetStation('Event', IMtype, GetSecs, 0.001, 'TNUM',i);
    
    playblocking(ToneWAV);
    
    x = 6500-3500*rand(1);
    pause(x/1000); % pause for ITI in seconds
    
end
fprintf('\n');

pause(2);

NetStation('Event', 'BEND');

playblocking(RelWAV);

NetStation('StopRecording');

pause(5);

end