function ploterdmap(basename)

filepath = 'D:\Data\Imagery\';
datafile = [filepath basename '.mat'];

load(datafile);

if length(P_C_S.Channels) == 129
    %origchan = [129 7 106 80 55 31 36 35 29 30 37 42 41];
    %origchan = [40 37];
    %origchan = [42 37 53 87 93 86 5];
    origchan = [6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129];
    %     C3 = 36;
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

badchannels = P_C_S.ChannelAttribute;
badchannels = find(badchannels(1,:) == 1);
avchan = setdiff(origchan,badchannels);

y = P_C_S.Data;
y(:,:,end) = mean(y(:,:,avchan),3);
P_C_S.Data = y;

save d:\data\imagery\temp.mat P_C_S

trial_id=[];
channel_id=[];
type_id=[];
channelnr_id=length(P_C_S.Channels);
flag_tr='tr_exc';
flag_ch='ch_exc';
flag_type='type_exc';
flag_nr='nr_inc';
[TrialExclude, ChannelExclude]=gBSselect(P_C_S,trial_id,flag_tr,channel_id,flag_ch,type_id,flag_type,channelnr_id,flag_nr);

T.ref=[250 375];
%T.ref=[376 875];
T.borders=[7 31];
T.bandwidths=1;
T.steps=1;
T.lc=[];
T.hc=[];
T.mode=0;
T.med=0;
T.stats = 'boot';
%T.stats = [];%'boot';
T.statsopt.B=200;
T.statsopt.alpha=0.05;
T.heuristic=3;
T.statsopt.med=0;
T.smooth=[16 8];
FileName='';
E_M=gBSerdmaps(P_C_S,T,TrialExclude,ChannelExclude,FileName,0);
[maxerd, minidx] = min(min(struct(struct(E_M).objects{1,1}).D.erders,[],2));
fprintf('Max ERD of %.1f found at %dHz.\n', maxerd, T.borders(1)+minidx-1);
gResult2d(CreateResult2D(E_M));