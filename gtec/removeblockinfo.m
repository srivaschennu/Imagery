function P_C_S = removeblockinfo(P_C_S)

AttributeName = P_C_S.AttributeName;
Attribute = P_C_S.Attribute;
AttributeColor = P_C_S.AttributeColor;

blockattridx = find(strncmp('BLOCK',AttributeName,length('BLOCK')));
keepattr = setdiff(1:length(AttributeName),blockattridx);

P_C_S.AttributeName = AttributeName(keepattr);
P_C_S.Attribute = Attribute(keepattr,:);
P_C_S.AttributeColor = AttributeColor(keepattr);
