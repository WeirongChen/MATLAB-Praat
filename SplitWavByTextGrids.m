function SplitWavByTextGrids(mypath, outpath)
% This function splits all wav files by corresponding TextGrids
%
% Weirong Chen   Jul-2-2014

sep=filesep;
if nargin<1 || isempty(mypath), mypath=pwd;end; 
if nargin<2 || isempty(outpath), outpath=[mypath sep 'split'];end;


Tier=1;
wavfl=gfl([mypath sep '*.wav']);
tgfl=gfl([mypath sep '*.TextGrid']);
A=ismember(wavfl,tgfl);
fl=wavfl(A);

[~,~]=mkdir(outpath);
for idx=1:length(fl)
    f=fl{idx};
    wavFileName=[mypath sep f '.wav'];
    TextGridFileName=[mypath sep f '.TextGrid'];
    [y,sr]=audioread(wavFileName);
    [segs,labs]=ReadPraatTier1(TextGridFileName,Tier);
    for i=1:length(labs)%1:length(labs)
        lab=labs{i}; lab=strrep(lab,' ','');
        if strcmpi(lab,'XXX') || isempty(lab), continue;end;
        fn=[outpath sep lab '.wav'];
        t1=round(segs(i,1)*sr)+1;t2=round(segs(i,2)*sr)+1;
        if t2>length(y),t2=length(y);end;
        s=y(t1:t2);
        audiowrite(fn,s,sr);
        %[textgrid,THRESH]=GenerateTextGridfromWav(wavFName, outpath, nSylTarget, Vlabel, nSylPreCarrier, nSylPostCarrier, TierName)
%         GenerateTextGridfromWav(fn);
    end;
end; % for idx=1:length(fl)
end % end of SplitWavByTextGrids
%%
function [segs,labs, tierNames, nTiers,tierorder] = ReadPraatTier1(fName,tier)
%READPRAATTIER  - read tier data from PRAAT TextGrid file
%
%	usage:  [segs,labs] = ReadPraatTier(fName, tier)
%
% use this procedure to load the specified point or interval TIER data 
% from PRAAT TextGrid format FNAME (both standard and short forms supported)
%
% default ".TextGrid" extension is optional
%
% if TIER is unspecified, the default is the 1st tier.
% TIER can be tier name or tier number.
%
% Returns SEGS offsets [nSegs x offs] and segment labels LABS [nSegs]
% for specified tier (for interval tiers offs == head,tail)
%
% see also WRITESHORTTEXTGRID  ReadPraatTier.m

% mkt 03/09
%  
%  modified by using 'DetectTextGridEncoding' to detect the encoding of .TextGrid file.
% Requires: 'DetectTextGridEncoding', 'textscanu_wr'
% Sep-08-2015 wr added 'DetectStrainedQuotationSybol' function.

% parse args
if nargin < 1,
	eval('help ReadPraatTier');
	return;
end;

[p,f,e] = fileparts(fName);
if isempty(e), fName = fullfile(p,[f,'.TextGrid']); end;
encoding = DetectTextGridEncoding(fName);
% vacuum file
try
    lines = textscanu_wr(fName, encoding);
catch
	error('error attempting to load from %s', fName);
end;
lines=DetectStrainedQuotationSybol2(lines);
% some rudimentary format checking
if length(lines)<15 || isempty(findstr(lines{1},'ooTextFile')) || isempty(findstr(lines{2},'"TextGrid"')) || isempty(findstr(lines{6},'exists'))
    
	error('%s has unrecognized file format', fName);
end;
%long or short?
[isShort, head, tail, nTiers]=DetectTextGridCellsLongOrShort(lines);

% get tier names and types
if isShort,
	k = find(~cellfun(@isempty,regexp(lines,'TextTier')));
	if isempty(k),
		pointTierNames = {};pointTiers=[];
    else
		pointTiers = k + 1;
		pointTierNames = lines(pointTiers);
		for k = 1 : length(pointTiers), pointTierNames{k} = strrep(pointTierNames{k},'"','');  end;
	end;
	k = find(~cellfun(@isempty,regexp(lines,'IntervalTier')));
	if isempty(k),
		intTierNames = {};intTiers =[];
    else
		intTiers = k + 1;
		intTierNames = lines(intTiers);
		for k = 1 : length(intTiers), intTierNames{k} = strrep(intTierNames{k},'"',''); end;
	end;
