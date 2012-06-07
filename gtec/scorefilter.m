function FilterScores = scorefilter(P_C,C_O,ChannelExclude,FileName)

class_names = {'RIGHTHAND';'TOES'};

spf = struct(get(C_O.objects,'spf'));
W = real(spf.D.W);
FilterScores = zeros(size(W,2),1);

P_C = struct(P_C);
rhtrials = logical(P_C.attribute(strcmp(class_names{1},P_C.attributename),:));
totrials = logical(P_C.attribute(strcmp(class_names{2},P_C.attributename),:));
trialcount = length(P_C.trialnumber);

ChannelInclude = setdiff(P_C.channels,ChannelExclude);

for filter = 1:size(W,2)
    vars = zeros(1,trialcount);
    for trial = 1:trialcount
        thistrial = squeeze(P_C.data(trial,:,setdiff(P_C.channels,ChannelExclude)))';
        vars(trial) = W(filter,ChannelInclude) * (thistrial * thistrial') * W(filter,ChannelInclude)';
    end
    FilterScores(filter) = median(vars(rhtrials)) / ...
        (median(vars(rhtrials)) + median(vars(totrials)));
    %fprintf('Filter %d got a score of %.2f\n', filter,score(filter));
end

if ~strcmp(FileName,'')
    save(FileName,'FilterScores');
end