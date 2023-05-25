function GenSegTierInTextGrid(tgFName, V_Tier, C_list, NasalCoda_list)
% This function generates hypothetical segmental tier from vowel tier in textgrid files.
% 
% See also: DO_Call_PraatFmts_ref_for_all_wav_in_folder.m
%         and FillinSegTierFromVowelLabelTier_TextGrid.m
% Weirong Chen  Jan-23-2015
sep=filesep;
p_ref = fileparts(which('GenSegTierInTextGrid'));
if nargin<2 || isempty(V_Tier), V_Tier=1;end;
if nargin < 3 || isempty(C_list),C_list=xls2struct([p_ref sep 'C_list.xlsx']);end;
if nargin < 4 || isempty(NasalCoda_list),NasalCoda_list=xls2struct([p_ref sep 'NasalCoda_list.xlsx']);end;
% if nargin < 5 || isempty(wordlist), ifWordlistExists=0; else ifWordlistExists=1; if ischar(wordlist),wordlist=xls2struct(wordlist);end;  end;
if ischar(C_list),C_list=xls2struct(C_list);end; if ischar(NasalCoda_list),NasalCoda_list=xls2struct(NasalCoda_list);end;
if isstruct(C_list),C_list=cat(1,C_list.C_IPA,C_list.C_IPA93,C_list.C_Pinyin);end;
if isstruct(NasalCoda_list),NasalCoda_list=cat(1,NasalCoda_list.C_IPA,NasalCoda_list.C_IPA93,NasalCoda_list.C_Pinyin);end;

try
        TG=ReadTextGrid(tgFName); whichSeg_Tier=length(TG)+1;
        [segs, labs]=ReadPraatTier_wr(tgFName, V_Tier); TotalDur=segs(end,2);
        segTierSegs=segs;segTierLabs=labs;
        for j=1:length(labs) %running through labels in V_Tier
             if isempty(labs{j}) ||  ~strcmpi(labs{j}(1),'V'), continue;end;
              [segTierSegs, segTierLabs] = ProcWithoutWordlist(j, labs, segs, segTierSegs, segTierLabs, C_list, NasalCoda_list);
        end;% for j=1:length(V_labs), running through labels in V_Tier.
        TG(whichSeg_Tier).segs=segTierSegs;TG(whichSeg_Tier).labs=segTierLabs;TG(whichSeg_Tier).NAME='seg';
        Write2TextGrid(TG,tgFName,TotalDur);
    catch
        fprintf(['Error processing "' strrep(tgFName,'\','\\') '" \n']);
end;

end % end of main function
function  [segTierSegs, segTierLabs] =ProcWithoutWordlist(j, labs, segs, segTierSegs, segTierLabs, C_list, NasalCoda_list)
lab=labs{j}; if j>1, previousLab=labs{j-1};end;  
if j<length(labs), nextLab=labs{j+1};end; 
StartTime=segs(j,1);EndTime=segs(j,2);labDur=EndTime-StartTime; % in sec
%[Vcore, NasalCoda, OnsetC, rep, Coda, newLabel]=CleanUpTGLabel
[V,NasalCoda, OnsetC, ~,~, lab]=CleanUpTGLabel(lab,C_list, NasalCoda_list);
subLabs=ParseVlabelTrans(V,NasalCoda); nSegs=length(subLabs);
% -----------------------------------------
% If the found boundary is more than 0.02s (20ms) away from the Vlable Start/End times, 
% then this should be considered as an error and skipped :
[index1, foundValue] = FindClosestInNumArray(segTierSegs(:,1), StartTime);
if abs(foundValue-StartTime)>0.02, return;end; 
[index2, foundValue] = FindClosestInNumArray(segTierSegs(:,2), EndTime);
if abs(foundValue-EndTime)>0.02, return;end; 
if index1~=index2, return;end; % 'index1' should equal 'index2'
%-----------------------------------------
% Prepare labels ('SubLabs') and hypothetical timestamps ('SubSegs') to be
% inserted into 'segTierLabs' and 'segTierSegs'. 
SegDur=labDur/nSegs; SubSegs=NaN*zeros(nSegs,2);SubSegs(1,1)=StartTime; SubSegs(end,2)=EndTime;SubSegs(1,2)=StartTime+SegDur;
for k=1:nSegs,
    subLabs{k}=['V' num2str(k) '-' subLabs{k} '-(' lab ')'];
    if k>1, SubSegs(k,1)=SubSegs(k-1,2);end;
    if k<nSegs, SubSegs(k,2)=SubSegs(k,1)+SegDur;end;
end;
% Generate hypothetical onset consonant label
HypCdur = 0.01; % hypothetical onset consonant duration = 10ms
if ~isempty(OnsetC), 
    OnsetClab = ['C1-' OnsetC '-(' lab ')'];
    if ~isempty(previousLab) && strcmp(previousLab(1),'C'), 
        segTierLabs{index1-1}= OnsetClab; 
    else 
        OnsetCseg = [SubSegs(1,1)-HypCdur, SubSegs(1,1)]; 
        subLabs = [OnsetClab; subLabs]; SubSegs = [OnsetCseg; SubSegs];
        if OnsetCseg(1,1)>segTierSegs(index1-1, 1),
            segTierSegs(index1-1, 2)=OnsetCseg(1,1);
        else
            OnsetCseg(1,1)=segTierSegs(index1-1, 1)+(segTierSegs(index1-1, 2)-segTierSegs(index1-1, 1))/2;
            segTierSegs(index1-1, 2)=OnsetCseg(1,1);
        end;
    end;
end
% ----------------------------------------
segTierLabs=[segTierLabs(1:index1-1); subLabs; segTierLabs(index1+1:end)];
segTierSegs=[segTierSegs(1:index1-1, :); SubSegs; segTierSegs(index1+1:end, :)];
end % function ProcWithoutWordlist

function subLabs=ParseVlabelTrans(Vlabel,NasalCoda)
% e.g., subLabs=ParseVlabelTrans('ian'); => subLabs = {'i', 'ia', 'a', 'n'}; 
subLabs=[]; idx=1;
NasalIdx=strfind(Vlabel, '~') - 1; % NasalIdx = nasal index; e.g., Vlabel = 'i~a~n'; NasalIdx = [1,2];
Vlabel=strrep(Vlabel,'~','');
vlength=length(Vlabel);
for k=1:vlength-1,
%     thisVLabel=Vlabel(k); nextVLabel=Vlabel(k+1);
    % Treat /i~/ as one vowel segment
    if sum(ismember(NasalIdx,k))>0, thisVLabel=[Vlabel(k) '~']; else thisVLabel=Vlabel(k);end;
    if sum(ismember(NasalIdx,k+1))>0, nextVLabel=[Vlabel(k+1) '~']; else nextVLabel=Vlabel(k+1);end;
    subLabs{idx}=thisVLabel;
    subLabs{idx+1}=[thisVLabel nextVLabel];
    idx=idx+2;
end;
if sum(ismember(NasalIdx,vlength))>0,subLabs{idx}=[Vlabel(vlength) '~']; else subLabs{idx}=Vlabel(vlength);end;
idx=idx+1;
if ~isempty(NasalCoda), subLabs{idx}=NasalCoda;end;subLabs=subLabs';
end  %subLabs=ParseVlabelTrans(Vlabel,NasalCoda)
