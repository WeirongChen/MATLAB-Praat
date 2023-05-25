
function outTG = sliceTextGrid(inTG, startTime, endTime)
% Slice TextGrid from StartTime to EndTime
% W. Chen  21SEP2021
nTiers = numel(inTG);
outTG = inTG;
% dur = t2-t1;
for i = 1:nTiers
    tier = inTG(i); labs = tier.labs; segs = tier.segs;
    isPointTier = size(segs,2)==1;
    if isPointTier
        ix = segs >= startTime & segs <= endTime;
    else
        ix = segs(:,1) >= startTime & segs(:,2) <= endTime;
    end
    labs1 = labs(ix); segs1 = segs(ix,:) - startTime;
    outTG(i).labs = labs1; outTG(i).segs = segs1;
end
end % sliceTextGrid