function plotspec(basename,useplot)

filepath = 'D:\Data\Imagery\';
datafile = [filepath basename '.mat'];

class_names = {'RIGHTHAND','TOES'};
load(datafile);

if length(P_C_S.Channels) == 129
    %origchan = [129 7 106 80 55 31 36 35 29 30 37 42 41];
    %origchan = [40 37];
    %origchan = [42 37 53 87 93 86 5];
%     origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
    origchan = 129;
        %C3 = 36;
    %     C4 = 104;
    %     Cz = 129;
    %     C3 = 40;
    %     %C4 = 93;
    %     Cz = 37;
    % % C3 = 64;
    % % Cz = 9;
elseif length(P_C_S.Channels) == 257
    origchan = [8    9   17   43   44   45   51   52   53   58   59   60   64   65   66   71   72   78   79   80   81   89   90  130  131  132  143  144  154  155  164  173  181  182  183  184  185  186  194  195  196  197  198  257];
    %origchan = [8    9   17   42   43   44   45   50   51   52   53   57   58   59   60   64   65   66   71   72   78   79   80   81   90  131  132  144  185  186  198  257];
    %     C3 = 59;
    %     C4 = 183;
    %     Cz = 257;
end

origchan = 32;

badchannels = P_C_S.ChannelAttribute;
badchannels = find(badchannels(1,:) == 1);
avchan = setdiff(origchan,badchannels);

y = P_C_S.Data;
y(:,:,end) = mean(y(:,:,avchan),3);
P_C_S.Data = y;

if ~exist('useplot','var') || useplot == 0
    scrsz = get(0,'ScreenSize');
    figdim = [1024 768];
    figure('Position',[(scrsz(3)-figdim(1))/2 (scrsz(4)-figdim(2))/2 figdim(1) figdim(2)], ...
        'Name',sprintf('Frequency spectrum for %s', basename),'Color', 'white');
    hold all
end

for c = 1:length(class_names)
    trial_id=find(strcmp(class_names{c},P_C_S.AttributeName));
    channel_id=[];
    type_id=[];
    channelnr_id=length(P_C_S.Channels);
    flag_tr='tr_inc';
    flag_ch='ch_exc';
    flag_type='type_exc';
    flag_nr='nr_inc';
    [TrialExclude, ChannelExclude]=gBSselect(P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);
    
    %Spectrum
    ActionBegin=500;
    RefBegin=[];
    IntervalLength=500;
    Window='hanning';
    DownSampling=0;
    FileName='';
    S_O=gBSspectrum(P_C_S,ActionBegin,RefBegin,IntervalLength,Window,DownSampling,TrialExclude,ChannelExclude,FileName,0);
    
%     plot((1:length(S_O.pxx_reference)).*S_O.deltafrequency, 10*log10(S_O.pxx_reference),'DisplayName','Reference','LineWidth',4);
    plot((1:length(S_O.pxx_action)).*S_O.deltafrequency, 10*log10(S_O.pxx_action),...
        'LineWidth',4,'DisplayName',class_names{c});
end

xlim = [7 30];
set(gca,'XLim', xlim,'FontSize',20,'FontName','Gill Sans MT','FontWeight','bold');%,'XTick',xlim(1):xlim(2));
xlabel('Frequency (Hz)','FontSize',20,'FontName','Gill Sans MT','FontWeight','bold');
ylabel('Power (dB)','FontSize',20,'FontName','Gill Sans MT','FontWeight','bold');
box on
legend('show');

%gResult2d(CreateResult2D(S_O));