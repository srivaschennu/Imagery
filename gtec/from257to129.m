function P_C_S = from257to129(P_C_S)

loadpaths

montagefile = [montagepath 'GSN-HydroCel-129.mat'];
montage129 = load(montagefile);
chanloc129 = [montage129.chanloc(:,1) montage129.chanloc(:,2) montage129.chanloc(:,3)];

if ischar(P_C_S)
    mergedfile = [filepath P_C_S '_merged.mat'];
    savefile = [filepath P_C_S '_merged.mat'];
    %this will overwrite P_C_S in memory
    fprintf('Loading %s.\n', mergedfile);
    load(mergedfile);
end

load ELECS.mat
keepchan = elecs;

% chanloc257 = [P_C_S.XPosition' P_C_S.YPosition' P_C_S.ZPosition'];
%
% [THETA PHI] = cart2sph(chanloc129(:,1),chanloc129(:,2),chanloc129(:,3));
% chanloc129 = radtodeg([PHI THETA]);
%
% [THETA PHI] = cart2sph(chanloc257(:,1),chanloc257(:,2),chanloc257(:,3));
% chanloc257 = radtodeg([PHI THETA]);
%
% keepchan = zeros(1,size(chanloc129,1));
%
% for chan = 1:size(chanloc129,1)
%     dist = distance(chanloc129(chan,1),chanloc129(chan,2),chanloc257(:,1),chanloc257(:,2));
%     [~, sortidx] = sort(dist);
%     for d = 1:length(sortidx)
%         if isempty(nonzeros(keepchan(1:chan-1) == sortidx(d)))
%             keepchan(chan) = sortidx(d);
%             break;
%         end
%     end
%     %fprintf('Channel %d: keeping closest channel %d (dist = %.1f)\n', chan, keepchan(chan), dist(keepchan(chan)));
% end

ChannelExclude = setdiff(1:P_C_S.NumberChannels,keepchan);
fprintf('Deleting %d channels.\n', length(ChannelExclude));
P_C_S=gBScuttrialschannels(P_C_S,[],ChannelExclude);
%P_C_S.SubjectID = [P_C_S.SubjectID '_129'];

if exist('savefile', 'var')
    fprintf('Saving %s.\n', savefile);
    save(savefile, 'P_C_S');
end