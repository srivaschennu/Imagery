function bootstraplda(P_C_S)

filepath = 'D:\Data\Imagery\';
class_names = {'RIGHTHAND';'TOES'};

%% Subtraction of baseline log power
y = P_C_S.Data;
subwin = [-1.492 0];
fprintf('Subtracting baseline power within %.1f-%.1fs.\n',subwin(1),subwin(2));
subwin = (subwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
for c = 1:size(y,1)
    for t = 1:size(y,3)
    y(c,:,t) = y(c,:,t) ./ mean(y(c,subwin(1):subwin(2),t),2);
    end
end
P_C_S.Data = y;

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

%% trial subaveraging to increase SNR
% y = P_C_S.Data;
% yrh = y(1:2:end,:,:);
% yto = y(2:2:end,:,:);
%
% groupsize = 3;
% groups = 1:groupsize:size(yrh,1);
% for g = 1:length(groups)-1
%     yrh(g,:,:) = mean(yrh(groups(g):groups(g+1)-1,:,:),1);
%     yto(g,:,:) = mean(yto(groups(g):groups(g+1)-1,:,:),1);
% end
%
% yrh(length(groups),:,:) = mean(yrh(groups(end):end,:,:),1);
% y(1:2:length(groups)*2,:,:) = yrh(1:length(groups),:,:);
% yto(length(groups),:,:) = mean(yto(groups(end):end,:,:),1);
% y(2:2:length(groups)*2,:,:) = yto(1:length(groups),:,:);
% P_C_S.Data = y;
%
% ChannelExclude = [];
% TrialExclude = length(groups)*2+1:length(P_C_S.TrialNumber);
% P_C_S = gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);
% fprintf('%d trials left after subaveraging.\n', length(P_C_S.TrialNumber));

%% Feature Matrix
targetwin = [0.1 2]; %time window relative to stimulus onset within which to identify best classifier accuracy
targetwin = (targetwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
%Interval=[P_C_S.SamplingFrequency/10 P_C_S.SamplingFrequency/10 P_C_S.PreTrigger+P_C_S.PostTrigger];
Interval=[5 5 P_C_S.PreTrigger+P_C_S.PostTrigger];
fprintf('Calculating feature matrix over interval %d:%d:%d.\n',Interval(1),Interval(2),Interval(3));

ChannelExclude=[];
Permutate=0;
FileName='';
ProgressBarFlag = 0;
FM_O = gBSfeaturematrix(P_C_S,Interval,class_names,Permutate,ChannelExclude,FileName,ProgressBarFlag);

%% Run bootstrap
numboot = 200;
%numboot = 0;

ClassifierType='LDA';
TrainTestData='CV';
% TrainTestData='100:100';
% TrainTestData='50:50';

out_accu = zeros(numboot+1,length(Interval(1):Interval(2):Interval(3)));
C_O_boot = cell(numboot+1,1);
out_x = zeros(2,length(Interval(1):Interval(2):Interval(3)));

datafile = [filepath P_C_S.SubjectID '_bs.mat'];
% load(datafile, 'C_O_boot');

fprintf('Bootstrapping %s classifier %d times with train-test method: %s.\n', ClassifierType, numboot, TrainTestData);
fprintf('Bootstrap iteration:    ');
for bi = 1:numboot+1
    
    fprintf('\b\b\b%03d',bi - 1);
    
    if bi > 1
        ClassLabels = FM_O.ClassLabels;
        FM_O.ClassLabels = ClassLabels(:,randperm(size(ClassLabels,2)));
    end
    
    %% Linear Classifier
    PlotFeatures = [];
    P.metric='';
    FileName='';
    ProgressBarFlag = 0;
    %fprintf('Generating LDA classifier with train-test method: %s.\n', TrainTestData);
    C_O=gBSlinearclassifier(FM_O,ClassifierType,P,TrainTestData,PlotFeatures,FileName,ProgressBarFlag);
    C_O = set(C_O,'features',[]);
    C_O = set(C_O,'datafm',[]);
    C_O_boot{bi} = C_O;
    
%     C_O = C_O_boot{bi};

    out_err = C_O.out_err;
    for i=1:size(out_err,2)
        out_x(1:2,i) = out_err{1,i};
        thiserr = out_err{2,i};
        out_accu(bi,i) = 100 - thiserr(1);
    end
end
fprintf('\n');

smoothwin = 0.2;
smoothwin = smoothwin .* P_C_S.SamplingFrequency;
smoothwin = find(out_x(2,:) - out_x(2,1) < smoothwin, 1, 'last');

%smoothing window average
smooth_accu = zeros(size(out_accu));
for t = 1:size(out_accu,2)
    swstart = max(1,t-floor(smoothwin/2));
    swstop = min(t+floor(smoothwin/2),size(out_accu,2));
    smooth_accu(:,t) = mean(out_accu(:,swstart:swstop),2);
end
out_accu = smooth_accu;

targetwinidx = find(targetwin(1) <= out_x(2,:),1,'first'):find(targetwin(2) <= out_x(2,:),1,'first');
bootaccu = max(out_accu(2:end,targetwinidx),[],2);

bootp = zeros(1,size(out_accu,2));
for t = 1:size(out_accu,2)
    bootp(t) = sum(bootaccu >= out_accu(1,t)) / length(bootaccu);
end

[bestaccu bestidx] = max(out_accu(1,targetwinidx),[],2);
bestbootp = bootp(targetwinidx(bestidx));

sigint = 1;
sigint = find(sigint <= out_x(1,:),1,'first');

siglevel = '';
if length(find(bootp(targetwinidx) < 0.05)) >= sigint
    siglevel = '*';
end
if length(find(bootp(targetwinidx) < 0.01)) >= sigint
    siglevel = '**';
end

% siglevel = '';
% if bestbootp < 0.05
%     siglevel = '*';
% end
% 
% if bestbootp < 0.01
%     siglevel = '**';
% end

fprintf('\n%s: Best accuracy = %.1f%s at time %.1fs. Bootstrap significance: %.6f.\n\n', ...
    P_C_S.SubjectID, bestaccu, siglevel, out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger/P_C_S.SamplingFrequency), bestbootp);

