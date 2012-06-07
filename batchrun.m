function batchrun

ts = fix(clock);
datetimestr = sprintf('%02d-%02d-%d %02d-%02d-%02d',ts(3),ts(2),ts(1),ts(4),ts(5),ts(6));
diaryfile = sprintf('diary %s.txt',datetimestr);

diary(diaryfile);
diary on

loadpaths

subjlist = {

%controls
'imagDD_fake'
'imagDD_imag_lancet'
'imagDFE_fake'
'imagDFE_imag_lancet'
'imagRM_fake'
'imagRM_imag_lancet'
'imagSB_fake'
'imagSB_imag_lancet'
'imagX2_fake'
'imagX2_imag_lancet'
'imagX4_fake'
'imagX4_imag_lancet'
'imagX5_fake'
'imagX5_imag_lancet'
'imagX6_fake'
'imagX6_imag_lancet'
'imagX7_fake'
'imagX7_imag_lancet'
'imagXX_fake'
'imagXX_imag_lancet'

%VS patients
'bourlard_lancet'
'cucovaz_lancet'
'imag_lancet'
'imbi_lancet'
'imdf_lancet'
'imjl_lancet'
'immagnetto_lancet'
'lehen_lancet'
'moutschen_lancet'
'p0310t2_lancet'
'p0311_lancet'
'p0710_lancet'
'p0910_lancet'
'pages_lancet'
'rm_imagery_lancet'
'sk_s1_lancet'

%MCS patients
'imbm'
'imfv'
'imgy2'
'imhd4'
'imjp'
'imlr'
'immj'
'imrs'
'imsn'
'p0211_imagery'
'p0410'
'p0511_imagery'
'p0711_imagery'
'p0811_imagery1'
'p0911_imagery2'
'p1011_imagery1'
'p1211_imagery'
'p1411_imagery2'
'waterschoot'
'imff'
'imst'
'p0611_imagery'
};

%trialduration = 7/60;
% scrsize = get(0,'ScreenSize');
% fsize = [800 600];
% figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)]);
%
% hold all;
%
% for subj = 1:length(subjlist)
%     lda(subjname,'trainandtest');
%     load(sprintf('BA_%s.mat',subjname));
%     lshandle = plot(BA(1,:) .* trialduration, BA(2,:), '-s', ...
%         'DisplayName', subjname, 'LineWidth',2);
%     set(lshandle,'MarkerFaceColor',get(lshandle,'Color'));
% end
%
% legend('show','Location','SouthEast');
% set(gca,'YLim',[0 100]);
% xlabel('Training time (min)');
% ylabel('Test accuracy (%)');
% box on
% grid on

fields = {
    'Subject',...
    'Accuracy',...
    'Significance',...
    ' ',...
    'Nr. of bad trials',...
    'Total nr. of trials',...
    'Nr. of bad channels',...
    'Total nr. of channels'...
    };

FSrange = [];

BI = {};
for subj = 1:size(subjlist,1)
    subjname = subjlist{subj,1};
    BI{subj,1} = subjname;

    
    fprintf('\nProcessing %s.\n', subjname);
%     dataimport_migrate(subjname);
    
%     preprocessdata(subjname);
%     
%     if subjelecs == 257
%         from257to129(subjname);
%     end
    
%     if subjelecs == 257
%         subjname = sprintf('%s_129',subjname);
%     end
    
%     mergegtecdata(subjname);
%     
%     [bestaccu siglevel] = lda(subjname,'action','cv');

%     close(gcf);
%     load(sprintf('%s_swlda.mat',subjname),'bestaccu');
%     BI{subj,2} = bestaccu;
    
    [bestaccu siglevel] = csplda(subjname,'cv');
    close all
    BI{subj,2} = bestaccu;
    BI{subj,3} = siglevel;
    
    %close(gcf);
%     load(sprintf('%s_csp.mat',subjname),'FS');
%     BI{subj,2} = max(FS)-min(FS);

    %    BI{subj,2} = analyse([subjname '_raw'],'/Users/chennu/Data/Imagery/');
    
    %     load(sprintf('%s_loglda.mat',subjname), 'binores', 'binoaccu', 'bino95ci', 'bino99ci');
    %     siglevel = ' ';
    %     if bino95ci(1) > 50
    %         siglevel = '*';
    %     end
    %     if bino99ci(1) > 50
    %         siglevel = '**';
    %     end
    %     BI{subj,2} = binoaccu;
    %     BI{subj,3} = siglevel;
    %     BI{subj,4} = length(binores);
    
%     load(sprintf('%s%s_bs.mat',filepath,subjname), 'out_x','bestaccu', 'bootp', 'bestbootp');
%     
%     targetwin = [0.1 2];
%     sigint = 1; %seconds
%     targetwin = targetwin + 1.5; %pre-stim interval
%     targetwinidx = find(targetwin(1) <= out_x(1,:),1,'first'):find(targetwin(2) <= out_x(1,:),1,'first');
%     sigint = find(sigint <= out_x(1,:),1,'first');
%     
%     siglevel = ' ';
%     %if bestbootp < 0.05
%     if length(find(bootp(targetwinidx) < 0.05)) >= sigint
%         siglevel = '*';
%     end
%     
%     %if bestbootp < 0.01
%     if length(find(bootp(targetwinidx) < 0.01)) >= sigint
%         siglevel = '**';
%     end
%     
%     BI{subj,2} = bestaccu;
%     BI{subj,3} = siglevel;
    %BI{subj,4} = [];
    
%     load(sprintf('%s_bt.mat',subjname));
%     BI{subj,5} = length(badtrials);
%     BI{subj,6} = length(alltrials);
%     
%     load(sprintf('%s_bc.mat',subjname));
%     BI{subj,7} = length(intersect(badchannels,origchan));
%     BI{subj,8} = length(origchan);

% load(sprintf('%s_FSall.mat',subjname));
% for cvrun = 1:size(FSall,2)
%     FSrange = [FSrange max(FSall(:,cvrun))-min(FSall(:,cvrun))];
% end

% mergegtecdata_ip(subjname);
% BI{subj,2} = csplda_CVb_best_test(subjname,'distfs','pre');
% close all

    save(sprintf('BI %s.mat',datetimestr),'BI');
end

% save FSrange.mat FSrange
%BI = cat(1,fields,BI);


diary off