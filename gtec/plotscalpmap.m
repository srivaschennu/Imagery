function plotscalpmap(basename,freqrange)

loadpaths

datafile = [filepath basename '.mat'];
class_names = {'RIGHTHAND';'TOES'};

%% Load Data
fprintf('Loading %s.\n', datafile);
load(datafile);

%% Cut out all channels except the ones required
if length(P_C_S.Channels) == 129
    origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
    montagefile = [montagepath 'GSN-HydroCel-129.sfp'];
    splinefile = [montagepath '129_spline.spl'];
elseif length(P_C_S.Channels) == 257
    origchan = [8    9   17   43   44   45   51   52   53   58   59   60   64   65   66   71   72   78   79   80   81   89   90  130  131  132  143  144  154  155  164  173  181  182  183  184  185  186  194  195  196  197  198  257];
    montagefile =[montagepath 'GSN-HydroCel-257.sfp'];
    splinefile = [montagepath '257_spline.spl'];
end
chanlocs = readlocs(montagefile,'filetype','sfp');

[~, badchannels] = findbadtrialschannels(P_C_S);
goodchannels = setdiff(origchan,badchannels);

fprintf('Rejecting bad channels: %s.\n', num2str(intersect(origchan,badchannels)));
TrialExclude=[];
ChannelExclude = goodchannels;
ChannelExclude = setdiff(1:P_C_S.NumberChannels,ChannelExclude);
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

% if ~exist('freqranges','var')
%     freqranges = [
%         7 12
%         12 15
%         15 19
%         19 25
%         ];
% end

refwin = [-0.5 0];
actwin = [0 2];

for l=1:length(class_names)
    
    
    trial_id=find(strcmp(class_names{l},P_C_S.AttributeName));
    channel_id=[];
    type_id=[];
    channelnr_id=[];
    flag_tr='tr_exc';
    flag_ch='ch_exc';
    flag_type='type_exc';
    flag_nr='nr_exc';
    [TrialExclude, ChannelExclude]=gBSselect(P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
    
    y = P_C_S.Data;
    y = permute(y,[3 2 1]);
    y = y(:,:,TrialExclude);
    %     RefBegin=250;
    %     IntervalLength=125;
    %     Window='hanning';
    %     DownSampling=0;
    %     FileName='';
    %     S_O=gBSspectrum(P_C_S,ActionBegin,RefBegin,IntervalLength,Window,DownSampling,TrialExclude,ChannelExclude,FileName,0);
    %     freqs = (1:length(S_O.pxx_reference)).*S_O.deltafrequency;
    %     fidx = find(freqs <= freqrange(1),1,'last'):find(freqs <= freqrange(2),1,'last');
    %     pref = S_O.pxx_reference;
    %     pref = squeeze(pref)';
    %     pref = mean(pref(:,fidx),2);
    %
    %     ActionBegin=375;
    %     RefBegin=[];
    %     IntervalLength=500;
    %     Window='hanning';
    %     DownSampling=0;
    %     FileName='';
    %     S_O=gBSspectrum(P_C_S,ActionBegin,RefBegin,IntervalLength,Window,DownSampling,TrialExclude,ChannelExclude,FileName,0);
    %     freqs = (1:length(S_O.pxx_action)).*S_O.deltafrequency;
    %     fidx = find(freqs <= freqrange(1),1,'last'):find(freqs <= freqrange(2),1,'last');
    %     pact = S_O.pxx_action;
    %     pact = squeeze(pact)';
    %     pact = mean(pact(:,fidx),2);
    
    pref = zeros(size(y,1),size(y,3));
    pact = zeros(size(y,1),size(y,3));
    
    for c = 1:length(P_C_S.Channels)
        
        [~,~,~,timesout,freqs,~,~,tfdata] = newtimef(y(c,:,:), P_C_S.PreTrigger+P_C_S.PostTrigger,...
            [-P_C_S.PreTrigger P_C_S.PostTrigger]*(1000/P_C_S.SamplingFrequency), P_C_S.SamplingFrequency,...
            0, 'padratio', 4, 'plotersp', 'off', 'plotitc', 'off');
        timesout = timesout./1000;
        tfdata = abs(tfdata).^2;
        
        %damian's windows
        %         refidx = 23:44;
        %         actidx = 45:133;
        refidx = find(timesout <= refwin(1),1,'last'):find(timesout <= refwin(2),1,'last');
        actidx = find(timesout <= actwin(1),1,'last'):find(timesout <= actwin(2),1,'last');
        fidx = find(freqs <= freqrange(1),1,'last'):find(freqs <= freqrange(2),1,'last');
        
        pref(c,:) = squeeze(mean(mean(tfdata(fidx,refidx,:),1),2));
        pact(c,:) = squeeze(mean(mean(tfdata(fidx,actidx,:),1),2));
    end
    
    %calculate log power ratios per channel and trial
    lpratio = log(pact./pref);

    %average across trials
    lpratio = mean(lpratio,2);

    %adjust values to zero mean
    if mean(lpratio) > 0
        lpratio = lpratio - mean(lpratio);
    elseif mean(lpratio) < 0
        lpratio = lpratio + abs(mean(lpratio));
    end
    
    %% Plot scalp maps
    plotchans = zeros(1,length(chanlocs));
    plotchans(goodchannels) = lpratio;
    figure;
    %title(sprintf('%s - %s - %.1f-%.1fHz',basename,class_names{l},freqrange(fr,1),freqrange(fr,2)),'Interpreter','none');
    subplot(1,2,1); headplot(plotchans,splinefile,'electrodes','off','view',[0 90]);
    subplot(1,2,2); headplot(plotchans,splinefile,'electrodes','off','view',[-136 44]); zoom(1.5);
    %colorbar
end