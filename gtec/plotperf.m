function plotperf(catlabel,bcf,val,tag)

fontsize = 24;
fontweight = 'bold';

uniqcat = unique(catlabel);
cat = zeros(length(catlabel),1);
for c = 1:length(uniqcat)
    cat(strcmpi(uniqcat{c},catlabel)) = c;
end

colours = zeros(length(catlabel),3);
colours(strcmpi('MCS+',catlabel),:) = repmat([0 1 0],sum(strcmpi('MCS+',catlabel)),1);
colours(strcmpi('MCS-',catlabel),:) = repmat([1 0 0],sum(strcmpi('MCS-',catlabel)),1);
colours(strcmpi('VS',catlabel),:) = repmat([0 0 1],sum(strcmpi('VS',catlabel)),1);

screensize = get(0,'ScreenSize');
figsize = [800 600];
figure('Color','white','Position',[screensize(3)/2-figsize(1)/2 screensize(4)/2-figsize(2)/2 figsize(1) figsize(2)]);

scatter(cat(strcmpi('MCS+',catlabel)),val(strcmpi('MCS+',catlabel)),250,colours(strcmpi('MCS+',catlabel),:),'filled');
hold all
scatter(cat(strcmpi('MCS-',catlabel)),val(strcmpi('MCS-',catlabel)),250,colours(strcmpi('MCS-',catlabel),:),'filled');
scatter(cat(strcmpi('VS',catlabel)),val(strcmpi('VS',catlabel)),250,colours(strcmpi('VS',catlabel),:),'filled');


% scatter(cat,val,[],colours,'filled');

set(gca,'XLim',[0 max(cat)+1],'YLim',[50 70],'XTick',1:max(cat),...
    'YTick',50:5:70,'XTickLabel',uniqcat,'FontName','Helvetica','FontSize',fontsize,'FontWeight',fontweight);
ylabel('Cross-validated Accuracy (%)','FontName','Helvetica','FontSize',fontsize,'FontWeight',fontweight);

% set(gca,'XLim',[0 max(cat)+1],'YLim',[0 1],'XTick',1:max(cat),...
%     'YTick',0:0.2:1,'XTickLabel',uniqcat,'FontName','Helvetica','FontSize',fontsize,'FontWeight',fontweight);
% ylabel('Range of CSP Scores','FontName','Helvetica','FontSize',fontsize,'FontWeight',fontweight);

for c = 1:length(cat)
    textx = cat(c)+0.1;
    texty = val(c)-0.5;
    if ~strcmpi('X',tag{c})
        text(textx,texty,tag{c},'FontName','Helvetica','FontSize',fontsize+10,'FontWeight',fontweight);
    end
end

box on
%legend({'CF+','CF-'});
