function [bestaccu,siglevel] = csplda(basename,TrainTestMethod,TrainInfo)

loadpaths;

if ~exist('TrainInfo','var')
    TrainInfo = [];
end

%% Load Data
fprintf('Loading %s.set\n', basename);
EEG = pop_loadset('filepath',filepath,'filename',[basename '.set']);
fprintf('Found %d trials, %d samples, %d channels.\n', EEG.trials, EEG.pnts, EEG.nbchan);

if EEG.nbchan == 257
    EEG.chanlocs = pop_readlocs([chanlocpath 'GSN-HydroCel-257.sfp']);
    EEG.chanlocs = EEG.chanlocs(4:end);
    load ELECS.mat
    EEG = pop_select(EEG,'channel',keepchan);
elseif EEG.nbchan == 129
    EEG.chanlocs = pop_readlocs([chanlocpath 'GSN-HydroCel-129.sfp']);
    EEG.chanlocs = EEG.chanlocs(4:end);
end
EEG.origlocs = EEG.chanlocs;

%% downsample data
newRate = 100;
fprintf('Downsampling data to %sHz...\n',num2str(newRate));
EEG = pop_resample(EEG, newRate);
EEG.setname = basename;

%% Channels to use for analyses
%25 channels for spectral analysis
%origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
%41 channels for CSP analysis
origchan = [6    7   13   20   28   29   30   31   34   35   36   37   40   41   42   46   47   52   53   54   55   79   80   86   87   92   93   98  102  103  104  105  106  109  110  111  112  116  117  118  129];
EEG = pop_select(EEG,'channel',origchan);

%time and frequency windows for analysis
timewin = [0.5 1.5];
freqwin = [7 30];

%% Filter
EEG = pop_eegfiltnew(EEG,freqwin(1),0);
EEG = pop_eegfiltnew(EEG,0,freqwin(2));
EEG.data = reshape(EEG.data,EEG.nbchan,EEG.pnts,EEG.trials);

% fullmodel = csp_calc(EEG,struct('patterns',4,'timewin',timewin));
% csp_visualize([],fullmodel);
% save(sprintf('%s_csp.mat',basename),'fullmodel');


%% Select classes
classtype = zeros(1,EEG.trials);
blocktrial = zeros(1,EEG.trials);

if strcmp(TrainTestMethod,'test')
    for t = 1:EEG.trials
        classtype(t) = strcmp(EEG.event(t).type,'QUES');    % 1 = RH, 0 = TO;
        blocktrial(t) = EEG.event(t).bnum;
    end
else
    for t = 1:EEG.trials
        classtype(t) = strcmp(EEG.event(t).type,'RIGHTHAND');    % 1 = RH, 0 = TO;
        blocktrial(t) = EEG.event(t).bnum;
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
        
        
        fprintf('Testing trials %s.\n', num2str(testtrials));
        
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
        
        save([basename '_csp_train.mat'],'b', 'meanfeats','stdfeats', 'nb','alldecisions','alllabels');
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
        
        
        AllCoeffs = {};
        allaccs = [];
        
        alllabels = [];
        alldecisions = [];
        alltrialnums = [];
        allmodels = [];
        
        for run = 1:length(blocknums)
            traintrials = [];
            trainblocks = setdiff(blocknums,run);
            
            for j = 1:length(trainblocks)
                traintrials = [traintrials find(blocktrial == trainblocks(j))];
            end
            
            testtrials = find(blocktrial == blocknums(run));
            trainlabels = classtype(traintrials)';
            testlabels = classtype(testtrials)';
                        
            trainEEG = pop_select(EEG,'trial',traintrials);
            
            %CALCULATE CSP FILTERS
            fprintf('\nCalculating spatial filters.\n');
            cspmodel = csp_calc(trainEEG,struct('patterns',3,'timewin',timewin));
%             cspmodel = speccsp_calc(trainEEG,struct('patterns',3,'timewin',timewin,...
%                 'prior',freqwin,'pp',0,'qp',1,'steps',3));
            

            %SELECT APPROPRIATE FILTERS
            %             keepfilt = [1:cspmodel.numfilt size(cspmodel.filters,2):-1:size(cspmodel.filters,2)-cspmodel.numfilt+1];
            [~, filtidx] = sort(cspmodel.filterscores);
            keepfilt = filtidx([1:cspmodel.numfilt length(filtidx):-1:length(filtidx)-cspmodel.numfilt+1])';
            fprintf('\nSelecting filters %s.\n',num2str(keepfilt));

            %VISUALIZE CSPs
            csp_visualize([],cspmodel,keepfilt,EEG.origlocs);
            %speccsp_visualize([],cspmodel,keepfilt);
            saveas(gcf,sprintf('figures/%s_csp%d.fig',basename,run));
            close(gcf);
            
            %APPLY FILTERS
            fprintf('\nApplying spatial filters.\n');
            cspEEG = csp_apply(EEG,cspmodel);
