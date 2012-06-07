function P_C = changeref(P_C)

[~, badchannels] = findbadtrialschannels(P_C);
chanlocs = [P_C.XPosition' P_C.YPosition' P_C.ZPosition'];

%local average reference (laplacian operator)
P_C.Data = lar(P_C.Data,chanlocs,badchannels);

%common average reference
% Data = permute(P_C.Data,[3 2 1]);
% Data = reref(Data,[],'exclude',badchannels);
% P_C.Data = permute(Data,[3 2 1]);

%linked mastoid reference
% if length(P_C.Channels) == 129
%     mastoidchannels = [57 100];
% elseif length(P_C.Channels) == 257
%     mastoidchannels = [94 190];
% end
% 
% Data = permute(P_C.Data,[3 2 1]);
% Data = reref(Data,mastoidchannels,'exclude',badchannels,'keepref','on');
% P_C.Data = permute(Data,[3 2 1]);
