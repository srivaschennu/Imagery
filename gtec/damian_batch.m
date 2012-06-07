participant = 'imag010'
pathname = 'd:\data\imagery\';
origfakefile = [pathname participant '_fake_raw.mat'];

load(origfakefile);

rh = Right_Hand;
to = Toes;

clear Right_Hand Toes;

rh1 = rh(:,:,1:15);
rh2 = rh(:,:,16:30);
rh3 = rh(:,:,31:45);
rh4 = rh(:,:,46:60);
rh5 = rh(:,:,61:75);
rh6 = rh(:,:,76:90);

to1 = to(:,:,1:15);
to2 = to(:,:,16:30);
to3 = to(:,:,31:45);
to4 = to(:,:,46:60);
to5 = to(:,:,61:75);
to6 = to(:,:,76:90);

Right_Hand = cat(3,rh1,to1,rh2,to2,rh3,to3);
Toes = cat(3,rh4,to4,rh5,to5,rh6,to6);
save([pathname participant '_100fake_raw.mat'], 'Right_Hand', 'Toes', 'samplingRate');
clear Right_Hand Toes;
Right_Hand = cat(3,rh1,to1,rh2,to2,rh5,to6);
Toes = cat(3,rh3,to3,rh4,to4,to5,rh6);
save([pathname participant '_66fake_raw.mat'], 'Right_Hand', 'Toes', 'samplingRate');
clear Right_Hand Toes;
Right_Hand = cat(3,rh1,to1,rh2,to3,rh5,to6);
Toes = cat(3,rh3,to2,to4,rh4,to5,rh6);
save([pathname participant '_50fake_raw.mat'], 'Right_Hand', 'Toes', 'samplingRate');
clear Right_Hand Toes;
Right_Hand = cat(3,rh1,to1,rh3,to3,rh5,to5);
Toes = cat(3,rh2,to2,rh4,to4,rh6,to6);
save([pathname participant '_33fake_raw.mat'], 'Right_Hand', 'Toes', 'samplingRate');

preprocessdata([participant '_100fake']);
preprocessdata([participant '_66fake']);
preprocessdata([participant '_50fake']);
preprocessdata([participant '_33fake']);

equalisebadch([participant '_fake'],[participant '_100fake']);
equalisebadch([participant '_fake'],[participant '_66fake']);
equalisebadch([participant '_fake'],[participant '_50fake']);
equalisebadch([participant '_fake'],[participant '_33fake']);

mergegtecdata([participant '_100fake']);
mergegtecdata([participant '_66fake']);
mergegtecdata([participant '_50fake']);
mergegtecdata([participant '_33fake']);

lda([participant '_100fake'],'train');
lda([participant '_66fake'],'train');
lda([participant '_50fake'],'train');
lda([participant '_33fake'],'train');