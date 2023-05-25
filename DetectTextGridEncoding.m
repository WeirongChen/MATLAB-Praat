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