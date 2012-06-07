function trainandtestlda(P_C_S)

class_names = {'RIGHTHAND';'TOES'};

%% Log Transform
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

%%Train and test procedure
Trialset = P_C_S.TrialNumber;
ttinc = 30;
ttratio = ttinc:ttinc:length(Trialset)-ttinc;
BA = zeros(1,length(ttratio));
ChannelExclude = [];
Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
targetwin = [0 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;

for tt = 1:length(ttratio)
        
    TrialExclude = Trialset(1:ttratio(tt));
    P_C_S_test = gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
    TrialExclude = Trialset(ttratio(tt)+1:end);
    P_C_S_train = gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
    
    fprintf('%s: Running classifier with %d training and %d test trials.\n', ...
        P_C_S.SubjectID, length(P_C_S_train.TrialNumber), length(P_C_S_test.TrialNumber));

    %% Feature Matrix
    ChannelExclude=[];
    Permutate=0;
    FileName='';
    ProgressBarFlag = 0;
    FM_O_train = gBSfeaturematrix(P_C_S_train,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);
    FM_O_test = gBSfeaturematrix(P_C_S_test,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);
    
    %% Train Classifier
    PlotFeatures=[];
    Method='LDA';
    P.metric='';
    TrainTestData='100:100';
    FileName='';
    ProgressBarFlag = 0;
    C_O_train=gBSlinearclassifier(FM_O_train,Method,P,TrainTestData,PlotFeatures,FileName,ProgressBarFlag);
    
    %% Store classifier weights for every step
    out_wv  = C_O_train.out_clssfyr;
    out_err = C_O_train.out_err;
    
    fid = fopen(sprintf('trainres_%d.txt',tt),'w');
    fprintf(fid,'Classification Method: LDA');
    fprintf(fid,'\n');
    fprintf(fid,'Training and test option: %s\n', TrainTestData);
    fprintf(fid,'Number of trials: %d\n\n',length(P_C_S_train.TrialNumber));
    fprintf(fid,'Second\tSample\tMean Error\tErr Std Dev\tRuns:\n');
    
    out_err_ = zeros(1,size(out_err,2));
    out_err_x = zeros(2,size(out_err,2));
    for i=1:size(out_err,2)
        thiserr = out_err{2,i};
        out_err_(i)=thiserr(1);
        out_err_x(1:2,i) = out_err{1,i};
        fprintf(fid,'%.1f\t%d\t', out_err_x(1,i), out_err_x(2,i));
        fprintf(fid,'%.2f\t', thiserr);
        fprintf(fid,'\n');
    end
    
    if ~isempty(out_wv{1,1})
        fprintf(fid,'\n');
        fprintf(fid,'Bias value and Weight Vector: ');
        fprintf(fid,'\n');
        out_wv_ = zeros(size(out_wv{1,2},1)+1,size(out_wv,1));
        for i=1:size(out_wv,1)
            out_wv_(:,i) = [out_wv{i,1} out_wv{i,2}'];
            fprintf(fid,'%.2f\t',[out_wv{i,1} out_wv{i,2}']);
            fprintf(fid,'\n');
        end
        save WV.mat Interval out_err_ out_err_x out_wv_;
    end
    fclose(fid);
    
    %% Test Classifer
    targetwinidx = find(targetwin(1) <= out_err_x(2,:),1,'first'):find(targetwin(2) <= out_err_x(2,:),1,'first');
    [~, bestidx] = min(out_err_(targetwinidx));
    
    ClassifierNumber = targetwinidx(bestidx);
    PlotFeatures = [];
    FileName = '';
    ProgressBarFlag = 0;
    C_O_test = gBStestclassifier(FM_O_test,C_O_train,ClassifierNumber,PlotFeatures,FileName,ProgressBarFlag);
    
    %% Store classifier weights for every step
    out_wv  = C_O_test.out_clssfyr;
    out_err = C_O_test.out_err;
    
    fid = fopen(sprintf('testres_%d.txt',tt),'w');
    fprintf(fid,'Classification Method: LDA');
    fprintf(fid,'\n');
    fprintf(fid,'Training and test option: %s\n', TrainTestData);
    fprintf(fid,'Number of trials: %d\n\n',length(P_C_S_test.TrialNumber));
    fprintf(fid,'Second\tSample\tMean Error\tErr Std Dev\tRuns:\n');
    
    out_err_ = zeros(1,size(out_err,2));
    out_err_x = zeros(2,size(out_err,2));
    for i=1:size(out_err,2)
        thiserr = out_err{2,i};
        out_err_(i)=thiserr(1);
        out_err_x(1:2,i) = out_err{1,i};
        fprintf(fid,'%.1f\t%d\t', out_err_x(1,i), out_err_x(2,i));
        fprintf(fid,'%.2f\t', thiserr);
        fprintf(fid,'\n');
    end
    
    if ~isempty(out_wv{1,1})
        fprintf(fid,'\n');
        fprintf(fid,'Bias value and Weight Vector: ');
        fprintf(fid,'\n');
        out_wv_ = zeros(size(out_wv{1,2},1)+1,size(out_wv,1));
        for i=1:size(out_wv,1)
            out_wv_(:,i) = [out_wv{i,1} out_wv{i,2}'];
            fprintf(fid,'%.2f\t',[out_wv{i,1} out_wv{i,2}']);
            fprintf(fid,'\n');
        end
        save WV.mat Interval out_err_ out_err_x out_wv_;
    end
    fclose(fid);
    
    BA(tt) = 100 - min(out_err_(targetwinidx));
end

BA = cat(1,ttratio,BA);
save(sprintf('BA_%s.mat', P_C_S.SubjectID),'BA');

% %% Plot Figure
% ylim = [0 50];
% scrsize = get(0,'ScreenSize');
% fsize = [1000 660];
% figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
%     'Name',P_C_S.SubjectID,'NumberTitle','off');
% x=out_err_x(1,:) - P_C_S.PreTrigger * (1/P_C_S.SamplingFrequency);
% y=out_err_;
% a=axes;
%
% plot(x,y,'Parent',a);
% set(a,'YLim',ylim);
% set(a,'XLim',[x(1) x(end)]);
%
% %set(a,'XTickLabel',get(a,'XTick')-eventlatency);
% line([0 0],[0 ylim(2)],'Color','black');
% ylabel('Error rate (%)');
% xlabel('Time (s)');
% title(sprintf('Classification Error for %s', P_C_S.SubjectID), 'Interpreter', 'none');
% grid on
%
% maximumX=max(get(a,'XLim'));
% minimumX=min(get(a,'XLim'));
% line([minimumX maximumX],[10 10],'Color','green');
% text(maximumX+0.2,1,'EXCELLENT','Rotation',90);
% text(maximumX+0.2,16,'GOOD','Rotation',90);
% line([minimumX maximumX],[30 30],'Color','yellow');
% text(maximumX+0.2,31,'MORE TRAINING','Rotation',90);
