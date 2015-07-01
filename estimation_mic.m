function demand = estimation_mic( targetResources,returnedMetric,targetMetric,method,parameters, obj, mode, dc )

demand = -1;
metrics = dc.checkEstimationMetric();

if isempty(metrics)
    return;
end

it = metrics.entrySet().iterator();
while (it.hasNext)
    clearvars -except returnedMetric targetMetric method parameters obj mode dc demand metrics it
    pair = it.next();
    targetResources = pair.getValue();
    
    data_format = [];
    category_index = 1;
    category_count = 1;
    mapObj = containers.Map;
    
    for i = 1:targetResources.size
        temp_str = obj.obtainData(targetResources.get(i-1),targetMetric);
        
        if isempty(temp_str)
            demand = -1;
            disp('No data received')
            return;
        end
        
        values = temp_str.getValues;
        timestamps = temp_str.getTimestamps;
        
        for j = 0:values.size-1
            str = values.get(j);
            value = str2double(str);
            ts = str2double(timestamps.get(j));
            
            category_str = char(targetResources.get(i-1));
            
            if isKey(mapObj, category_str) == 0
                mapObj(category_str) = category_index;
                category_list{1,category_count} = category_str;
                category_count = category_count + 1;
                
                category = category_index;
                data_format{6,category}=[];
                category_index = category_index + 1;
            else
                category = mapObj(category_str);
            end
            
            %         if strcmp(split_str(10),'Request Begun')
            %             continue;
            %         end
            response_time = value;
            data_format{3,category} = [data_format{3,category};ts];
            data_format{4,category} = [data_format{4,category};response_time/1000];
        end
    end
    rawData = data_format;
    rawData{3, category_index} = [];
    warmUp = 0;
    
    if strcmp(mode,'tower4clouds')
        if ~isempty(parameters.get('window'))
            window = str2double(parameters.get('window'))*1000;
        end
        if ~isempty(parameters.get('warmUp'))
            warmUp = str2double(parameters.get('warmUp'));
        end
        if ~isempty(parameters.get('nCPU'))
            nCPU = str2double(parameters.get('nCPU'));
        end
        if ~isempty(parameters.get('avgWin'))
            avgWin = str2double(parameters.get('avgWin'));
        end
        if ~isempty(parameters.get('maxTime'))
            maxTime = str2double(parameters.get('maxTime'));
        end
        if ~isempty(parameters.get('CPUUtilTarget'))
            cpuUtilTarget = char(parameters.get('CPUUtilTarget'));
        end
        if ~isempty(parameters.get('CPUUtilMetric'))
            cpuUtilMetric = char(parameters.get('CPUUtilMetric'));
        end
    else
        for i = 1:size(parameters,1)
            switch parameters{i,1}
                case 'window'
                    window = str2double(parameters{i,2});
                case 'warmUp'
                    warmUp = str2double(parameters{i,2});
                case 'nCPU'
                    nCPU = str2double(parameters{i,2});
                case 'avgWin'
                    avgWin = str2double(parameters{i,2});
                case 'maxTime'
                    maxTime = str2double(parameters{i,2});
                case 'cpuUtilTarget'
                    cpuUtilTarget = char(parameters{i,2});
                case 'cpuUtilMetric'
                    cpuUtilMetric = char(parameters{i,2});
            end
        end
    end
    
    rawData
    cpu = obj.obtainData(cpuUtilTarget,cpuUtilMetric);
    if isempty(cpu)
        demand = -1;
        disp('No CPU data received')
        [data,category_list] = dataFormat(rawData,window,category_list);
    else
        cpu_value = convertArrayList(cpu.getValues);
        cpu_timestamps = convertArrayList(cpu.getTimestamps);

        length_cpu_value = length(cpu_value);
        length_cpu_timestamps = length(cpu_timestamps);

        if length_cpu_value > length_cpu_timestamps
            cpu_value(length_cpu_timestamps+1:length_cpu_value)=[];
        end

        if length_cpu_value < length_cpu_timestamps
            cpu_timestamps(length_cpu_value+1:length_cpu_timestamps)=[];
        end
        [data,category_list] = dataFormat(rawData,window,category_list,cpu_value,cpu_timestamps);
    end
    
    data
    for i = 1:size(data,2)-1
        mean(data{6,i})
    end
    data{2,end}
    save('SDAData.mat','data','rawData','window','category_list');
    
    switch method
        case 'ci'
            demand = ci(data,warmUp,0,nCPU);
        case 'fcfs'
            demand = fcfs(data,nCPU,avgWin);
        case 'ubo'
            demand = ubo(data,maxTime);
        case 'ubr'
            demand = ubr(data,nCPU);
        case 'otherwise'
            warning('Unexpected method. No demand generated.');
    end
    
    for i = 1:targetResources.size
        try
            targetResources.get(i-1)
            strcat(targetResources.get(i-1),': ',num2str(demand(i)))
            %dcAgent.sendSyncMonitoringDatum(num2str(demand(i)),returnedMetric,targetResources{1,i});
            dcAgent = dc.dcAgent();
            dcAgent.send(dc.createResource(targetResources.get(i-1)),returnedMetric,demand(i));
        catch err
            disp(getReport(err,'extended'));
            disp('could not send data to dda')
        end
    end
    
end

demand = -1;
