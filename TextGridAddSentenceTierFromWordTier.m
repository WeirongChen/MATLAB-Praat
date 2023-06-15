function TG = TextGridAddSentenceTierFromWordTier(TextGrid, whichIsWdTier, opt)
% Generate a sentence tier to TextGrid inferred from the word tier. 
% Assuming that consecutive words without empty intervals construct a sentence.
% Example: 
% Word Tier:         |    | W1 | W2 |    |W3 | W4|W5|    |W6|
% Sentence Tier : |    | W1 W2   |    | W3 W4 W5 |    |W6|
% Require: ReadTextGrid.m
% Output: 
%     TG : TextGrid sturcture
% Wei-Rong Chen   15JUN2023
arguments
    TextGrid = '01.TextGrid'% Either TextGrid filename or TextGrid structure
    whichIsWdTier  = 1 % Either tier name or tier number; must be interval tier
    opt.outSentTierName char {mustBeText} = 'sent'
end
if ischar(TextGrid), TG = ReadTextGrid(TextGrid);
elseif isstruct(TextGrid), TG = TextGrid; 
else, fprintf('Invalid TextGrid!\n'); return;
end
if isnumeric(whichIsWdTier)
    wdTier = TG(whichIsWdTier);
elseif ischar(whichIsWdTier)
    ind = find(ismember({TG.NAME}, whichIsWdTier));
    if isempty(ind),  fprintf('Tier not found!\n'); return;end
    ind = ind(1); wdTier = TG(ind);
end
ix = ~cellfun(@isempty, wdTier.labs);
if isrow(ix), ix = ix';end
ix1 = diff(ix);
startInds = find(ix1==1)+1;
endInds = find(ix1==-1);
if ~any(ix) || (numel(startInds) ~= numel(endInds))
    fprintf('Words not found!\n'); return;
end
pairs = [startInds, endInds];
sentTierNum = numel(TG)+1;
TG(sentTierNum).NAME = opt.outSentTierName;
TG(sentTierNum).labs = cell(size(pairs,1),1);
for i = 1:size(pairs,1)
    pair = pairs(i,:);
    startTime = wdTier.segs(pair(1),1); endTime = wdTier.segs(pair(2),2);
    sent = strjoin(wdTier.labs(pair(1):pair(2)), ' ');
    TG(sentTierNum).labs{i} = sent;
    TG(sentTierNum).segs(i,:) = [startTime, endTime];
end
% test:
% WriteTextGrid(TG, 'out.TextGrid');
end % main
%% Future:
% Add write out 
    % opt.ifWriteOutput logical = false % if write the output to a new TextGrid file. 