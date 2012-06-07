function [bestaccu sig pci01 pci001] = svmlda_b(EEG,origchan,bsloract,TrainTestMethod,Traininfo)

% %% 5 trials only
% truetrialnums = cat(2,EEG.event.urevent);
% % temptrials = 1:15:max(truetrialnums);
% temptrials = 8:15:max(truetrialnums);
% 
% thisset = [];
% for blockrun = 1:length(temptrials)
%     thisset = [thisset temptrials(blockrun):temptrials(blockrun)+7];
% end
% thisset = thisset(thisset<=max(truetrialnums));
% trials2use = [];
% for blockrun = 1:length(thisset)
%     x = find(truetrialnums == thisset(blockrun));
%     if ~isempty(x);
%         trials2use(blockrun) = x;
%     end
% end
% [~,~,trials2use] = find(trials2use);
% EEG.event = EEG.event(trials2use);
% features = EEG.data(:,:,trials2use);
% % %%

features = EEG.data;
%% Log Transform
fprintf('Calculating log transform of bandpower channels.\n');
features = log(features);

%% Select classes
classtype = zeros(1,size(features,3));
blocktrial = zeros(1,size(features,3));

for t = 1:size(features,3)
    if strcmp(TrainTestMethod,'test')
        classtype(t) = strcmp(EEG.event(t).type,'QUES');
    else
        classtype(t) = strcmp(EEG.event(t).type,'RIGHTHAND');    % 1 = RH, 0 = TO;
    end
    
    if iscell(EEG.epoch(t).eventbnum)
        blocktrial(t) = EEG.epoch(t).eventbnum{1};
    else
        blocktrial(t) = EEG.epoch(t).eventbnum(1);
    end
end