%             cspEEG = speccsp_apply(EEG,cspmodel);

            %KEEP SELECTED FILTERS
            cspEEG = pop_select(cspEEG,'channel',keepfilt);
            
            %cspEEG = pop_resample(cspEEG,10);
            
            %CONCATENATE FILTER-WISE FEATURES
            cspEEG = concatfeats(cspEEG,[cspEEG.xmin cspEEG.xmax]);

            features = cspEEG.data;
            
            fprintf('\nTesting trials %d-%d with %d features.\n', testtrials(1),testtrials(end),size(features,1));
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
            allmodels = [allmodels cspmodel];
            
        end
        
        uniquetrialnums = unique(alltrialnums);
        numtrialnums = [];
        numaccstrialnums = [];
        
        save([basename '_csp_cv.mat'],'allmodels','alldecisions','alllabels');
        
        for ut = 1:length(uniquetrialnums)
            numtrialnums(ut) = length(find(alltrialnums == uniquetrialnums(ut)));
            numaccstrialnums(ut) = sum(allaccs(find(alltrialnums == uniquetrialnums(ut))));
            
        end
        
        %         fprintf('\n%s\n',num2str(uniquetrialnums));
        %         fprintf('\n%s\n',num2str(numtrialnums));
        %         fprintf('\n%s\n',num2str(numaccstrialnums));
        
        
    case 'train'
        
        AllCoeffs = {};
        allaccs = [];
        
        traintrials = 1:size(features,3);
        testtrials = traintrials;
        trainlabels = classtype(traintrials)';
        testlabels = classtype(testtrials)';
        
        
        fprintf('Testing trials %s.\n', num2str(testtrials));
        
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
        
        save([basename '_csp_train.mat'],'b', 'meanfeats','stdfeats', 'nb', 'alldecisions','alllabels');
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
            
            
            siglevel = 'x';
            if pci01(2) < 0.5 || pci01(1) > 0.5
                siglevel = '**';
            end
            if pci001(2) < 0.5 || pci001(1) > 0.5
                siglevel = '***';
            end
            
            if phat>0.5
                fprintf('Question %s was a right-hand (%.2f) %s\n',num2str(block),phat,char(siglevel));
            else
                fprintf('Question %s was a toe (%.2f) %s\n',num2str(block),phat,char(siglevel));
            end
            fprintf('Bounds for .01: %s\n',num2str(pci01));
            fprintf('Bounds for .001: %s\n',num2str(pci001));
            %
            bestaccu = [];
            siglevel = '';
            
            %             bayesfactor(mean(currentdec),std(currentdec)/sqrt(length(currentdec)),mean(rhdecs),std(rhdecs)/sqrt(length(rhdecs)),mean(todecs),std(todecs)/sqrt(length(todecs)));
            bayesfactor(mean(currentdec),std(currentdec,1)/sqrt(length(currentdec)),mean(rhdecs),std(rhdecs,1),mean(todecs),std(todecs,1));
            fprintf('Question with %s trials\n',num2str(length(currentres)));
            
            %             bayesfactor(mean(currentdec),std(currentdec),mean(rhdecs),std(rhdecs),mean(todecs),std(todecs));
            
        end
        return;
        
end

fprintf('\n');

cvresults = alldecisions';
labels = ~alllabels';

%rocdata = rocanalysis([cvresults labels]);
rocdata.co = 0.5;

hidx = (cvresults(labels == 1) > rocdata.co);
hrate = (sum(hidx)+1)/(length(hidx)+2);
faidx = (cvresults(labels == 0) > rocdata.co);
farate = (sum(faidx)+1)/(length(faidx)+2);

dprime = norminv(hrate) - norminv(farate);
[cvaccu cvaccuci] = binofit(sum(hidx)+sum(~faidx),length(hidx)+length(faidx));
cvaccu = cvaccu * 100; cvaccuci = cvaccuci * 100;

result.cvresults = cvresults;
result.labels = labels;
result.cvaccu = cvaccu;
result.cvaccuci = cvaccuci;
result.dprime = dprime;
result.criterion = rocdata.co;
result.hitrate = hrate;
result.farate = farate;

