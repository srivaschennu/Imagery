function P_C_S = markbadtrialschannels(P_C_S,BadTrials,BadChannels)

if exist('BadTrials','var') && ~isempty(BadTrials)
    badtrial_idx=strmatch('ARTIFACT',P_C_S.AttributeName,'exact');
    Attribute = P_C_S.Attribute;
    Attribute(badtrial_idx, BadTrials) = 1;
    P_C_S.Attribute = Attribute;
end

if exist('BadChannels','var') && ~isempty(BadChannels)
    badchannel_idx=strmatch('BAD',P_C_S.ChannelAttributeName,'exact');
    ChannelAttribute = P_C_S.ChannelAttribute;
    ChannelAttribute(badchannel_idx, BadChannels) = 1;
    P_C_S.ChannelAttribute = ChannelAttribute;
end