else % if isLong
	k = find(~cellfun(@isempty,regexp(lines,'class = "TextTier"')));
	if isempty(k),
		pointTierNames = {};pointTiers=[];
    else
		pointTiers = k + 1;
		q = regexp(lines(k+1),'name = "(\S+)"','tokens');
		for k = 1 : length(q), pointTierNames(k) = q{k}{1}; end;
	end;
	k = find(~cellfun(@isempty,regexp(lines,'class = "IntervalTier"')));
	if isempty(k),
		intTierNames = {};intTiers =[];
    else
		intTiers = k + 1;
		q = regexp(lines(k+1),'name = "(\S+)"','tokens');
		for k = 1 : length(q), intTierNames(k) = q{k}{1}; end;
	end;
end;

% list names if tier name unspecified
tierNames = [pointTierNames , intTierNames];

AllTierNameLines=[pointTiers; intTiers];
[~,tierorder]=sort(AllTierNameLines);

if nTiers ~= length(tierNames),
	error('expecting %d tiers, found %d', nTiers, length(tierNames));
end;
if nargin < 2,
    tier = tierNames{tierorder(1)};
elseif isnumeric(tier)
    tier = tierNames{tierorder(tier)};
end;

% format data
k = strmatch(tier, tierNames, 'exact');
if length(k) > 1,
	k = k(1);
	fprintf('more than one instance of %s found in %s; using first\n', tierNames{k}, fName);
elseif isempty(k),
	error('%s not found in %s', tier, fName);
end;
k = strmatch(tier, pointTierNames, 'exact');
if isempty(k),
	k = strmatch(tier, intTierNames, 'exact');
	tiers = intTiers;
	isPoint = 0;
else
	tiers = pointTiers;
	isPoint = 1;
end;
tierStart = tiers(k);

% verify tier length against file length
if isShort,
	h = str2num(lines{tierStart+1});
	t = str2num(lines{tierStart+2});
else
	h = str2num(lines{tierStart+1}(regexp(lines{tierStart+1},' \d'):end));
	t = str2num(lines{tierStart+2}(regexp(lines{tierStart+2},' \d'):end));
end;
if head ~= h || tail ~= t,
	error('mismatch between tier (%.1f:%.1f) and file lengths (%.1f:%.1f)', h,t,head,tail);
end;