[phat, pci01] = binofit(sum(hidx)+sum(~faidx),length(hidx)+length(faidx),0.01);
[~, pci001] = binofit(sum(hidx)+sum(~faidx),length(hidx)+length(faidx),0.001);
bestaccu = phat*100;
siglevel = ' ';
if pci01(1) > 0.5
    siglevel = '**';
end
if pci001(1) > 0.5
    siglevel = '***';
end

fprintf('\nMean classification accuracy for %s: %.1f %s across %s trials\n',EEG.setname,bestaccu,char(siglevel),num2str(length(allaccs)));
fprintf('Bounds for .01: %s\n',num2str(pci01));
fprintf('Bounds for .001: %s\n',num2str(pci001));
fprintf('D''=%.2f, Criterion=%.2f\n',result.dprime,result.criterion);

allchans = zeros(1,129);
allchans(origchan) = 1;
%badsinmotor = sum(and(allchans,EEG.rejchan));

%fprintf('%s channels interpolated\n',num2str(badsinmotor));

end


function cspmodel = csp_calc(data,args)
evtypes = {'RIGHTHAND','TOES'};

if data.nbchan == 1
    error('CSP does intrinsically not support single-channel data (it is a spatial filter).'); end
if data.nbchan < args.patterns
    error('CSP prefers to work on at least as many channels as you request output patterns. Please reduce the number of pattern pairs.'); end
for k=1:2
    trials{k} = pop_selectevent(data,'type',evtypes{k});
    trials{k} = pop_select(trials{k},'time',args.timewin);
    covar{k} = cov(reshape(trials{k}.data,size(trials{k}.data,1),[])');
    covar{k}(~isfinite(covar{k})) = 0;
end

[V,D] = eig(covar{1},covar{1}+covar{2});
if ~isreal(V)
    warning('csp_calc:ComplexEig','Complex values found in eigenvector solution.');
    V = real(V);
end
cspmodel.filters = V;
cspmodel.patterns = inv(V);
cspmodel.filterscores = csp_scorefilter(data,cspmodel);
cspmodel.chanlocs = data.chanlocs;
cspmodel.numfilt = 3;
cspmodel.timewin = args.timewin;
end


% visualize a CSP cspmodel
function csp_visualize(parent,cspmodel,filtidx,chanlocs)

loadpaths

%chanexcl = [1,8,14,17,21,25,32,38,43,44,48,49,56,57,63,64,68,69,73,74,81,82,88,89,94,95,99,100,107,113,114,119,120,121,125,126,127,128];
chanexcl = [];

chanlocs = chanlocs(setdiff(1:length(chanlocs),chanexcl));

[~,diffidx] = setdiff({chanlocs.labels},{cspmodel.chanlocs.labels});
setidx = setdiff(1:length(chanlocs),diffidx);

% no parent: create new figure
if isempty(parent)
    parent = figure('Name','Common Spatial Patterns'); end

% number of pairs, and index of pattern per subplot
%idx = [1:cspmodel.numfilt size(cspmodel.filters,2):-1:size(cspmodel.filters,2)-cspmodel.numfilt+1];

np = length(filtidx)/2;
idx = [1:np 2*np:-1:np+1];

% for each CSP pattern...
for p=1:length(filtidx)
    subplot(2,np,idx(p),'Parent',parent);
    plotinfo = zeros(1,length(chanlocs));
    plotinfo(setidx) = cspmodel.patterns(filtidx(p),:);
    plotinfo(diffidx) = 0;
    topoplot(plotinfo,chanlocs,'style','map','conv','on','electrodes','off');
    title(sprintf('Pattern %d (%.2f)', filtidx(p), cspmodel.filterscores(filtidx(p))));
end
end


function FilterScores = csp_scorefilter(data,cspmodel)

numfilters = size(cspmodel.filters,2);
FilterScores = zeros(numfilters,1);

[~, rhtrials] = pop_selectevent(data,'type','RIGHTHAND');
[~, totrials] = pop_selectevent(data,'type','TOES');
trialcount = data.trials;

for filter = 1:size(cspmodel.filters,2)
    vars = zeros(1,trialcount);
    for trial = 1:data.trials
        thistrial = data.data(:,:,trial);
        vars(trial) = cspmodel.filters(:,filter)' * (thistrial * thistrial') * cspmodel.filters(:,filter);
    end
    FilterScores(filter) = median(vars(rhtrials)) / ...
        (median(vars(rhtrials)) + median(vars(totrials)));
    %fprintf('Filter %d got a score of %.2f\n', filter,score(filter));
end
end


% extract csp-filtered log-variance features
function data = csp_apply(data,cspmodel)

swsize = 0.5; %seconds

data = pop_select(data,'time',[cspmodel.timewin(1) cspmodel.timewin(2)+swsize-1/data.srate]);

