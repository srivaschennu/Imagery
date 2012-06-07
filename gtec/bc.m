function P_C_S = bc(P_C_S,bcwin)

bcwin = (bcwin .* P_C_S.SamplingFrequency) + P_C_S.PreTrigger;
datasize = size(P_C_S.Data);
P_C_S.Data = permute(P_C_S.Data, [3 2 1]); %permute to channels X frames X epochs
P_C_S.Data = rmbase(P_C_S.Data, datasize(2), bcwin(1):bcwin(2));
P_C_S.Data = reshape(P_C_S.Data, datasize(3), datasize(2), datasize(1));
P_C_S.Data = permute(P_C_S.Data, [3 2 1]); %permute back to epochs X frames X channels