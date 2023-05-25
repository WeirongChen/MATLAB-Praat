function k = FindWhatSegsInSyl_TextGrid(syl_ind, sylTierSegs, segTierSegs, ifJoinMultipleOutputs)
% This is a function for TextGrid processing. 
% Given a syllable in a syllable tier (sylTierSegs), find what are those
% segments in the segment tier (segTierSegs) that are included in this
% syllable. 
% 
% INPUT: 
%   syl_ind: n x 1 interger indices for the target syllable in sylTier. 
%   sylTierSegs:  nSyllables x  2 [start,end] time stamps.
%   segTierSegs: 
%                   If IsPointTier, segTierSegs : nSegments x  2 [start,end] time stamps.
%                   If not IsPointTier, segTierSegs : nSegments x  1 time stamps.
%    
% OUTPUT: 
%   k :  
%       If the input syl_ind is 1x1 interger, 
%             k: 1 x nSegs interger indices for the corresponding segments that are
%             included in the syllable indexed by syl_ind.
%       If the input syl_ind is nx1 interger, 
%             k: n x 1 cells, each cell is 1 x nSegs interger indices for the corresponding segments that are
%             included in the syllable indexed by syl_ind(i).
% 
% W.Chen 29-Nov-2018
if nargin < 4 || isempty(ifJoinMultipleOutputs), ifJoinMultipleOutputs = 0;end
n = numel(syl_ind); 
IsPointTier = size(segTierSegs,2) == 1; 
e = 0.001; % alignment error tolerance in sec. default = 0.001s (1ms)
k = cell(n,1);
for i= 1:n
    j = syl_ind(i); St = sylTierSegs(j,1) - e; Et = sylTierSegs(j,2) + e; 
    if ~IsPointTier
        ki = find(segTierSegs(:,1) > St & segTierSegs(:,2) < Et);  
        k{i} = ki;
    else
        ki = find(segTierSegs > St & segTierSegs < Et);  
        k{i} = ki;
    end
end
if n == 1
    k = k{1}; 
elseif n>1 && ifJoinMultipleOutputs
    inds = [];
    for i = 1:n
        k1 = k{i}; inds = [inds; k1];
    end
    k = inds;
end
return
end %FindWhatSegsInSyl_TextGrid