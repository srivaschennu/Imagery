function applylda(P_C_S)

filepath = 'D:\Data\Imagery\';

%% Log Transform
fprintf('Calculating log transform of bandpower channels.\n');
ApplyOn = 'multiple channels';
ChannelExclude_mult = [];
TrialExclude_mult = [];
Operation_mult = 'LOG10'; %log 10 operation so none of the parameters below matter!!
SecondOperand_mult(1) = 5;
Unit_mult = 'µV';
FirstOperand_two = 1;
Operation_two = 'SUB';
SecondOperand_two = 2;
ProgressBarFlag = 0;
P_C_S = gBSarithmetic(P_C_S, ApplyOn, ChannelExclude_mult,...
    TrialExclude_mult, Operation_mult, SecondOperand_mult,...
    Unit_mult, FirstOperand_two, Operation_two,...
    SecondOperand_two, ProgressBarFlag);


%% Apply classifier to data
subjname = P_C_S.SubjectID;
subjname = subjname(1:findstr('_',subjname)-1);
datafile = [filepath P_C_S.SubjectID '_bs.mat'];
fprintf('Loading %s.\n', datafile);
load(datafile);

targetwin = [0.1 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
targetwinidx = find(targetwin(1) <= out_x(2,:),1,'first'):find(targetwin(2) <= out_x(2,:),1,'first');

CL = zeros(length(C_O_boot), length(P_C_S.TrialNumber));

fprintf('Bootstrapping classifier test.\n');
for bi = 1:length(C_O_boot)
    
    C_O_train = C_O_boot{bi};
    [~, bestidx] = max(out_accu(bi,targetwinidx),[],2);
    
    out_wv  = C_O_train.out_clssfyr;
    
    Data = P_C_S.Data;
    
    for trial = 1:size(Data,1)
        Features = squeeze(Data(trial,:,:));
        trialclass = zeros(1,length(targetwinidx));
        
        for int = 1:length(targetwinidx)
            trialclass(int) = out_wv{bestidx,1} + (Features(targetwinidx(int),:) * out_wv{bestidx,2});
        end
        %CL(bi,trial) = mean(trialclass);
        [~, maxidx] = max(abs(trialclass), [], 2);
        CL(bi,trial) = trialclass(maxidx);
    end
end

save CL.mat CL