% sort_nat_struct.m
% Anthony Fouad
%
% Wrapper for sort_nat, adapting it to struct arrays returned by dir. 

function [d_sort,index] = sort_nat_struct(d,N,mode)

% Handle inputs
    if nargin < 3; mode = 'ascend';     end

% Transform the file name struct into a cell array of file names
    c = cell(N,1);
    
    for n = 1:N
        c{n} = d(n).name;
    end

% run this cell through sort_nat to get the sort indices    
    [~,index] = sort_nat(c,mode);
    
% resort the struct array according to these indices
    d_sort = d(index);
    
end