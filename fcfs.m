function [demEst] = fcfs(data,nCPU,avgWin)
% FCFS Statistical data analyzer (SDA) based on a First-Come-First-Serve 
% description of the processing station.  
%
% D = FCFS(data,nCPU,avgWin) reads the data and configuration 
% parameters from the input parameters, estimates the resource
% demand for each request class and returns it on D. 
%
% Configuration file fields:
% data:         the input data for the SDA
% nCPU:         number of CPUs on which the application is deployed
% avgWin:       number of samples in each averaging window 
% 
%
% Copyright (c) 2012-2013, Imperial College London 
% All rights reserved.
% This code is released under the 3-Clause BSD License. 

%%
if exist('data','var') == 0
    disp('No data provided specified. Terminating without running SDA.');
    meanST = [];
    obs = [];
    return;
end

if exist('nCPU','var') ~= 0
    V = nCPU;
else
    disp('Number of CPUs not specified. Using default: 1.');
    V = 1;
end 
% SDA parameters
if exist('avgWin','var') ~= 0
    avgWinSize = floor(avgWin);
    if avgWinSize <= 0 
        disp('Averaging window size must be positive. Terminating without running SDA.');
        demEst = [];
        return;
    end
else
    disp('Averaging window size not specified. Using default: 10.');
    avgWinSize = 10;
end 


%%
% prepare input data
[~, ~, aTimes, rTimes, ~, ~] = parseDataFormat(data);
R = size(aTimes, 2); % number of classes

% arrival times
aTimesClass = [];
for r=1:R
    class((length(aTimesClass)+1):(length(aTimesClass) + length(aTimes{r}))) = r;
    aTimesClass = [aTimesClass; aTimes{r}, aTimes{r}+rTimes{r}*1e3, r*ones(size(aTimes{r})), [(length(aTimesClass)+1):(length(aTimesClass) + length(aTimes{r}))]'];
end
[~,I]=sort(aTimesClass(:,1));
aTimesClass = aTimesClass(I,:);
class = class(I);

%% find jobs in queue at arrival instants
aqid = {};
for j=1:size(aTimesClass,1)
    aTime = aTimesClass(j,1);
    % jobs arrived before j joins the queue and leaving after
    aheadInQueue = find(aTimesClass(:,1) < aTime & aTimesClass(:,2) >= aTime);
    aqid{j,1} = aTimesClass(aheadInQueue,4);
end

%%
aQueue=[]; % number of jobs per class in queue at arrival instants
for i=1:size(aqid,1)
    aqueue=class(aqid{i});
    aQueue(end+1,:)=zeros(1,R);
    for r=1:length(aqueue)
        aQueue(end,aqueue(r))=aQueue(end,aqueue(r))+1;
    end
    aQueue(end,class(i))=aQueue(end,class(i))+1;
end

%% regression for multi-class FCFS
X=[];
Y=[];
for r=1:R
    X = [X; aggregate(aQueue(class == r, :), avgWinSize)/V]; 
    Y = [Y; aggregate(aTimesClass(class == r, 2) - aTimesClass(class == r, 1), avgWinSize)];
end
demEst = lsqnonneg(X,Y);

%save(output_filename, 'demEst', '-ascii');
end