switch TrainTestMethod
    
    case '50:50'
        
        AllCoeffs = {};
        allaccs = [];
        
        truetrialnums = cat(2,EEG.event.urevent);
        % temptrials = 1:15:max(truetrialnums);
        temptrials = 1:15:max(truetrialnums);
        
        thisset = [];
        for blockrun = 1:length(temptrials)
            thisset = [thisset temptrials(blockrun):temptrials(blockrun)+7];
        end
        thisset = thisset(thisset<=max(truetrialnums));
        trials2use = [];
        for blockrun = 1:length(thisset)
            x = find(truetrialnums == thisset(blockrun));
            if ~isempty(x);
                trials2use(blockrun) = x;
            end
        end
        [~,~,trials2use] = find(trials2use);
        
        traintrials = trials2use;
        
                truetrialnums = cat(2,EEG.event.urevent);
        % temptrials = 1:15:max(truetrialnums);
        temptrials = 9:15:max(truetrialnums);
        
        thisset = [];
        for blockrun = 1:length(temptrials)
            thisset = [thisset temptrials(blockrun):temptrials(blockrun)+6];
        end
        thisset = thisset(thisset<=max(truetrialnums));
        trials2use = [];
        for blockrun = 1:length(thisset)
            x = find(truetrialnums == thisset(blockrun));
            if ~isempty(x);
                trials2use(blockrun) = x;
            end
        end
        [~,~,trials2use] = find(trials2use);
        
        testtrials = trials2use;       
        

        trainlabels = classtype(traintrials)';
        testlabels = classtype(testtrials)';
        
        
        fprintf('Testing %d trials: %s.\n', length(testtrials), num2str(testtrials));
        
        trainfeatures = squeeze(features(:,1,traintrials))';
        testfeatures = squeeze(features(:,1,testtrials))';
        
        %% normalise for SVM
        for feat = 1:size(trainfeatures,2)
            meanfeats(feat) = mean(trainfeatures(:,feat));
            stdfeats(feat) = std(trainfeatures(:,feat));
            normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        end
        trainfeatures = normtrainfeats;
        
        for feat = 1:size(testfeatures,2)
            normtestfeats(:,feat) = (testfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        end
        testfeatures = normtestfeats;
        %
        
        b = svmtrain(trainfeatures,trainlabels,'autoscale','false');
        AllCoeffs{1} = b;
        testres = svmclassify(b,testfeatures);
        allaccs = [allaccs; ~xor(testres > 0, testlabels > 0)];
        %             testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
        
        nb = NaiveBayes.fit(trainfeatures,trainlabels);
        
        [~,f] = svmdecision(testfeatures,b);
        alldecisions = f';
        alllabels = testlabels';
        
        save([EEG.setname '_train.mat'],'b', 'meanfeats','stdfeats', 'nb', 'alldecisions', 'alllabels');
        clear meanfeats stdfeats normtrainfeats normtestfeats;
         
    
    case 'cv'
        
        %% Exclude artefacted blocks
        blocknums = unique(blocktrial);
        
        badCVs = [];
        
        for k = 1:length(blocknums)
            if length(find(blocktrial == blocknums(k))) < 5
                badCVs = [badCVs k];
                fprintf('Excluding block %d with %d trials.\n', blocknums(k), length(find(blocktrial == blocknums(k))));
            end
        end
        
        blocknums = setdiff(blocknums,blocknums(badCVs));
        
        numsamples = size(features,2);
        
        AllCoeffs = {};
        allaccs = [];
        
        alllabels = [];
        alldecisions = [];
        alltrialnums = [];
        
        for run = 1:length(blocknums)
            traintrials = [];
            trainblocks = setdiff(blocknums,run);
            
            for j = 1:length(trainblocks)
                traintrials = [traintrials find(blocktrial == trainblocks(j))];
            end
            
            testtrials = find(blocktrial == blocknums(run));
            trainlabels = classtype(traintrials)';
            testlabels = classtype(testtrials)';
            
            
            fprintf('Testing %d trials: %s.\n', length(testtrials), num2str(testtrials));
            for t = 1:numsamples
                
                trainfeatures = squeeze(features(:,t,traintrials))';
                testfeatures = squeeze(features(:,t,testtrials))';
                
                %% normalise for SVM
                for feat = 1:size(trainfeatures,2)
                    meanfeats(feat) = mean(trainfeatures(:,feat));
                    stdfeats(feat) = std(trainfeatures(:,feat));
                    normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
                end
                trainfeatures = normtrainfeats;
                
                for feat = 1:size(testfeatures,2)
                    normtestfeats(:,feat) = (testfeatures(:,feat) - mean(meanfeats(feat))) ./ mean(stdfeats(feat));
                end
                testfeatures = normtestfeats;
                clear meanfeats stdfeats normtrainfeats normtestfeats;
                %
                
                b = svmtrain(trainfeatures,trainlabels,'autoscale','false');
                AllCoeffs{run} = b;
                testres = svmclassify(b,testfeatures);
                allaccs = [allaccs; ~xor(testres > 0, testlabels > 0)];
                %             testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
                
                [~,f] = svmdecision(testfeatures,b);                
                alldecisions = [alldecisions f'];
                alllabels = [alllabels testlabels'];
                
                currenttrialnums = cat(2,EEG.event(testtrials).urevent); 
                currenttrialnums = mod(currenttrialnums,15);
                currenttrialnums(currenttrialnums == 0) = 15;
                alltrialnums = [alltrialnums currenttrialnums];                
                
                
            end
            
        end       
        
        uniquetrialnums = unique(alltrialnums);
        numtrialnums = [];
        numaccstrialnums = [];
        
        save 'temp.mat' alldecisions alllabels;
        
        for ut = 1:length(uniquetrialnums)
           
            numtrialnums(ut) = length(find(alltrialnums == uniquetrialnums(ut)));
            numaccstrialnums(ut) = sum(allaccs(find(alltrialnums == uniquetrialnums(ut))));
            
        end
        
        fprintf('\n%s\n',num2str(uniquetrialnums));
        fprintf('\n%s\n',num2str(numtrialnums));
        fprintf('\n%s\n',num2str(numaccstrialnums));
        
        
    case 'train'
        
        AllCoeffs = {};
        allaccs = [];
        
        traintrials = 1:size(features,3);
        testtrials = traintrials;
        trainlabels = classtype(traintrials)';
        testlabels = classtype(testtrials)';
        
        
        fprintf('Testing %d trials: %s.\n', length(testtrials), num2str(testtrials));
        
        trainfeatures = squeeze(features(:,1,traintrials))';
        testfeatures = squeeze(features(:,1,testtrials))';
        
        %% normalise for SVM
        for feat = 1:size(trainfeatures,2)
            meanfeats(feat) = mean(trainfeatures(:,feat));
            stdfeats(feat) = std(trainfeatures(:,feat));
            normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        end
        trainfeatures = normtrainfeats;
        
        for feat = 1:size(testfeatures,2)
            normtestfeats(:,feat) = (testfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        end
        testfeatures = normtestfeats;
        %
        
        b = svmtrain(trainfeatures,trainlabels,'autoscale','false');
        AllCoeffs{1} = b;
        testres = svmclassify(b,testfeatures);
        allaccs = [allaccs; ~xor(testres > 0, testlabels > 0)];
        %             testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
        
        nb = NaiveBayes.fit(trainfeatures,trainlabels);
        
        [~,f] = svmdecision(testfeatures,b);
        alldecisions = f';
        alllabels = testlabels';
        
        save([EEG.setname '_train.mat'],'b', 'meanfeats','stdfeats', 'nb', 'alldecisions', 'alllabels');
        clear meanfeats stdfeats normtrainfeats normtestfeats;
        
        
    case 'test'
        
        load([char(Traininfo) '_train.mat']);
        
        testfeatures = squeeze(features)';
        
        %% normalise for SVM
        for feat = 1:size(testfeatures,2)
            normtestfeats(:,feat) = (testfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        end
        testfeatures = normtestfeats;
        %
        
        testres = svmclassify(b,testfeatures);
        
        [~,f] = svmdecision(testfeatures,b);
                        
        blocks = unique(blocktrial);
        
        for block = blocks(1:length(blocks))
%             currentres = testres(blocktrial == block | blocktrial == block+3);
            currentres = testres(blocktrial == block);         
            
%             currentdec = f(blocktrial == block | blocktrial == block+3);
            currentdec = f(blocktrial == block);
            
            rhdecs = alldecisions(alllabels == 1);
            todecs = alldecisions(alllabels == 0);          
              
            
            [phat, pci01] = binofit(sum(currentres),length(currentres),0.01);
            [~, pci001] = binofit(sum(currentres),length(currentres),0.001);        
            
            
            sig = 'x';
            if pci01(2) < 0.5 || pci01(1) > 0.5
                sig = '**';
            end
            if pci001(2) < 0.5 || pci001(1) > 0.5
                sig = '***';
            end
            
            if phat>0.5
                fprintf('Question %s was a right-hand (%.2f) %s\n',num2str(block),phat,char(sig));
            else
                fprintf('Question %s was a toe (%.2f) %s\n',num2str(block),phat,char(sig));
            end
            fprintf('Bounds for .01: %s\n',num2str(pci01));
            fprintf('Bounds for .001: %s\n',num2str(pci001));
%             
            bestaccu = [];
            sig = '';
            
%             bayesfactor(mean(currentdec),std(currentdec)/sqrt(length(currentdec)),mean(rhdecs),std(rhdecs)/sqrt(length(rhdecs)),mean(todecs),std(todecs)/sqrt(length(todecs)));            
            bayesfactor(mean(currentdec),std(currentdec,1)/sqrt(length(currentdec)),mean(rhdecs),std(rhdecs,1),mean(todecs),std(todecs,1));
            fprintf('Question with %s trials\n',num2str(length(currentres)));

%             bayesfactor(mean(currentdec),std(currentdec),mean(rhdecs),std(rhdecs),mean(todecs),std(todecs));            
            
        end
        return;
        
end

fprintf('\n');

switch char(bsloract)
    case 'action'
        plotcoeffs(AllCoeffs);
end

[phat, pci01] = binofit(sum(allaccs),length(allaccs),0.01);
[~, pci001] = binofit(sum(allaccs),length(allaccs),0.001);
bestaccu = phat*100;
sig = 'x';
if pci01(1) > 0.5
    sig = '**';
end
if pci001(1) > 0.5
    sig = '***';
end

fprintf('Mean classification accuracy for %s: %.1f %s across %s trials\n',EEG.setname,bestaccu,char(sig),num2str(length(allaccs)));
fprintf('Bounds for .01: %s\n',num2str(pci01));
fprintf('Bounds for .001: %s\n',num2str(pci001));

allchans = zeros(1,129);
allchans(origchan) = 1;
%badsinmotor = sum(and(allchans,EEG.rejchan));

%fprintf('%s channels interpolated\n',num2str(badsinmotor));