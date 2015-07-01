function [meanST,obs] = des_CI(times, initSample, sampleSize,W,V)
% DES_CI implements the CI demand estimation method
% 
% times: arrival and response times in proper format as follows
%       cell with as many entries as job classes
%       cell k contains an m_k times 2 array, where
%       m_k is the number of obsrevations for type k jobs
%       the first column holds the arrival times stamps 
%       the second column holds the response times
%       both columns must be in the same time measure (e.g. s or ms)
%       returns the mean service times meanST per class
% initSample:   first sample to consider 
% sampleSize:   number of samples to use for anaysis
% W:            max number of jobs in service
% V:            number of processors
%
% Copyright (c) 2012-2014, Imperial College London 
% All rights reserved.


K = length(times);


%compute departure times and ids
id = 1;
for k = 1:K
    for i = 1:size(times{k},1)
        times{k}(i,3) = times{k}(i,1) + times{k}(i,2); % departure time
        times{k}(i,4) = id;  % ID
        id = id + 1; 
    end
end

%build array with all events
%first column: time
%second column: 0-arrival, 1-departure
%third column: class
%fourth column: arrival time (only for departures)
%fifth column: job id
timesOrder = [];
for k = 1:K
    if size(times{k},2) > 2
    %arrivals
    timesOrder = [timesOrder; 
        [times{k}(:,1) zeros(size(times{k},1),1) k*ones(size(times{k},1),1) zeros(size(times{k},1),1) times{k}(:,4)]
        ];
    %departures
    timesOrder = [timesOrder; 
        [times{k}(:,3) ones(size(times{k},1),1) k*ones(size(times{k},1),1) times{k}(:,1) times{k}(:,4)]
        ];
    end
end

%order events according to time of  
timesOrder = sortrows(timesOrder,1);

%t = timesOrder(warmUp+1,1); %clock
t = 0;
%STATE
 % each row corresponds to a current job
 % first column:  the class of the job
 % second column: the arrival time
 % third column: the elapsed service time
 % fourth column: job id
state = [];

%t = timesOrder(1,1); %clock
told = t;

%ACUM
% number of service completions observed for each class (row)
% and total service time per class (second column)
acum = zeros(K,2);
obs = cell(1,K); %holds all the service times observed

%advance until initSample observations
i = 1;
while sum(acum(:,1)) < initSample-1
    %acum(:,1)
    t = timesOrder(i,1);
    telapsed = t - told;
    n = size(state,1);

    % add to each job in process the service time elapsed (divided 
    % by the portion of the server actually dedicated to it in a PS server
    r = min(n,W);
    for j = 1:r
        state(j,3) = state(j,3) + telapsed/r;
    end

    %if the event is an arrival add the job to teh state
    if timesOrder(i,2) == 0
        state = [state; [timesOrder(i,3) t 0 timesOrder(i,5)] ];
    else
        %find job in progress that must leave - by ID
        %k = 1; while state(k,2) ~= timesOrder(i,4); k = k+1; end 
        k = 1; while state(k,4) ~= timesOrder(i,5); k = k+1; end 
        %update stats
        acum(state(k,1),1) = acum(state(k,1),1) + 1;
        acum(state(k,1),2) = acum(state(k,1),2) + state(k,3);
        %obs{state(k,1)} = [obs{state(k,1)}; state(k,3)];
        
        %update state
        state = [state(1:k-1,:); state(k+1:end,:)];
    end
    i = i + 1;
    told = t;
end

%actually sampled data
acum = zeros(K,2);
obs = cell(1,K); %holds all the service times observed

if sampleSize == 0
    sampleSize = round(size(timesOrder,1)/2);
end

while sum(acum(:,1)) < sampleSize%size(timesOrder,1)
    t = timesOrder(i,1);
    telapsed = t - told;
    n = size(state,1);

    % add to each job in process the service time elapsed (divided 
    % by the portion of the server actually dedicated to it in a PS server
    r = min(n,W);
    for j = 1:r
        if r <= V %at most as many jobs in service as processors
            state(j,3) = state(j,3) + telapsed;
        else %more jobs in service than processors
            state(j,3) = state(j,3) + telapsed*V/r;
        end
    end

    %if the event is an arrival add the job to the state
    if timesOrder(i,2) == 0
        state = [state; [timesOrder(i,3) t 0 timesOrder(i,5)] ];
    else
        %find job in progress that must leave - by ID
        k = 1; while state(k,4) ~= timesOrder(i,5); k = k+1; end 
        %update stats
        acum(state(k,1),1) = acum(state(k,1),1) + 1;
        acum(state(k,1),2) = acum(state(k,1),2) + state(k,3);
        obs{state(k,1)} = [obs{state(k,1)}; state(k,3)];
        %update state
        state = [state(1:k-1,:); state(k+1:end,:)];
    end
    i = i+1;
    told = t;
end
meanST = (acum(:,2)./acum(:,1))';



end