% short format
if isShort,
	nSegs = str2num(lines{tierStart+3});
	M = (3 - isPoint);
	h = tierStart + 4;
	t = nSegs*M + h - 1;
	n = (t - h + 1) / M;
	lines = reshape(lines(h:t),M,n)';
	labs = lines(:,M);
	for k = 1 : length(labs),
		labs{k} =strrep(labs{k},'"',''); 
	end;
	lines = reshape(lines(:,1:(M-1))',(M-1)*n,1);
	segs = reshape(str2num(char(lines)),(M-1),n)';

% long format
else
	nSegs = str2num(lines{tierStart+3}(regexp(lines{tierStart+3},'\d'):end));
	M = (4 - isPoint);
	h = tierStart + 4;
	t = nSegs*M + h - 1;
	n = (t - h + 1) / M;
	lines = reshape(lines(h:t),M,n)';
	labs = lines(:,M);
	for k = 1 : length(labs),
		kk = findstr(labs{k},'"');
        try
            labs{k} = labs{k}(kk(1)+1:kk(2)-1);
        catch
           error('error attempting to load from %s', fName);
        end;
	end;
	lines = reshape(lines(:,2:(M-1))',(M-2)*n,1);
	idx = cell2mat(regexp(lines,' \d'));
	segs = zeros(length(lines),1);
	for k = 1 : length(lines),
		segs(k) = str2num(lines{k}(idx(k):end));
	end;
	segs = reshape(segs,(M-2),n)';
end;
end % end of ReadPraatTier1


%%
function [isShort, head, tail, nTiers]=DetectTextGridCellsLongOrShort(TGlineCells)
    %long or short?
try
	data = str2num(char(TGlineCells([4 5 7])));
	isShort = 1;
	if isempty(data),
		data(1) = str2num(TGlineCells{4}(8:end));
		data(2) = str2num(TGlineCells{5}(8:end));
		data(3) = str2num(TGlineCells{7}(8:end));
		isShort = 0;
	end;
catch
	error('%s has unrecognized file format', fName);
end;

head = data(1);
tail = data(2);
nTiers = data(3);
end % end of DetectTextGridCellsLongOrShort

function outTextGridLines=DetectStrainedQuotationSybol(TextGridLines)
%Weirong Chen  Sep-08-2015
%%
outTextGridLines = TextGridLines;
AnomalyLines=[FindWhich(TextGridLines,'" ') FindWhich(TextGridLines,'"')];
ToDelete=[];
if numel(AnomalyLines)>1
    for i = 1:numel(AnomalyLines)-1,
        if AnomalyLines(i) == AnomalyLines(i+1)-1, ToDelete=[ToDelete i];end;
    end;
end;
AnomalyLines(ToDelete) = [];
delLineNum=[];
for i = 1:numel(AnomalyLines),
    AnomalyLineNum=AnomalyLines(i);
    if AnomalyLineNum < 2, continue;end;
    preLineNum = []; 
    for j = AnomalyLineNum-1:-1:1
        oneLine = strrep(TextGridLines{j},' ','');
        if ~isempty(oneLine),
            preLineNum=j;
            outTextGridLines{j} = [outTextGridLines{j} '"'];
            break;
        end;
    end;
    if ~isempty(preLineNum), 
        delLineNum=[delLineNum preLineNum+1:AnomalyLineNum]; %#ok<AGROW>
    end;
end;
outTextGridLines(delLineNum)=[];
end %DetectStrainedQuotationSybol
function outTextGridLines=DetectStrainedQuotationSybol2(TextGridLines)
%Weirong Chen  Oct-02-2015
%%
outTextGridLines = TextGridLines;
ToDelete=[];
for i = 1:length(TextGridLines)-1;
    thisLine = TextGridLines{i};
    nextLine = TextGridLines{i+1};
    thisLine = strrep(thisLine,' ','');
    nextLine = strrep(nextLine,' ','');
    if strcmp(thisLine,'text="') && strcmp(nextLine(end),'"'),
        ToDelete = [ToDelete i+1];
        outTextGridLines{i} = [TextGridLines{i} TextGridLines{i+1}];
    end;
end;
outTextGridLines(ToDelete) = [];

end %DetectStrainedQuotationSybol

function encoding = DetectTextGridEncoding(TextGridFName)
% Detect the text encoding method of a PRAAT .TextGrid file.
% Usage: encoding = DetectTextGridEncoding(TextGridFName)
% 
% Weirong Chen    JAN-13-2014

[~,~,e]=fileparts(TextGridFName);
if isempty(e), TextGridFName=[TextGridFName '.TextGrid'];end;
encodings{1}='UTF-8';
encodings{2}='UTF-16BE';
encodings{3}='UTF-16LE';
encodingWeight=NaN*zeros(1,length(encodings));
wid='MATLAB:iofun:UnsupportedEncoding';
warning('off',wid);
for i=1:length(encodings)
    fid = fopen(TextGridFName, 'r', 'l', encodings{i});
    S = fscanf(fid, '%c');
    fclose(fid);
    out = strfind(S, 'Text');
    encodingWeight(i)=length(out);
end;

[~,idx]=max(encodingWeight);
encoding=encodings{idx};
warning('on',wid);
end %DetectTextGridEncoding
function C = textscanu_wr(filename, encoding)

% C = textscanu(filename, encoding) reads Unicode 
% strings from a file and outputs a cell array of strings. 
% 
% Syntax:
% -------
% filename - string with the file's name and extension
%                 example: 'unicode.txt'
% encoding - encoding of the file
%                 default: UTF-16LE
%                 examples: UTF16-LE (little Endian), UTF8.
%                 See http://www.iana.org/assignments/character-sets
%                 MS Notepad saves in UTF-16LE ('Unicode'), 
%                 UTF-16BE ('Unicode big endian'), UTF-8 and ANSI.

% 
% Example:
% -------
% C = textscanu_wr('unicode.txt', 'UTF8');
% Reads the UTF8 encoded file 'unicode.txt', which has
% columns and lines delimited by tabulators, respectively 
% carriage returns. Shows a waitbar to make the progress 
% of the functions action visible.
%
% Note:
% -------
% Matlab's textscan function doesn't seem to handle 
% properly multiscript Unicode files. Characters 
% outside the ASCII range are given the \u001a or 
% ASCII 26 value, which usually renders on the 
% screen as a box.
% 
% Additional information at "Loren on the Art of Matlab":
% http://blogs.mathworks.com/loren/2006/09/20/
% working-with-low-level-file-io-and-encodings/#comment-26764
% 
% Bug:
% -------
% When inspecting the output with the Array Editor, 
% in the Workspace or through the Command Window,
% boxes might appear instead of Unicode characters.
% Type C{1,1} at the prompt: you will see the correct
% string. Also: in Array Editor click on C then C{1,1}.
% 
% Matlab version: starting with R2006b
%
% Revisions:
% -------
% 2009.06.13 - added option to display a waitbar
% 2008.02.27 - function creation
% 
% Created by: Vlad Atanasiu / atanasiu@alum.mit.edu

switch nargin
    case 1
        encoding = 'UTF16-LE';
end
warning off MATLAB:iofun:UnsupportedEncoding;
% read input
fid = fopen(filename, 'r', 'l', encoding);
S = fscanf(fid, '%c'); A=abs(S);
fclose(fid);
% end of line symbol (CR=13, LF=10)
eol_sym1 = 13;% CR: carriage return
eol_sym2 = 10;% LF: line feed
% remove Byte Order Marker 
if A(1)==65279, S = S(2:end); A=abs(S);end;  %Byte Order Marker = 65279
% locates column delimitators and end of lines
eol1 = find(A == eol_sym1);
eol2 = find(A == eol_sym2);
if isempty(eol2) && ~isempty(eol1) 
    eol=eol1; eol_sym=eol_sym1; nCharEol=1;
elseif   isempty(eol1) && ~isempty(eol2) 
    eol=eol2; eol_sym=eol_sym2; nCharEol=1;
elseif ~isempty(eol1) && length(eol2)==length(eol1)
    B=eol2-eol1; 
    tt=find(B==1); if length(tt)==length(B),eol=eol1; nCharEol=2;eol_sym=[eol_sym1 eol_sym2];end;
    tt=find(B==-1); if length(tt)==length(B),eol=eol2; nCharEol=2;eol_sym=[eol_sym2 eol_sym1];end;
else
    eol=[eol1 eol2];eol=sort(eol);eol_sym=eol_sym2;
end;
% add an end of line mark at the end of the file
S = [S char(eol_sym)]; 
% get number of rows and columns in input
row = numel(eol);
C = cell(row,1); % output cell array
m = 1;
n = 1;
sos = 1;
% parse input
    % single column input
    for r = 1:row
        eos = eol(n) - 1;
        C(r,1) = {S(sos:eos)};
        n = n + 1;
        sos = eos + nCharEol+1;
    end
end % end of textscanu_wr
function n=FindWhich(StringCellArray, TargetString, nOutput)
% This funcion finds the 'TargetString' in a string cell array and returns
% the serial number of the element found in 'StringCellArray'.
% 'nOutput' = number of output elements.
% Weirong Chen    SEP-14-2013

sn=1:length(StringCellArray); A=cellismember(StringCellArray,TargetString); n=sn(A);
if nargin<3, return;end;
if numel(n)>0, n=n(1:nOutput);end;
end % FindWhich

%% required sub-functions: 
function Lia=cellismember(A,B) 
% The built-in "ismember" function in MATLAB fails to perform when the input variables are cells containing different types of variables.
% This function 'cellismember' is a function that performs 'ismember' on
%  cells with various data types.
%  The input A and B must be cell arrays.
%  Example: 
%  Input: A = {'ab','cd', NaN, [], 5, 1}; B = {[], 'cd', NaN, 1};
%  output: Lia = [0 1 1 1 0 1]; 
%
% Acknowledgement: 
% This function greatly benefits from Jan Simon's comments. The previous version was errorful. 
% See 'ismember' for more information
% Weirong Chen   Apr-16-2
% Update: Jun-1-2015015

if ~iscell(B) && ischar(B), B={B}; end; % Convert single value into 1x1 cell array of string
str_Index_A = cellfun('isclass', A, 'char');
str_Index_B = cellfun('isclass', B, 'char');
NaN_Index_A=logical(cell2mat(cellfun(@sum, cellfun(@isnan, A,'UniformOutput',false),'UniformOutput',false)));
NaN_Index_B=logical(cell2mat(cellfun(@sum, cellfun(@isnan, B,'UniformOutput',false),'UniformOutput',false)));
empty_Index_A=cellfun(@isempty, A);
empty_Index_B=cellfun(@isempty, B);
num_Index_A=cellfun(@isnumeric, A) & ~NaN_Index_A & ~empty_Index_A; % 'isnumeric' includes NaN and EMPTY.
num_Index_B=cellfun(@isnumeric, B) & ~NaN_Index_B & ~empty_Index_B; % 'isnumeric' includes NaN and EMPTY.
if sum(str_Index_A)>0 && sum(str_Index_B)>0 
    out_Index_str = str_Index_A;
    out_Index_str(str_Index_A)=ismember(A(str_Index_A),B(str_Index_B));
else 
    out_Index_str = false(size(A,1),size(A,2));
end;
if sum(num_Index_A)>0 && sum(num_Index_B)>0 
    out_Index_num = num_Index_A;
    out_Index_num(num_Index_A)=ismember(cell2mat(A(num_Index_A)),cell2mat(B(num_Index_B)));
else 
    out_Index_num = false(size(A,1),size(A,2));
end;
if sum(NaN_Index_A)>0 && sum(NaN_Index_B)>0 
    out_Index_NaN = NaN_Index_A;
else 
    out_Index_NaN = false(size(A,1),size(A,2));
end;
if sum(empty_Index_A)>0 && sum(empty_Index_B)>0 
    out_Index_empty = empty_Index_A;
else 
    out_Index_empty = false(size(A,1),size(A,2));
end;
Lia = out_Index_str  | out_Index_num | out_Index_NaN | out_Index_empty;
end %end of cellismember
