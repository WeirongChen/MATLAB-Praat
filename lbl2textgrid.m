function TextGrid =lbl2textgrid(lbl, outTextGridFileName)
% Convert lbl to TextGrid
% lbl is Mark Tiede's label structure, wherein: 
% OFFSET is mean of onset:offset for phone, onset for word
% VALUE field holds [onset offset]
% HOOK field holds "word" or "phone" label type
if nargin < 2, outTextGridFileName = [] ;end;
TierNames = unique({lbl.HOOK}, 'stable');
nTiers = numel(TierNames);
for i =1:nTiers,
    tierName = TierNames{i};
    TextGrid(i).NAME =tierName;
    idx = ismember({lbl.HOOK},tierName);
    tierlbl =lbl(idx);
    segs =round(cell2mat({tierlbl.VALUE}'),2)/1000;
    labs ={tierlbl.NAME}';
    [segs2, idx] = sortrows(segs,1);labs2 =labs(idx);
    if segs2(1,1) > 0, segs2 = [0 segs2(1,1); segs2]; labs2 = [{''}; labs2]; end;
    TextGrid(i).segs =segs2; TextGrid(i).labs =labs2; 
end;

if isempty(outTextGridFileName), return;end;

Write2TextGrid(TextGrid, outTextGridFileName);