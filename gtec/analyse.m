function bestaccu = analyse(basename,filepath)

if ~exist('filepath','var')
    filepath = '';
end

rawfile = [filepath basename '.mat'];

if ~exist(rawfile,'file')
    error('File not found: %s\n', rawfile);
end

fprintf('Loading %s.\n',rawfile);
load(rawfile);

%% normalise number of channels!!
load('chanlocs_129.mat'); % matfile containing spf of 129-set plus corresponding sites on 257-cap

if size(Right_Hand,1) == 129
    
    fprintf('129-channels found...\n');
    AllData = cat(3, Right_Hand, Toes);
    
elseif size(Right_Hand,1) == 257;
    
    fprintf('257-channels found...\n');
    fprintf('Down-sampling to 129-channels...\n');
    AllData = cat(3, Right_Hand(elecs,:,:), Toes(elecs,:,:));
    
else
    
    error('There appears to be a problem with the number of channels in the data.  Make sure it''s 129 or 257...\n');
end

%% put into EEGLAB format

AllData_EEG = pop_importdata( 'dataformat', 'array', 'data', AllData, 'srate', samplingRate, 'pnts', size(AllData,2), 'nbchan', size(AllData,1), 'xmin', -1.5);
AllData_EEG.trials = size(AllData,3);

%% remove baseline

AllData_EEG_blc = pop_rmbase(AllData_EEG,[-500 0]);

%% Remove bad channels across both tasks

% [AllData_EEG_blc_chrej indxElec] = pop_rejchan(AllData_EEG_blc, 'elec', [1:129], 'threshold', 9, 'norm', 'off', 'measure', 'kurt');
% 
% % Keep track of channel indices left
% 
% newChans = setdiff(1:129,indxElec);

output = zeros(1,129);

for i = 1:129
    x = std(AllData_EEG_blc.data(i,:,:));
    y = mean(x);
    if y>50
        output(i) = 0;
    else
        output(i) = 1;
    end
end
output = logical(output);
fprintf('Rejecting %d bad channels: %s\n',129-sum(output),num2str(find(output == 0)));

if sum(output) < 25
    error('Not enough good channels!');
elseif sum(output) < 50
    fprintf('\nWARNING: Data is probably too noisy!\n\n');
end


newChans = find(output);

AllData_EEG_blc_chrej.data = AllData_EEG_blc.data(output,:,:);

%% Local average reference!!

% RH_EEG.data = reref(RH_EEG.data);
% TO_EEG.data = reref(TO_EEG.data);

numneighbours = 4;

goodchannels = newChans;

chanlocs = chanlocs(newChans,:);

[THETA PHI] = cart2sph(chanlocs(:,1),chanlocs(:,2),chanlocs(:,3));
chanlocs = radtodeg([PHI THETA]);

for chan = 1:length(goodchannels)
%     dist = pdist2(chanlocs(chan,:), chanlocs);
    dist = distance(chanlocs(chan,:),chanlocs);
    [~, sortidx] = sort(dist);
%     sortidx = subset(sortidx, chan);
%     sortidx = subset(sortidx, badchannels);
    neighbours = sortidx(2:numneighbours+1);
    AllData_EEG_blc_chrej.data(chan,:,:) = mean(AllData_EEG_blc_chrej.data(neighbours,:,:),1) - AllData_EEG_blc_chrej.data(chan,:,:);
end

%% separate back into two conditions

AllData_out = AllData_EEG_blc_chrej.data;

RH_EEG = pop_importdata( 'dataformat', 'array', 'data', AllData_out(:,:,1:size(Right_Hand,3)), 'srate', samplingRate, 'pnts', size(Right_Hand,2), 'nbchan', size(Right_Hand,1), 'xmin', -1.5);
RH_EEG.trials = size(Right_Hand,3);
RH_EEG.xmax = 3.996;
TO_EEG = pop_importdata( 'dataformat', 'array', 'data', AllData_out(:,:,size(Right_Hand,3)+1:end), 'srate', samplingRate, 'pnts', size(Toes,2), 'nbchan', size(Toes,1), 'xmin', -1.5);
TO_EEG.trials = size(Toes,3);
TO_EEG.xmax = 3.996;


%% Identify bad trials

% extreme values

% limits = [-100 100]; % in uV
% 
% RH_EEG = pop_eegthresh(RH_EEG,1, [1:size(RH_EEG.data,1)],limits(1),limits(2), RH_EEG.xmin, RH_EEG.xmax, 0, 0);
% TO_EEG = pop_eegthresh(TO_EEG,1, [1:size(TO_EEG.data,1)],limits(1),limits(2), TO_EEG.xmin, TO_EEG.xmax, 0, 1);

% Kurtosis

RH_EEG.stats.kurt = [];
RH_EEG.stats.kurtE = [];
TO_EEG.stats.kurt = [];
TO_EEG.stats.kurtE = [];

