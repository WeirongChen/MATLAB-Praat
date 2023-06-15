function WriteTextGrid(TG, outfilename,TotalDur)
% Usage: WriteTextGrid(TG, outfilename, TotalDur)
% Write TextTrid struct to TextGrid file.
% % The extention '.TextGrid' will be automatically added to 'outfilename'.
% --------------------------------------------------------------------------
% Input: 
%  'TG' : TextGrid structure with the following format: 
%           TextGrid(i).NAME : tier name
%           TextGrid(i).segs : 
%                   If it's an interval tier, then:
%                        TextGrid(i).segs : n Intervals x 2 ([StartTime EndTime]) matrix
%                   If it's an interval tier, then:
%                       TextGrid(i).segs : n Intervals x 1 (time) vector
%           TextGrid(i).labs=labs : n Intervals x 1 cell array
%           TextGrid(i).IsPointTier : true if this tier is a PointTier, otherwise false
%           TextGrid(i).xmin :  Start time of the tier
%           TextGrid(i).xmax : Ending time of the tier 
%   'TotalDur' : (Optional) The duration of the whole audio signals. 
% --------------------------------------------------------------------------
% 
% Weirong Chen     Jul-16-2013
% Update:               Jul-28-2018, Nov-18-2020, Nov-22-2021, Dec-21-2022, Feb-1-2023
% Latest: 15JUN2023 : replace 'hasfield' with 'isfield'

if nargin<3 || isempty(TotalDur)
    TotalDur=findDurFromTextGridStruct(TG);
    if isnan(TotalDur)
        [~, f, ~]=fileparts(outfilename);
        fprintf([f '  : No "total duration" provided!\n']);
        return
    end
end
TG = CheckTextGridIntegrity(TG, TotalDur);
xmin = TG(1).xmin; xmax = TG(1).xmax;
%------------------------------------------------------
%% 
[~,~,e]=fileparts(outfilename);
if isempty(e), outfilename=[outfilename '.TextGrid']; end    

nTiers=length(TG);

fid=fopen(outfilename,'w', 'n','UTF-8');

fprintf(fid,'File type = "ooTextFile"\r\n');
fprintf(fid,'Object class = "TextGrid"\r\n');
fprintf(fid,'\r\n');
fprintf(fid,'xmin = %f\r\n', xmin);
fprintf(fid,'xmax = %f\r\n', xmax);
fprintf(fid,'tiers? <exists>\r\n');
fprintf(fid,'size = %d\r\n', nTiers);
fprintf(fid,'item []:\r\n'); 

for i = 1:nTiers
      tg1 = TG(i); tiername = tg1.NAME; segs = tg1.segs; labs = tg1.labs;
      if ~isempty(tg1.IsPointTier)
          isPointTier = tg1.IsPointTier; 
      else
          isPointTier = size(tg1.segs,2) < 2;
      end

     xmin = tg1.xmin; xmax = tg1.xmax;
     labs = preprocessTGlabels(labs);
     
     if isPointTier, tierclass='TextTier'; else, tierclass='IntervalTier'; end
    fprintf(fid,'    item [%d]:\r\n', i);
    fprintf(fid,'        class = "%s"\r\n', tierclass);
    fprintf(fid,'        name = "%s"\r\n', tiername);
    fprintf(fid,'        xmin = %f\r\n', xmin);
    fprintf(fid,'        xmax = %f\r\n', xmax);
    if ~isPointTier % if isIntervalTier
        nIntervals=size(segs,1);
        if nIntervals == 0
            % Write an empty interval tier:
            fprintf(fid,'        intervals: size = %d\r\n', 1);
            fprintf(fid,'        intervals [1]:\r\n');
            fprintf(fid,'            xmin = %f\r\n', xmin);
            fprintf(fid,'            xmax = %f\r\n', xmax);
            fprintf(fid,'            text = ""\r\n');
            continue;
        end        
        fprintf(fid,'        intervals: size = %d\r\n', nIntervals);

        %---------------------------------------------------------------
        % Write first interval separately because the first interval
        % contains 'xmin=0' without decimal point.
        label = labs{1}; 
        fprintf(fid,'        intervals [1]:\r\n');
        fprintf(fid,'            xmin = %f\r\n', xmin);
        fprintf(fid,'            xmax = %f\r\n', segs(1,2));
        fprintf(fid,'            text = "%s"\r\n', label);
        %---------------------------------------------------------------
        if nIntervals == 1, continue;end
        for j=2:nIntervals  % loop-writing intervals starts from the second interval
            label = labs{j}; 
            fprintf(fid,'        intervals [%d]:\r\n', j);
            fprintf(fid,'            xmin = %f\r\n', segs(j,1));
            fprintf(fid,'            xmax = %f\r\n', segs(j,2));
            fprintf(fid,'            text = "%s"\r\n', label);
        end
    else % if isPointTier
        nIntervals=numel(segs);
        if nIntervals == 0
            % Write an empty point tier:
            fprintf(fid,'        points: size = %d\r\n', 0);
            continue;
        end    
        fprintf(fid,'        points: size = %d\r\n', nIntervals);
        if nIntervals == 0, continue;end
        for j=1:nIntervals
             label = labs{j}; 
            fprintf(fid,'        points [%d]:\r\n', j);
            fprintf(fid,'            number = %f\r\n', segs(j,1));
            fprintf(fid,'            mark = "%s"\r\n', label);
        end
    end % if isIntervaltier,
