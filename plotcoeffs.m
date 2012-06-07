function plotcoeffs(AllCoeffs)

loadpaths

splinefile = '129_spline.spl';

origchan = sort([6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129],'ascend');
meancoeffRH = [];
meancoeffTO = [];
tp = [];
for i = 1:length(AllCoeffs)
    
    currentb = AllCoeffs{i};
    rhtrials = find(currentb.GroupNames(currentb.SupportVectorIndices));
    totrials = find(currentb.GroupNames(currentb.SupportVectorIndices) == 0);
    
    currentvectors = currentb.SupportVectors;
    
    %     rhvectors = currentvectors(rhtrials,:);
    %     tovectors = currentvectors(totrials,:);
    %
    %     rhvectors = rhvectors' * currentb.Alpha(rhtrials);
    %     tovectors = tovectors' * currentb.Alpha(totrials);
    %
    %     rhvectors = rhvectors - tovectors;
    %
    %
    
    rhvectors = currentvectors' * currentb.Alpha;
    
    [~, sortidx] = sort(rhvectors,'descend');
    
    num2use = 1;
    
    
    % %     rhvectors = reshape(rhvectors,size(rhvectors,1),100,300);
    % %     rhvectors = reshape(rhvectors,size(rhvectors,1),25,4*300);
    % %
    % %     tovectors = reshape(tovectors,size(tovectors,1),100,300);
    % %     tovectors = reshape(tovectors,size(tovectors,1),25,4*300);
    %
    %     rhvectors = reshape(rhvectors,300,100);
    %     tovectors = reshape(tovectors,300,100);
    
    %     rhvectors = currentvectors' * currentb.Alpha;
    
    %     [~,xmax] = max(abs(rhvectors));
    %
    tp = [];
    freqband = [];
    for num = 1:num2use
        
        tp(num) = ceil(sortidx(num)/100);
        remfeat = rem(sortidx(num),100);
        freqband(num) = rem(remfeat,4);
        
        if freqband(num) == 0
            freqband(num) = 4;
        end
        
    end
    
    rhvectors = reshape(rhvectors,4,25,300);
    rhvectors = rhvectors(unique(freqband),:,unique(tp));
    
    rhvectors = permute(rhvectors,[1 3 2]);
    rhvectors = reshape(rhvectors,size(rhvectors,1)*size(rhvectors,2),25);
    
    
    %
    % %     tovectors = reshape(tovectors,4,25,300);
    % %     tovectors = permute(tovectors,[1 3 2]);
    % %     tovectors = reshape(tovectors,300*4,25);
    % %
    %     [maxfeats,fmax] = min(abs(rhvectors));
    %
    %     [~,fmaxmax] = max(maxfeats);
    % %     fmaxmax = 8;
    %     rhvectors = rhvectors(fmax(fmaxmax),:);
    %         rhvectors = mean(rhvectors(fmax,:),1);
    
    
    %     rhvectors = rhvectors(freqband,:,tp(i));
    %     rhvectors = permute(rhvectors,[1 3 2]);
    %     tovectors = reshape(tovectors,4,25,300);
    %     tovectors = permute(tovectors,[1 3 2]);
    %
    %     rhvectors = reshape(rhvectors,300*4,25);
    %     tovectors = reshape(tovectors,300*4,25);
    %         for k = 1:size(rhvectors,3)
    %             rhvectors = (rhvectors - mean(rhvectors)) / std(rhvectors);
    %         end
    
    
    for j = 1:size(rhvectors,1)
        %         for k = 1:size(rhvectors,3)
        rhvectors(j,:) = (rhvectors(j,:) - mean(rhvectors(j,:))) / std(rhvectors(j,:));
        %         end
    end
    
    rhvectors = mean(rhvectors,1);
    %
    %     for j = 1:size(tovectors,1)
    % %         for k = 1:size(tovectors,3)
    %             tovectors(j,:) = (tovectors(j,:) - mean(tovectors(j,:))) / std(tovectors(j,:));
    % %         end
    %     end
    
    %     [x, xmax] = max(abs(rhvectors));
    %     [maxx, xmaxx] = max(x);
    %
    %     meanRH = rhvectors(xmax(xmaxx),:);
    %
    %     [x, xmax] = max(abs(tovectors));
    %     [maxx, xmaxx] = max(x);
    %
    %     meanTO = tovectors(xmax(xmaxx),:);
    
    
    %     meanRH = squeeze(mean(rhvectors,1));
    %     meanTO = squeeze(mean(tovectors,1));
    
    %     meanRH = reshape(meanRH,25,4)';
    %     meanTO = reshape(meanTO,25,4)';
    
    
    meancoeffRH = [meancoeffRH; rhvectors];
    %     meancoeffTO = [meancoeffTO; meanTO];
    
    
    
end


plotchansRH = zeros(1,129);
% plotchansTO = zeros(1,129);

plotchansRH(origchan) = mean(meancoeffRH,1);
% plotchansTO(origchan) = mean(meancoeffTO,1);

% save 'plotchanssvm.mat' plotchansRH;

figure('Color','white');
subplot(1,2,1);
headplot(plotchansRH,[chanlocpath splinefile],'electrodes','off','view',[0 90]);
subplot(1,2,2);
headplot(plotchansRH,[chanlocpath splinefile],'electrodes','off','view',[-136 44]); zoom(1.5);
%
% figure;
% subplot(1,2,1);
% headplot(plotchansTO,'129_spline.spl','electrodes','off','view',[-136 44]);
% subplot(1,2,2);
% headplot(plotchansTO,'129_spline.spl','electrodes','off','view',[0 90]);
