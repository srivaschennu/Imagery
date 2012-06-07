function accutest(basename)

[~ , ~, bsl_pci01 bsl_pci001] = lda(basename,'baseline','cv');
[act_accu , ~, act_pci01 act_pci001] = lda(basename,'action','cv');

siglevel = '';

if act_pci01(1) > bsl_pci01(2)
    siglevel = '**';
end

if act_pci001(1) > bsl_pci001(2)
    siglevel = '***';
end

fprintf('\n%s: Accuracy in action window = %.1f%%%s\n',basename,act_accu,siglevel);