function newMatrix=aggregate(matrix,rowstep)
% AGGREGATE Sums the rows of a matrix in steps of fixed size 
%
% [A] = AGGREGATE(M,S) sums the rows of the matrix M in steps of size S, and 
% returns the resulting matrix A 
% 
% 
% Copyright (c) 2012-2013, Imperial College London 
% All rights reserved.


[n,m]=size(matrix);
if n==1 || m==1
    matrix=matrix(:);
end

newrows=ceil(size(matrix,1)/rowstep);
newMatrix=zeros(newrows,size(matrix,2));

for i=1:newrows
    s=matrix((1+(i-1)*rowstep):min([i*rowstep,size(matrix,1)]),:);
    newMatrix(i,:)=sum(s);
end

end