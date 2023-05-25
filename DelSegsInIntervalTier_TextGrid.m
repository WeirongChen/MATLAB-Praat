function outTier = DelSegsInIntervalTier_TextGrid(del_seg_ind, tgTier)
% This is a function for TextGrid processing. 
% Delete a list of segsments in del_seg_ind from an interval tier in a
% textgrid structure. The time duration of the deleted segments will be
% merged into the previous segments. 
% 
% INPUT: 
%   del_seg_ind: n x 1 interger indices for the segments to be deleted. 
%   tgTier:  1x1 structure
%           tgTier.segs:  n x 2 [start,end] time stamps.
%           tgTier.labs:   n x 1 cells for segment labels.
%           tgTier.IsPointTier:   1x1 boolean value.  This should be false
%              because for this purpose, the input tier should be an interval tier. 
%    
% OUTPUT: 
%    outTier:  1x1 struter of the output tier after segments in del_seg_ind
%    are deleted. 
% 
% W.Chen 29-Nov-2018
outTier = tgTier; 
segs1 = tgTier.segs(:,1); segs2 = tgTier.segs(:,2); labs = tgTier.labs; 
% If del_seg_ind contains 1, then: segs(2,1) = segs(1,1); segs(1,:) = []
if any(find(del_seg_ind==1))
    segs1(2) = segs1(1); segs1(1) = []; segs2(1) = []; labs(1) = [];
    del_seg_ind(del_seg_ind==1) = []; 
end
segs1(del_seg_ind) = []; segs2(del_seg_ind-1) = []; labs(del_seg_ind) = [];
outTier.segs = [segs1, segs2]; 
outTier.labs = labs; 
return 
