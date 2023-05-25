function DeletePraatTier(tgFName, tier)
% 'tgFName': TextGrid filename.
% Weirong Chen  Apr-21-2015
TextGrid = ReadTextGrid(tgFName);
n = FindWhich({TextGrid.NAME},{tier});
TextGrid(n)=[];
Write2TextGrid(TextGrid, tgFName);
end % 

function n=FindWhich(StringCellArray, TargetString)
% This funcion finds the 'TargetString' in a string cell array and returns
% the serial number of the element found in 'StringCellArray'.
% Weirong Chen    SEP-14-2013
sn=1:length(StringCellArray); A=cellismember(StringCellArray,TargetString); n=sn(A);
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
% Weirong Chen   Apr-16-2015

if ~iscell(B) && numel(B) <2, B={B}; end; % Convert single value into 1x1 cell array of string
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
end
