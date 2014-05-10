function demand = estimation( targetResources,targetMetric,parameters, obj )

data_format = [];
category_index = 1;
category_count = 1;
mapObj = containers.Map;

temp_str = obj.obtainData(targetResources,targetMetric);

if isempty(temp_str)
    demand = -1;
    disp('No data received')
    return;
end

values = temp_str.getValues;

for j = 0:values.size-1
    str = values.get(j);
    str = java.lang.String(str);
    split_str = str.split(',');
    dateFormat = java.text.SimpleDateFormat('yyyyMMddHHmmssSSS');
    
    date_str = '';
    
    for k = 1:7
        date_str = strcat(date_str,char(split_str(k)));
    end
    
    try
        date = dateFormat.parse(date_str);
    catch e
        e.printStackTrace();
    end
    
    date_milli = date.getTime();
    
    jobID = char(split_str(8));
    
    category_str = char(split_str(9));
    
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
    
    if strcmp(split_str(10),'Request Begun')
        continue;
    end
    response_time = str2double(char(split_str(11)));
    data_format{3,category} = [data_format{3,category};date_milli-response_time*1000];
    data_format{4,category} = [data_format{4,category};response_time];
end

rawData = data_format;
rawData{3, category_index} = [];

it_parameter = parameters.iterator();
while (it_parameter.hasNext)
    parameter = it_parameter.next;
    switch char(parameter.getName)
        case 'window'
            window = str2double(parameter.getValue);
        case 'warmUp'
            warmUp = str2double(parameter.getValue);
        case 'nCPU'
            nCPU = str2double(parameter.getValue);
        case 'avgWin'
            avgWin = str2double(parameter.getValue);
        case 'maxTime'
            maxTime = str2double(parameter.getValue);
        case 'cpuUtilTarget'
            cpuUtilTarget = char(parameter.getValue);
        case 'cpuUtilMetric'
            cpuUtilMetric = char(parameter.getValue);
        case 'method'
            method = char(parameter.getValue);
    end
end


%FIX: obtain cpu value
cpu = obj.obtainData(cpuUtilTarget,cpuUtilMetric);
cpu_value = convertArrayList(cpu.getValues);
cpu_timestamps = convertArrayList(cpu.getTimestamps);

[data,category_list] = dataFormat(rawData,window,category_list,cpu_value,cpu_timestamps);

switch method
    case 'ci'
        demand = ci(data,nCPU,warmUp);
    case 'fcfs'
        demand = fcfs(data,nCPU,avgWin);
    case 'ubo'
        demand = ubo(data,maxTime);
    case 'ubr'
        demand = ubr(data,nCPU);
    case 'otherwise'
        warning('Unexpected method. No demand generated.');
end