RH_EEG = pop_rejkurt(RH_EEG,1,1:size(RH_EEG.data,1), 5, 5, 0, 0);
TO_EEG = pop_rejkurt(TO_EEG,1,1:size(TO_EEG.data,1), 5, 5, 0, 0);

trials2keepRH = ~logical(RH_EEG.reject.rejkurt);
trials2keepTO = ~logical(TO_EEG.reject.rejkurt);


% Abnormal spectra

% RH_EEG = pop_rejspec(RH_EEG,1,1:size(RH_EEG.data,1), -25, 25, 1, 40, 0, 0);
% TO_EEG = pop_rejspec(TO_EEG,1,1:size(TO_EEG.data,1), -25, 25, 1, 40, 0, 0);

%% Reject bad trials

fprintf('Rejecting trials...\n');

RH_EEG.data = RH_EEG.data(:,:,trials2keepRH);
TO_EEG.data = TO_EEG.data(:,:,trials2keepTO);

RH_EEG.trials = size(RH_EEG.data,3);
TO_EEG.trials = size(TO_EEG.data,3);

%% send to LDA

bestaccu = auto_LDA(RH_EEG,TO_EEG,newChans,basename);

end

function bestaccu = auto_LDA(RH_EEG,TO_EEG,newChans,basename)

%% select motor area channels

origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];

chans2use = [];

for i = 1:length(origchan)
    
    chans2use = [chans2use find(newChans == origchan(i))];
    
end

RH_EEG.data = RH_EEG.data(chans2use,:,:);
RH_EEG.nbchan = length(chans2use);
TO_EEG.data = TO_EEG.data(chans2use,:,:);
TO_EEG.nbchan = length(chans2use);

%% quick and dirty power calculation

% filter

fprintf('Calculating features...\n');

RH_mu_Data = pop_eegfilt(RH_EEG,7,13,[],0,1);
TO_mu_Data = pop_eegfilt(TO_EEG,7,13,[],0,1);

RH_beta_Data = pop_eegfilt(RH_EEG,13,25,[],0,1);
TO_beta_Data = pop_eegfilt(TO_EEG,13,25,[],0,1);

RH_mu_Data.data = reshape(RH_mu_Data.data,size(RH_mu_Data.data,1),1375,size(RH_EEG.data,3));
TO_mu_Data.data = reshape(TO_mu_Data.data,size(TO_mu_Data.data,1),1375,size(TO_EEG.data,3));

RH_beta_Data.data = reshape(RH_beta_Data.data,size(RH_mu_Data.data,1),1375,size(RH_EEG.data,3));
TO_beta_Data.data = reshape(TO_beta_Data.data,size(TO_mu_Data.data,1),1375,size(TO_EEG.data,3));

% select first 2 seconds only after beep and square and log values

RH_mu_power = log(RH_mu_Data.data(:,376:875,:) .^2);
TO_mu_power = log(TO_mu_Data.data(:,376:875,:) .^2);

RH_beta_power = log(RH_beta_Data.data(:,376:875,:) .^2);
TO_beta_power = log(TO_beta_Data.data(:,376:875,:) .^2);

% smooth data

fprintf('Smoothing data to 50Hz.\n');

numsamples = 100;

smooth_RH_mu = zeros(size(RH_mu_power,1),numsamples,size(RH_mu_power,3));
smooth_RH_beta = zeros(size(RH_beta_power,1),numsamples,size(RH_beta_power,3));
smooth_TO_mu = zeros(size(TO_mu_power,1),numsamples,size(TO_mu_power,3));
smooth_TO_beta = zeros(size(TO_beta_power,1),numsamples,size(TO_beta_power,3));

for i = 1:numsamples

    smooth_RH_mu(:,i,:) = mean(RH_mu_power(:,i*5-4:i*5,:),2);
    smooth_RH_beta(:,i,:) = mean(RH_beta_power(:,i*5-4:i*5,:),2);
    
    smooth_TO_mu(:,i,:) = mean(TO_mu_power(:,i*5-4:i*5,:),2);
    smooth_TO_beta(:,i,:) = mean(TO_beta_power(:,i*5-4:i*5,:),2);
            
end

% create feature matrix

fprintf('Creating feature matrix.\n');

RH_features = cat(1,smooth_RH_mu,smooth_RH_beta);
TO_features = cat(1,smooth_TO_mu,smooth_TO_beta);

% equalise trials

RH_features = RH_features(:,:,1:min(size(RH_features,3),size(TO_features,3)));
TO_features = TO_features(:,:,1:min(size(RH_features,3),size(TO_features,3)));

features = zeros(size(RH_features,1),size(RH_features,2),size(RH_features,3) + size(TO_features,3));

% interleave trials, RH TO

features(:,:,1:2:end) = RH_features;
features(:,:,2:2:end) = TO_features;

classlabels = zeros(1,size(features,3));
classlabels(1:2:end) = 1;

% run classification

