function catclass(basename)

filepath = 'd:\data\imagery\';
datafile = [filepath basename '_cont.mat'];
cifile = [filepath basename '_cont_ci.mat'];
chfile = [filepath basename '_cont_ch.mat'];

load([filepath basename '_rh_cont.mat']);
rh_y = y;
clear y

load([filepath basename '_to_cont.mat']);
to_y = y;
clear y

if length(nonzeros(rh_y(end,:))) ~= length(nonzeros(to_y(end,:)))
    fprintf('Number of trials in each class must be the same. Class 1: %d; Class 2: %d\n', ...
        length(nonzeros(rh_y(end,:))), length(nonzeros(to_y(end,:))));
    return;
end

y = [rh_y to_y];
epochcount = length(nonzeros(rh_y(end,:)));

class_info = [ones(1,epochcount) zeros(1,epochcount); zeros(1,epochcount), ones(1,epochcount)];
class_names = {
    'RIGHT_HAND'
    'TOES'
    };

chancount = size(y,1);

if chancount == 130
    C3 = 41;%36;
    C4 = 104;
    Cz = 37;%129;
elseif chancount == 258
    C3 = 59;
    C4 = 183;
    Cz = 257;
    y = y([C3,C4,Cz,end],:);
    C3 = 1;
    C4 = 2;
    Cz = 3;
end
channels = [C3 Cz];

save(datafile, 'y');
save(cifile, 'class_info', 'class_names');
save(chfile, 'channels');
clear