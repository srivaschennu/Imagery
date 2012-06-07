ActLimits = [45:133]; %45:133 is 2 seconds after beep based on EEGLabs time-point output

freq = 1; %lazy fall-back to previous versions of this script, just necessary for later variables

bounds = [-1:1]; %below and above the reactive frequency, 1 point here is 0.25 of a Hz

clear work* mag*

a = exist('freqsCz','var');

for p = 1:length(Czchans);
    
    % the calculation takes a long time for this much data so this means
    % that if it's been calculated already, it just uses what already
    % exists in the workspace, or has been loaded in from a saved version.
    
    if a == 0

        [erspCz,itc,powbaseCz,times,freqsCz,erspboot,itcboot,tfdataCz] = newtimef({ LARdataRH(Czchans(p),:,:) LARdataTO(Czchans(p),:,:) }, 1375,[0 5500], 250, 0, 'padratio', 4, 'plotersp', 'off', 'plotitc', 'off');

        RH104 = tfdataCz{1};
        LH104 = tfdataCz{2};

        RH_all_tfdata{p} = RH104(1:123,1:133,:); % variables that fill with each iteration and I save later so I can reload them without the above calculation repeating
        TO_all_tfdata{p} = LH104(1:123,1:133,:);

    else

        RH104 = RH_all_tfdata{p};
        LH104 = TO_all_tfdata{p};

    end

    theFreq = find(round(freqsCz) == reacFreq,1);  %reacFreq comes from a different script that calculates the reactive frequency

    amuRH104 = RH104(theFreq+bounds,:,:); %takes out the timefreq data for the reactive frequency and the width of the bounds 
    amuLH104 = LH104(theFreq+bounds,:,:);

    muRH104 = mean(amuRH104(:,:,:),1); %averages across the frequency band
    muLH104 = mean(amuLH104(:,:,:),1);

    BSLmuRH104 = muRH104(:,23:44,:); %the time points that come from the TF that correspond to the baseline period
    BSLmuLH104 = muLH104(:,23:44,:);

    ACTmuRH104 = muRH104(:,ActLimits,:); %the time points corresponding to the action period (0-2secs)
    ACTmuLH104 = muLH104(:,ActLimits,:);


        workBSLmuRH104(freq,:,:) = real(BSLmuRH104(freq,:,:)) .^2 + imag(BSLmuRH104(freq,:,:)) .^2; %from what i understood from researching the TF output on eeglablist, this is how you get a power value from the TF complex number output
        magBSLmuRH104(freq,1,:) = mean(workBSLmuRH104(freq,:,:),2);

        %repeats the above for RH and Toe (called LH due to it's age...)
        %for the baseline and the action periods
        
        workBSLmuLH104(freq,:,:) = real(BSLmuLH104(freq,:,:)) .^2 + imag(BSLmuLH104(freq,:,:)) .^2;
        magBSLmuLH104(freq,1,:) = mean(workBSLmuLH104(freq,:,:),2);


        workACTmuRH104(freq,:,:) = real(ACTmuRH104(freq,:,:)) .^2 + imag(ACTmuRH104(freq,:,:)) .^2;
        magACTmuRH104(freq,1,:) = mean(workACTmuRH104(freq,:,:),2);

        workACTmuLH104(freq,:,:) = real(ACTmuLH104(freq,:,:)) .^2 + imag(ACTmuLH104(freq,:,:)) .^2;
        magACTmuLH104(freq,1,:) = mean(workACTmuLH104(freq,:,:),2);


    aERDmuRH104 = magACTmuRH104 ./ magBSLmuRH104; %ratio
    aERDmuLH104 = magACTmuLH104 ./ magBSLmuLH104;

    ERDmuRH104 = squeeze(aERDmuRH104);
    ERDmuLH104 = squeeze(aERDmuLH104);

    clear work* mag*
    
    %grows a big variable to input to the eeglab 3d plotting function
    
    if p == 1;

        DataOutRH = [log(ERDmuRH104)]; %Cz RH
        DataOutTO = [log(ERDmuLH104)]; %Cz TO
    else
        DataOutRH = [DataOutRH log(ERDmuRH104)];
        DataOutTO = [DataOutTO log(ERDmuLH104)];
    end;

    p

end;

for i = 1:length(Czchans)

    LAR_Spec_RH(Czchans(i)) = DataOutRH(i);
    LAR_Spec_TO(Czchans(i)) = DataOutTO(i);
    
end

%optional extra to give a TF of the whole period for all data, much like
%the TFs you plot with gTEC.

% 
% AllData = cat(3, LARdataRH, LARdataTO);
% CData = AllData(Czchans,:,:);
% meanData = squeeze(mean(CData,1));
% figure; newtimef(meanData, 1375, [-1500 4000], 250, 0, 'freqs', [6 26], 'baseline', [-500 0], 'plotitc', 'off');
% 
