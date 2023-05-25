function k = FindWhichSylContainsSeg_TextGrid(segInd, segTierSegs, sylTierSegs)
% This is a function for TextGrid processing. 
% Given a segment in a segment tier (segTierSegs), find which syllable in the syllable tier (sylTierSegs) that contains this
% segment.  
% 
% INPUT: 
%   segInd: n x 1 interger indices for segments in segTier. 
%   segTierSegs: 
%                   If IsPointTier, segTierSegs : nSegments x  2 [start,end] time stamps.
%                   If not IsPointTier, segTierSegs : nSegments x  1 time stamps.
%   sylTierSegs:  nSyllables x  2 [start,end] time stamps.
%    
% OUTPUT: 
%   k :  n x 1 interger indices for the corresponding syllables that contains
%        the segments indexed by 'segInd'. 
% 
% W.Chen 29-Nov-2018

n = numel(segInd);
IsPointTier = size(segTierSegs,2) == 1; 
e = 0.001; % alignment error tolerance in sec. default = 0.001s (1ms)
St = sylTierSegs(:,1) - e; Et = sylTierSegs(:,2) + e; 
k = NaN(n,1);
for i= 1:n
    ind = segInd(i);
    if ~ IsPointTier
        t1 = segTierSegs(ind,1); t2 = segTierSegs(ind,2); 
        ki = find(St < t1 & Et > t2);  
        k(i) = ki(1); 
    else
        t = segTierSegs(ind); 
         ki = find(St < t & Et > t);  
         k(i) = ki(1); 
    end
end

return