data.data = reshape(cspmodel.filters' * reshape(data.data,data.nbchan,data.pnts*data.trials),...
    size(cspmodel.filters,2),data.pnts,data.trials);

data = movingvar(data,swsize);
data.data = log(data.data);
end


% compute the Spec-CSP feature space
function cspmodel = speccsp_calc(data,args)

if data.nbchan == 1
    error('Spec-CSP does intrinsically not support single-channel data (it is a spatial filter).'); end
if data.nbchan < args.patterns
    error('Spec-CSP prefers to work on at least as many channels as you request output patterns. Please reduce the number of pattern pairs.'); end
[n_of,pp,qp,prior,steps,timewin] = deal(args.patterns,args.pp,args.qp,args.prior,args.steps,args.timewin);
% read a few parameters from the options (and re-parameterize the hyper-parameters p' and q' into p and q)
p = pp+qp;
q = qp;
if isnumeric(prior) && length(prior) == 2
    prior = @(f) f >= prior(1) & f <= prior(2); end

evtypes = {'RIGHTHAND','TOES'};

% preprocessing
for c=1:2
    % compute the per-class epoched data X and its Fourier transform (along time), Xfft
    X{c} = pop_selectevent(data,'type',evtypes{c});
    X{c} = pop_select(X{c},'time',timewin);
    
    % number of C=Channels, S=Samples and T=Trials #ok<NASGU>
    [C,S,T] = size(X{c}.data);
    % build a frequency table (one per DFT bin)
    freqs = (0:S-1)*X{c}.srate/S;
    % evaluate the prior I
    I = prior(freqs);
    % and find table indices that are supported by the prior
    bands = find(I);
    
    Xfft{c} = fft(X{c}.data,[],2);
    % the full spectrum F of covariance matrices per every DFT bin and trial of the data
    F{c} = single(zeros(C,C,max(bands),T));
    for k=bands
        for t=1:T
            F{c}(:,:,k,t) = 2*real(Xfft{c}(:,k,t)*Xfft{c}(:,k,t)'); end
    end
    % compute the cross-spectrum V as an average over trials
    V{c} = mean(F{c},4);
end

% 1. initialize the filter set alpha and the number of filters J
J = 1; alpha{J}(bands) = 1;
% 2. for each step
for step=1:steps
    % 3. for each set of spectral coefficients alpha{j} (j=1,...,J)
    for j=1:J
        % 4. calculate sensor covariance matrices for each class from alpha{j}
        for c = 1:2
            Sigma{c} = zeros(C);
            for b=bands
                Sigma{c} = Sigma{c} + alpha{j}(b)*V{c}(:,:,b); end
        end
        % 5. solve the generalized eigenvalue problem Eq. (2)
        [VV,DD] = eig(Sigma{1},Sigma{1}+Sigma{2});
        % and retain n_of top eigenvectors at both ends of the eigenvalue spectrum...
        W{j} = {VV(:,1:ceil(size(VV,2)/2)), VV(:,ceil(size(VV,2)/2)+1:end)};
        iVV = inv(VV)'; P{j} = {iVV(:,1:ceil(size(VV,2)/2)), iVV(:,ceil(size(VV,2)/2)+1:end)};
        % as well as the top eigenvalue for each class
        lambda(j,:) = [DD(1), DD(end)];
    end
    % 7. set W{c} from all W{j}{c} such that lambda(j,c) is minimal/maximal over j
    W = {W{argmin(lambda(:,1))}{1}, W{argmax(lambda(:,2))}{2}};
    P = {P{argmin(lambda(:,1))}{1}, P{argmax(lambda(:,2))}{2}};
    % 8. for each projection w in the concatenated [W{1},W{2}]...
    Wcat = [W{1} W{2}]; J = size(VV,2);
    Pcat = [P{1} P{2}];
    for j=1:J
        w = Wcat(:,j);
        % 9. calcualate (across trials within each class) mean and variance of the w-projected cross-spectrum components
        for c=1:2
            % part of Eq. (3)
            s{c} = zeros(size(F{c},4),max(bands));
            for k=bands
                for t = 1:size(s{c},1)
                    s{c}(t,k) = w'*F{c}(:,:,k,t)*w; end
            end
            mu_s{c} = mean(s{c});
            var_s{c} = var(s{c});
        end
        % 10. update alpha{j} according to Eqs. (4) and (5)
        for c=1:2
            for k=bands
                % Eq. (4)
                alpha_opt{c}(k) = max(0, (mu_s{c}(k)-mu_s{3-c}(k)) / (var_s{1}(k) + var_s{2}(k)) );
                % Eq. (5), with prior from Eq. (6)
                alpha_tmp{c}(k) = alpha_opt{c}(k).^q * (I(k) * (mu_s{1}(k) + mu_s{2}(k))/2).^p;
            end
        end
        % ... as the maximum for both classes
        alpha{j} = max(alpha_tmp{1},alpha_tmp{2});
        % and normalize alpha{j} so that it sums to unity
        alpha{j} = alpha{j} / sum(alpha{j});
    end
end
alpha = [vertcat(alpha{:})'; zeros(S-length(alpha{1}),length(alpha))];
cspmodel = struct('filters',{Wcat},'patterns',{Pcat},'alpha',{alpha},'freqs',{freqs},...
    'bands',{bands},'chanlocs',{data.chanlocs},'timewin',{timewin},'numfilt',{n_of});
cspmodel.filterscores = speccsp_scorefilter(data,cspmodel);
end


% extract csp-filtered log-variance features
function data = speccsp_apply(data,cspmodel)

swsize = 0.5; %seconds

data = pop_select(data,'time',cspmodel.timewin);

data.data = reshape(cspmodel.filters' * reshape(data.data,data.nbchan,data.pnts*data.trials),...
    size(cspmodel.filters,2),data.pnts,data.trials);

for t = 1:size(data.data,3)
    data.data(:,:,t) = 2*real(ifft(cspmodel.alpha'.*fft(data.data(:,:,t),[],2),[],2));
end

data = movingvar(data,swsize);
data.data = log(data.data);
end


% visualize a Spec-CSP cspmodel
function speccsp_visualize(parent,cspmodel,filtidx)

loadpaths

chanexcl = [1,8,14,17,21,25,32,38,43,44,48,49,56,57,63,64,68,69,73,74,81,82,88,89,94,95,99,100,107,113,114,119,120,121,125,126,127,128];

chanlocfile = 'GSN-HydroCel-129.sfp';
chanlocs = pop_readlocs([chanlocpath chanlocfile]);
chanlocs = chanlocs(setdiff(1:length(chanlocs),chanexcl));

[~,diffidx] = setdiff({chanlocs.labels},{cspmodel.chanlocs.labels});
setidx = setdiff(1:length(chanlocs),diffidx);

% no parent: create new figure
if isempty(parent)
    parent = figure('Name','Common Spatial Patterns'); end

% number of pairs, and index of pattern per subplot
np = length(filtidx)/2; idxp = [1:np np+(2*np:-1:np+1)]; idxf = [np+(1:np) 2*np+(2*np:-1:np+1)];

% for each CSP pattern...
for p=1:length(filtidx)
    pidx = filtidx(p);
    subplot(4,np,idxp(p),'Parent',parent);
    plotinfo(setidx) = cspmodel.patterns(:,pidx);
    plotinfo(diffidx) = 0;
    topoplot(plotinfo,chanlocs); set(gca,'CameraViewAngle',4.7);
    subplot(4,np,idxf(p),'Parent',parent);
    alpha = cspmodel.alpha(:,pidx);
    range = min(find(alpha)):max(find(alpha)); %#ok<MXFND>
    plot(cspmodel.freqs(range),cspmodel.alpha(range,p));
    set(gca,'XLim',[cspmodel.freqs(range(1)) cspmodel.freqs(range(end))]);
    title(sprintf('Spec-CSP Pattern %d (%.2f)',pidx,cspmodel.filterscores(pidx)));
end
end

function FilterScores = speccsp_scorefilter(data,cspmodel)

numfilters = size(cspmodel.filters,2);
FilterScores = zeros(numfilters,1);

[~, rhtrials] = pop_selectevent(data,'type','RIGHTHAND');
[~, totrials] = pop_selectevent(data,'type','TOES');
trialcount = data.trials;

data.data = reshape(cspmodel.filters' * reshape(data.data,data.nbchan,data.pnts*data.trials),...
    size(cspmodel.filters,2),data.pnts,data.trials);

data = pop_select(data,'time',cspmodel.timewin);

for filter = 1:size(cspmodel.filters,2)
    vars = zeros(1,trialcount);
    for trial = 1:data.trials
        thistrial = 2*real(ifft(cspmodel.alpha(:,filter)'.*fft(data.data(filter,:,trial),[],2),[],2));
        vars(trial) = thistrial * thistrial';
    end
    FilterScores(filter) = median(vars(rhtrials)) / ...
        (median(vars(rhtrials)) + median(vars(totrials)));
    %fprintf('Filter %d got a score of %.2f\n', filter,score(filter));
end
end