fprintf('Saving %s.\n', datafile);
save(datafile, 'bestaccu', 'bestbootp', 'numboot', 'out_x', 'out_accu', 'bootp', 'C_O_boot');

%% Plot Accuracy Figure
fprintf('Plotting classifier performance.\n');
ylim = [50 100];
scrsize = get(0,'ScreenSize');
fsize = [1000 660];
figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
    'Name',P_C_S.SubjectID,'NumberTitle','off');
x=out_x(1,:) - P_C_S.PreTrigger * (1/P_C_S.SamplingFrequency);
y=out_accu(1,:);
a=axes;

plot(x,y,'Parent',a,'Marker','.','LineWidth',3);
set(a,'YLim',ylim);
set(a,'XLim',[x(1) x(end)]);

line([0 0],[0 ylim(2)],'Color','black');
ylabel('Accuracy (%)');
xlabel('Time (s)');
title(sprintf('Single-trial classification accuracy for %s', P_C_S.SubjectID), 'Interpreter', 'none');
grid on

maximumX=max(get(a,'XLim'));
minimumX=min(get(a,'XLim'));
line([minimumX maximumX],[90 90],'Color','green');
line([minimumX maximumX],[70 70],'Color','yellow');
text(maximumX+0.2,91,'EXCELLENT','Rotation',90);
text(maximumX+0.2,78,'GOOD','Rotation',90);
text(maximumX+0.2,55,'MORE TRAINING','Rotation',90);

exportfig(gcf, ['figures/' P_C_S.SubjectID '_accu.jpg'], 'Format', 'jpeg', 'Color', 'cmyk');
close(gcf);

%% Plot Bootstrap Figure
fprintf('Plotting bootstrap results.\n');
ylim = [0 0.5];
scrsize = get(0,'ScreenSize');
fsize = [1000 660];
figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
    'Name',P_C_S.SubjectID,'NumberTitle','off');
x=out_x(1,:) - P_C_S.PreTrigger * (1/P_C_S.SamplingFrequency);
y=bootp;
a=axes;

plot(x,y,'Parent',a,'Marker','.','LineWidth',3);
set(a,'YLim',ylim);
set(a,'XLim',[x(1) x(end)]);

line([0 0],[0 ylim(2)],'Color','black');
ylabel('Bootstrap p value');
xlabel('Time (s)');
title(sprintf('Bootstrap results for %s', P_C_S.SubjectID), 'Interpreter', 'none');
grid on

maximumX=max(get(a,'XLim'));
minimumX=min(get(a,'XLim'));
line([minimumX maximumX],[0.05 0.05],'Color','yellow');
line([minimumX maximumX],[0.01 0.01],'Color','green');

exportfig(gcf, ['figures/' P_C_S.SubjectID '_boot.jpg'], 'format', 'jpeg', 'Color', 'cmyk');
close(gcf);
