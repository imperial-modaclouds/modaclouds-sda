function demandEst = ci(data, initSample, sampleSize, V, W)
% CI Complete Information statistical data analyzer (SDA).  
% This SDA is based on the method proposed in 
% Pérez, J.F., Pacheco-Sanchez, S. and Casale, G. 
% An Offline Demand Estimation Method for Multi-Threaded Applications. 
% Proceedings of MASCOTS 2013, 2013
%
% D = CI(data,nCPU,warmUp) reads the data and configuration 
% parameters from the input parameters, estimates the resource
% demand for each request class and returns it on D. 
%
% Configuration file fields:
% data:         the input data for the SDA
% nCPU:         number of CPUs on which the application is deployed
% warmUp:       initial number of samples to avoid when running the SDA
% 
% 
% Copyright (c) 2012-2013, Imperial College London 
% All rights reserved.
% This code is released under the 3-Clause BSD License. 


if nargin < 5
    W = 1000;
end

K = size(data,2)-1;
times = cell(1,K);
for k = 1:K
    times{k} = [data{3,k}/1000 data{4,k}];
end

[demandEst,obs] = des_CI(times, initSample, sampleSize,W,V);