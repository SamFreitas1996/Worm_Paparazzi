% verify_dirlist.m
% Anthony Fouad
%
% After using the dir() command to get all files and folders, use this
% command to apply operations on the struct: 
%       1.      Remove bogus dot entries
%       2.      Keep folders only, (foldersflag==1), OR
%       2.      Keep files   only, (foldersflag==0)
%       3.      Specify a text search filter
%       4.      Specify a text NOT search filter
%       5.      Use sort_nat to "naturally" sort the file names, i.e. 
%               [A1 A10 A2]     -->     [A1 A2 A10]
%
% The input D can optionally be a full path length p.

function [D,N,ikeep,sortindex]=verify_dirlist(D,foldersflag,ftype,nottype,sortnatflag)

% Handle inputs
    if nargin < 2; foldersflag = 1; end
    if ~isstruct(D) 
        if ischar(D)
            D = dir(D);
        else
            error('dirlist D must be a struct!'); 
        end
    end
    
    if nargin < 5; sortnatflag = 1; end
   
% cycle through folder contents and set to keep or delete
    ikeep = 1:length(D);
    
    for i = length(D):-1:1
       
        % Exclude craps
        if D(i).name(1) == '.'; ikeep(i) = 0; end
        
        % Exclude wrong types
        if  D(i).isdir ~= foldersflag; ikeep(i) = 0; end
        
        % Exclude entries not containing requested string
        if nargin > 2
            if ~isempty(ftype)
                if ~contains(upper(D(i).name),upper(ftype))
                    ikeep(i)    = 0;
                end                
            end
        end
        
        % Exclude entries containing refused string
        if nargin > 3 
            if ~isempty(nottype)
                if contains(upper(D(i).name),upper(nottype))
                    ikeep(i)    = 0;            
                end                
            end
        end
    end
    
% Perform exclusions  
    D(~ikeep) = [];

% Count the number of files too
    N = numel(D);
    
% Apply natural sorting if requested
    if sortnatflag
        [D,sortindex] = sort_nat_struct(D,N);
    end
    
% Put together the full file names of each file for convenience
    for n = 1:N
        D(n).fullname = fullfile(D(n).folder,D(n).name);
    end
end