% CVchunksize = round(size(features,3)/20)*2;
CVchunksize = floor(size(features,3)/10);
runs = 1:CVchunksize:size(features,3);
% runs = [runs size(features,3)+1];

numsamples = size(features,2);
numfeatures = size(features,1);

fprintf('%d out of 50 possible features will be used...\n',numfeatures);

trainaccu = zeros(length(runs)-1,numsamples);
testaccu = zeros(length(runs)-1,numsamples);
WM = zeros(length(runs)-1,numsamples,numfeatures);
WV = zeros(length(runs)-1,numfeatures);

bestwvidx = zeros(length(runs)-1,1);

Interval = [5 5 100];
out_x = Interval(1):Interval(2):Interval(3);

smoothwin = 0.2;
smoothwin = smoothwin .* 250;
smoothwin = find(out_x(1,:) - out_x(1,1) < smoothwin, 1, 'last');

fprintf('Running 10-fold cross validation over %d trials: fold   ', size(features,3));

for run = 1:length(runs)-1
    fprintf('\b\b%02d', run);
    
    %% train classifier
    for t = 1:numsamples
        trainfeatures = squeeze(features(:,t,:));
        trainfeatures = trainfeatures(:,setdiff(1:size(features,3),runs(run):runs(run+1)-1));
        trainlabels = classlabels(setdiff(1:size(features,3),runs(run):runs(run+1)-1));
        
        trainfeatures = trainfeatures';
        trainlabels = trainlabels';
        
        [b,~,~,inmodel] = stepwisefit(trainfeatures,trainlabels,'display','off');
        WM(run,t,:) = b'.*inmodel;

%         b = regress(trainlabels,trainfeatures);
%         WM(run,t,:) = b';
            
        trainres = trainfeatures * squeeze(WM(run,t,:));
        trainaccu(run,t) = (sum(~xor(trainres > 0, trainlabels > 0))/length(trainlabels)) * 100;
        
    end
    
    %smoothing window average
    smooth_accu = zeros(size(trainaccu(run,:)));
    for t = 1:numsamples
        swstart = max(1,t-floor(smoothwin/2));
        swstop = min(t+floor(smoothwin/2),size(trainaccu,2));
        smooth_accu(1,t) = mean(trainaccu(run,swstart:swstop),2);
    end
    trainaccu(run,:) = smooth_accu;
        
    [~, bestidx] = max(trainaccu(run,:),[],2);
    bestwvidx(run,1) = bestidx;
    WV(run,:) = squeeze(WM(run,bestwvidx(run,1),:))';
    %fprintf('Best classifier found at time %.1fs.\n', out_x(1,targetwinidx(bestidx)) - (P_C_S.PreTrigger / P_C_S.SamplingFrequency));
    
    %% test classifier
    for t = 1:numsamples
        testfeatures = squeeze(features(:,t,:));
        testfeatures = testfeatures(:,runs(run):runs(run+1)-1)';
        testlabels = classlabels(runs(run):runs(run+1)-1)';
        testres = testfeatures * squeeze(WM(run,t,:));
        testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
    end
    
    %smoothing window average
    smooth_accu = zeros(size(testaccu(run,:)));
    for t = 1:numsamples
        swstart = max(1,t-floor(smoothwin/2));
        swstop = min(t+floor(smoothwin/2),size(testaccu,2));
        smooth_accu(1,t) = mean(testaccu(run,swstart:swstop),2);
    end
    testaccu(run,:) = smooth_accu;
    finalaccu = mean(testaccu,1);
    
    
end
fprintf('\n');

bestaccu = max(finalaccu);
fprintf('\nBEST ACCURACY: %.1f\n\n',bestaccu);

% fprintf('Plotting classifier performance.\n');
% ylim = [50 100];
% scrsize = get(0,'ScreenSize');
% fsize = [1000 660];
% figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
%     'Name',basename,'NumberTitle','off');
% x=1:20:2000; %(out_x(1,:) - P_C_S.PreTrigger) * (1/P_C_S.SamplingFrequency);
% y=finalaccu;
% a=axes;
% 
% plot(x,y,'Parent',a,'Marker','.','LineWidth',3);
% set(a,'YLim',ylim);
% set(a,'XLim',[x(1) x(end)]);
% 
% line([0 0],[0 ylim(2)],'Color','black');
% ylabel('Accuracy (%)');
% xlabel('Time (ms)');
% title(sprintf('Single-trial classification accuracy for %s', basename), 'Interpreter', 'none');
% grid on
% 
% maximumX=max(get(a,'XLim'));
% minimumX=min(get(a,'XLim'));
% line([minimumX maximumX],[90 90],'Color','green');
% line([minimumX maximumX],[70 70],'Color','yellow');
% text(maximumX+40,91,'EXCELLENT','Rotation',90);
% text(maximumX+40,78,'GOOD','Rotation',90);
% text(maximumX+40,55,'MORE TRAINING','Rotation',90);


end