end % for i = 1:nTiers
fclose(fid); 
end % end of main function

%%
function labs = preprocessTGlabels(labs)
% Replace double quotation mark (") with 2x double quotation mark ("") 
if isempty(labs), return;end
nlabs = numel(labs);
for i = 1:nlabs
    lab = labs{i}; 
    if isempty(lab), continue; end
    lab = strrep(lab,'"','""'); % replace double quotation mark (") with 2x double quotation mark ("") 
    labs{i} = lab;
end
end


function dur=findDurFromTextGridStruct(TG)
dur = NaN;
for i = 1:length(TG)
    if isfield(TG(i), 'xmax')
        if ~isempty(TG(i).xmax)
            dur = TG(i).xmax; return; 
        end
    end
    if size(TG(i).segs,2)==2 % find interval tier
        dur=TG(i).segs(end); % the last timestamp is the total duration of the sound file.
        return
    end
end % for i = 1:length(TextGridStruct)
end % function dur=findDurFromTextGridStruct(TextGridStruct)


function [outTG, errorFlag] = CheckTextGridIntegrity(TG, Dur)
% For each interval tier, check if the begining of each label coincides
% with the end of the previous label. 
% 
% xmin : Starting time of TextGrid. Default:  0 (sec.)
% xmax: Ending time of TextGrid. 

tolerance = 0.0001;  % set interval tolerance = 0.0001 sec (0.1ms)
outTG = TG; 
errorFlag = 0; 
for i = 1:numel(TG)
    if isfield(TG(i), 'IsPointTier'), isPoint = TG(i).IsPointTier; else, isPoint = size(TG(i).segs,2) ==1; end
    if isfield(TG(i), 'xmin'), xmin = TG(i).xmin;  else, xmin = 0; end
    if isfield(TG(i), 'xmax'), xmax = TG(i).xmax;  else, xmax = Dur; end
    outTG(i).xmin = xmin; outTG(i).xmax = xmax; outTG(i).IsPointTier = isPoint;
    
    if isPoint, continue; end  % if isPoint, skip checking this tier. 

    labs = TG(i).labs; segs = TG(i).segs; 
    n = length(labs); 
    if n == 0, continue;end 
    
    if segs(1) ~= xmin % if interval tier and this tier doesn't start from xmin
        if segs(1) < xmin % if it starts < xmin, then set segs(1,1) to xmin
            segs(1) = xmin; 
        elseif segs(1)  > xmin % if it starts > xmin, add an empty interval starting from 0 to the beginning of the first label.
            segs = [xmin, segs(1); segs];   labs = [{''}; labs];
        end
    end


    if xmax - segs(end) > tolerance
        % if interval tier and this tier doesn't end in xmax, add an empty
        % interval starting from the end of the last interval to xmax.
        segs =  [segs; segs(end), xmax];
        labs = [labs; {''}];
    end

    idd = 1; 
    while idd < length(labs) && idd < 1000000 % avoid infinite loops
        if segs(idd,2) ~= segs(idd+1,1)
            if abs(segs(idd,2) - segs(idd+1,1)) <= tolerance
                m = nanmean([segs(idd,2), segs(idd+1,1)]); 
                segs(idd,2) = m;  segs(idd+1,1) = m;
            elseif segs(idd+1,1) - segs(idd,2) > tolerance
                segs = [segs(1:idd,:); segs(idd,2) segs(idd+1,1); segs(idd+1:end,:)];
                labs = [labs(1:idd); {''}; labs(idd+1:end)]; 
                idd = idd +1;      
            elseif  segs(idd,2) - segs(idd+1,1) > tolerance
                errorFlag = 1; 
            end
        end
        idd = idd + 1;
    end
    outTG(i).labs = labs; outTG(i).segs = segs;
end 
end  %CheckTextGridIntegrity
