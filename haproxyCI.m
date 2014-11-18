function [demand,count_file] = haproxyCI( targetResources,targetMetric,parameters, obj, mode, dcAgent, returnedMetric, period, fileID, count_file )

tic
delete = [];
for i = 1:size(targetResources,2)
    if isempty(targetResources{1,i})
        delete = [delete,i];
    end
end
targetResources(delete) = [];

targetResources = sort(targetResources);
N_haproxy = size(targetResources,2);

flag = 0;
for i = 1:N_haproxy
    temp_str{1,i} = obj.obtainData(targetResources{1,i},targetMetric);
    
    if isempty(temp_str{1,i})
        demand = -1;
        disp(strcat('No data received from target resources: ',targetResources{1,i}))
        return
    else
        flag = 1;
    end
end

if flag == 0
    return;
end

fprintf(fileID,'First check: %s\n',toc);

% clear

import java.io.File;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
% 
if strcmp(mode,'kb')
    if ~isempty(parameters.get('window'))
        window = str2double(parameters.get('window'));
    else
        window = 60000;
    end
    if ~isempty(parameters.get('warmUp'))
        warmUp = str2double(parameters.get('warmUp'));
    else
        warmUp = 0;
    end
    if ~isempty(parameters.get('nCPU'))
        nCPU = char(parameters.get('nCPU'));
        nCPU = str2num(nCPU);
    end
    if ~isempty(parameters.get('avgWin'))
        avgWin = str2double(parameters.get('avgWin'));
    end
    if ~isempty(parameters.get('maxTime'))
        maxTime = str2double(parameters.get('maxTime'));
    end
    if ~isempty(parameters.get('cpuUtilTarget'))
        cpuUtilTarget = char(parameters.get('cpuUtilTarget'));
    end
    if ~isempty(parameters.get('cpuUtilMetric'))
        cpuUtilMetric = char(parameters.get('cpuUtilMetric'));
    end
    if ~isempty(parameters.get('filePath'))
        filePath = char(parameters.get('filePath'));
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
                nCPU = str2num(nCPU);
            case 'avgWin'
                avgWin = str2double(parameters{i,2});
            case 'maxTime'
                maxTime = str2double(parameters{i,2});
            case 'cpuUtilTarget'
                cpuUtilTarget = char(parameters{i,2});
            case 'cpuUtilMetric'
                cpuUtilMetric = char(parameters{i,2});
            case 'method'
                method = char(parameters{i,2});
        end
    end
end

% save('test.mat','str_cell','N_haproxy','warmUp','nCPU')
% 
% 
% if ~strcmp(method,'ci')
%     cpu = obj.obtainData(cpuUtilTarget,cpuUtilMetric);
%     cpu_value = convertArrayList(cpu.getValues);
%     cpu_timestamps = convertArrayList(cpu.getTimestamps);
% end
% method = 'ci'
% warmUp = 0
% nCPU = [1,1,2,4];
% 
% 
% path = 'haproxy22.log';
% file = RandomAccessFile( path, 'r' );
% file.seek( 0 );
% line = file.readLine;


try 
    load(strcat(filePath,'LBData.mat'))
    disp('Previous data loaded')
catch
    old_value = zeros(1,N_haproxy);
    categoryList = ArrayList;
    serverIDList = cell(1,2);
    frontendList = ArrayList; 
    serverIDListAll = ArrayList;
    sessionIDList = cell(1,N_haproxy);
    data = cell(N_haproxy,4);
    sessionsList = cell(1,N_haproxy);
    requestTimes = cell(1,N_haproxy);
end
frontendResourceMap = HashMap;
data_session = cell(1,N_haproxy);
sessionTimes = cell(1,N_haproxy);
thinkTimes = cell(1,N_haproxy);

    
% expression=['(\w+ \d+ \S+) (\S+) (\S+)\[(\d+)\]: (\S+):(\d+) \[(\S+)\] ' ...
%     '(\S+) (\S+)/(\S+) (\S+) (\S+) (\S+) *(\S+) (\S+) (\S+) (\S+) (\S+) '...
%     '"(\S+) ([^"]+) (\S+)" *$'];
expression=['(\w+\s*\d+ \S+) (\S+) (\S+)\[(\d+)\]: (\S+):(\d+) \[(\S+)\] ' ...
    '(\S+) (\S+)/(\S+) (\S+) (\S+) (\S+) *(\S+) (\S+) (\S+) (\S+) (\S+) '...
    '(\S+) ([^"]+) (\S+) *$'];

for k = 1:N_haproxy
    
    if isempty(temp_str{1,k})
        continue;
    end
    
    values = temp_str{1,k}.getValues;
    
    for j = old_value(k):values.size-1
        str = values.get(j);

%     line = []
%     flag = 0;
%     %if isempty(line) && flag == 0
%         flag = 1;
%         path = 'C:\Users\think\Desktop\haproxy.log';
%         %path = 'D:\Dropbox\Modaclouds-SDA\haproxy2.log';
%         file = RandomAccessFile( path, 'r' );
%         file.seek( 0 );
%         for j = 0:9900
%         line = file.readLine;   
%         str = line;
        
        output = regexp(char(str),expression,'tokens');

        if isempty(output)
            continue
        end

        if ~isempty(strfind(output{1,1}{1,14},'JSESSIONID'))

            frontend = java.lang.String(strrep(output{1,1}{1,9},'~',''));

            if ~frontendList.contains(frontend)
                frontendList.add(frontend);
                frontendID = frontendList.indexOf(frontend) + 1;
                serverIDList{1,frontendID} = ArrayList;
                sessionIDList{1,frontendID} = ArrayList;
                sessionsList{1,frontendID} = ArrayList;
            end
            frontendResourceMap.put(frontend,targetResources{1,k});
            frontendID = frontendList.indexOf(frontend) + 1;
            thinkTimes{1,frontendID} = zeros(1,2);
            if isempty(sessionIDList{1,frontendID})
                sessionIDList{1,frontendID} = ArrayList;
            end
            if isempty(sessionsList{1,frontendID})
                sessionsList{1,frontendID} = ArrayList;
            end
            frontendID = frontendList.indexOf(frontend) + 1;

            server = java.lang.String(output{1,1}{1,10});
            if ~serverIDList{1,frontendID}.contains(server)
                serverIDList{1,frontendID}.add(server);
            end
            if ~serverIDListAll.contains(server)
                serverIDListAll.add(server);
            end
            serverIDAll = serverIDListAll.indexOf(server) + 1;
            serverID = serverIDList{1,frontendID}.indexOf(server) + 1;

            str_cookie = java.lang.String(output{1,1}{1,14});
            str = java.lang.String(output{1,1}{1,20});

            if str.contains(java.lang.String('.css'))
                continue;
            end

            if str.contains(java.lang.String(';jsessionid'))
                categoryName = str.substring(0,str.indexOf(';jsessionid'));
            else
                categoryName = str;
            end

            if categoryName.equals(java.lang.String('/ecommerce/'))
                continue
            end

            sessionID = char(str_cookie.substring(str_cookie.indexOf('JSESSIONID=')+11));

            if ~categoryList.contains(categoryName)
                categoryList.add(categoryName);
            end

            categoryIndex = categoryList.indexOf(categoryName) + 1;

            df = SimpleDateFormat('dd/MMM/yyyy:HH:mm:ss.S');
            date = df.parse(output{1,1}{1,7});
            arrival = date.getTime;

            str = java.lang.String(output{1,1}{1,11});
            response = str2double(str.substring(str.lastIndexOf('/')+1))/1000;

            if size(data{1,serverIDAll},2) < categoryIndex
                data{1,serverIDAll}{6,categoryIndex} = [];
            end

            data{1,serverIDAll}{3,categoryIndex} = [data{1,serverIDAll}{3,categoryIndex};arrival];
            data{1,serverIDAll}{4,categoryIndex} = [data{1,serverIDAll}{4,categoryIndex};response];

            if sessionIDList{1,frontendID}.contains(sessionID)
                index = sessionIDList{1,frontendID}.indexOf(sessionID);
                sessionsList{1,frontendID}.get(index).add(categoryIndex-1);
                requestTimes{1,frontendID}{1,index+1} = [requestTimes{1,frontendID}{1,index+1},[arrival;arrival+response*1000]];
                %sessionTimes{1,frontendID}(index+1,2) = arrival + response*1000;
                %thinkTimes{1,frontendID}(index+1,2) = thinkTimes{1,frontendID}(index+1,2) + arrival - thinkTimes{1,frontendID}(index+1,1);
                %thinkTimes{1,frontendID}(index+1,1) = arrival + response*1000;
            else
                sessionIDList{1,frontendID}.add(sessionID);
                temp = ArrayList;
                temp.add(categoryIndex-1);
                sessionsList{1,frontendID}.add(temp);
                index = sessionIDList{1,frontendID}.indexOf(sessionID);
                requestTimes{1,frontendID}{1,index+1} = [arrival;arrival+response*1000];
                sessionStart{1,frontendID}(index+1) = arrival;
                %sessionTimes{1,frontendID}(index+1,1) = arrival;
                %thinkTimes{1,frontendID}(index+1,1) = arrival+response*1000;
            end
        end
    end
    old_value(k) = values.size;
end

fprintf(fileID,'Second check: %s\n',toc);


% clear
% load('workspace.mat')
% N_haproxy=2;
% data_session = cell(1,N_haproxy);

for s = 1:frontendList.size

    [~,index_session{1,s}] = sort(sessionStart{1,s});


    for i = 1:sessionIDList{1,s}.size
        [requestTimes{1,s}{1,i}(1,:),index] = sort(requestTimes{1,s}{1,i}(1,:));
        requestTimes{1,s}{1,i}(2,:) = requestTimes{1,s}{1,i}(2,index);

        sessionsList_temp = ArrayList;
        for j = 1:sessionsList{1,s}.get(i-1).size
            sessionsList_temp.add(sessionsList{1,s}.get(i-1).get(j-1));
        end
        for j = 1:sessionsList{1,s}.get(i-1).size
            sessionsList_temp.set(j-1,sessionsList{1,s}.get(i-1).get(index(j)-1));

            thinkTimes{1,s}(i,1) = 0;
            if j > 1
                thinkTimes{1,s}(i,1) = thinkTimes{1,s}(i,1) + requestTimes{1,s}{1,i}(1,j)-requestTimes{1,s}{1,i}(2,j-1);
            end
        end
        sessionsList{1,s}.set(i-1,sessionsList_temp);

        sessionTimes{1,s}(i,1) = requestTimes{1,s}{1,i}(1,1);
        sessionTimes{1,s}(i,2) = requestTimes{1,s}{1,i}(2,end);

    end
end

max_length = 0;

for i = 1:size(data,2)
    if ~isempty(data{1,i})
        data{1,i}{2,size(data{1,i},2)+1} = [];
        server_id = serverIDListAll.get(i-1);
        index = str2double(strrep(server_id,'ofbiz',''));
        [D_request{1,i},~] = ci(data{1,i},1,warmUp);
        %[D_request{1,i},~] = ci(data{1,i},nCPU(index),warmUp);
        
        %             switch method
        %                 case 'ci'
        %                     [D_request{s,i},~] = ci(data{s,i},nCPU(i),warmUp);
        %                 case 'fcfs'
        %                     %[data{s,i}] = dataFormat(data{s,i},window,[],cpu_value,cpu_timestamps);
        %                     D_request{s,i} = fcfs(data{s,i},nCPU(i),avgWin);
        %                 case 'ubo'
        %                     %[data{s,i}] = dataFormat(data{s,i},window,[],cpu_value,cpu_timestamps);
        %                     D_request{s,i} = ubo(data{s,i},maxTime);
        %                 case 'ubr'
        %                     %[data{s,i}] = dataFormat(data{s,i},window,[],cpu_value,cpu_timestamps);
        %                     D_request{s,i} = ubr(data{s,i},nCPU(i));
        %                 case 'otherwise'
        %                     warning('Unexpected method. No demand generated.');
        %             end
        if max_length < length(D_request{1,i})
            max_length = length(D_request{1,i});
        end
    end
end

fprintf(fileID,'Third check: %s\n',toc);


D_request

hasValue = zeros(1,max_length);
count_hasValue = zeros(1,max_length);
for j = 1:max_length
    for i = 1:size(D_request,2)
        if isempty(D_request{1,i})
            continue;
        end
        if length(D_request{1,i}) >= j
            if ~isnan(D_request{1,i}(j))
                hasValue(j) = hasValue(j) + D_request{1,i}(j);
                count_hasValue(j) = count_hasValue(j) + 1;
            end
        end
    end
end

for i = 1:size(D_request,2)
    if isempty(D_request{1,i})
        D_request{1,i} = hasValue./count_hasValue;
        D_request{1,i} = D_request{1,i}';
        continue;
    end
    for j = 1:length(D_request{1,i})
        if isnan(D_request{1,i}(j))
            D_request{1,i}(j) = hasValue(j)/count_hasValue(j);
        end
    end
    if length(D_request{1,i}) < max_length
        for j = length(D_request{1,i})+1:max_length
            D_request{1,i}(j) = hasValue(j)/count_hasValue(j);
        end
    end
end


uniSessions = cell(1,frontendList.size);
for s = 1:frontendList.size
    uniSessions{1,s} = ArrayList;

    uniSessions{1,s}.add(sessionsList{1,s}.get(0));
    for i = 0:sessionsList{1,s}.size - 1
        flag = 0;
        for j = 0:uniSessions{1,s}.size - 1
            %sessionsList{1,s}.get(i)
            %uniSessions{1,s}.get(j)
            if sessionsList{1,s}.get(i).equals(uniSessions{1,s}.get(j))

                if size(data_session{1,s},2) < j+1
                    data_session{1,s}{7,j+1} = [];
                end
                data_session{1,s}{3,j+1} = [data_session{1,s}{3,j+1};sessionTimes{1,s}(index_session{1,s}(i+1),1)];
                data_session{1,s}{4,j+1} = [data_session{1,s}{4,j+1};(sessionTimes{1,s}(index_session{1,s}(i+1),2)-sessionTimes{1,s}(index_session{1,s}(i+1),1))/1000];
                data_session{1,s}{7,j+1} = [data_session{1,s}{7,j+1};thinkTimes{1,s}(index_session{1,s}(i+1),1)];
                flag = 1;
                break;
            end
        end
        if flag == 0
            uniSessions{1,s}.add(sessionsList{1,s}.get(i)); 
            if size(data_session{1,s},2) < uniSessions{1,s}.size
                data_session{1,s}{7,uniSessions{1,s}.size} = [];
            end
            data_session{1,s}
            data_session{1,s}{3,j+2} = [data_session{1,s}{3,j+2};sessionTimes{1,s}(index_session{1,s}(i+1),1)];
            data_session{1,s}{4,j+2} = [data_session{1,s}{4,j+2};(sessionTimes{1,s}(index_session{1,s}(i+1),2)-sessionTimes{1,s}(index_session{1,s}(i+1),1))/1000];
            data_session{1,s}{7,j+2} = [data_session{1,s}{7,j+2};thinkTimes{1,s}(index_session{1,s}(i+1),1)];
        end
    end
end

for s = 1:frontendList.size
    count = 0;
    delete = [];
    max_length = length(data_session{1,s}{3,1});
    for i = 2:size(data_session{1,s},2)
        if length(data_session{1,s}{3,i}) > max_length
            max_length = length(data_session{1,s}{3,i});
        end
    end

    if size(data_session{1,s},2) > 2
        for i = 1:size(data_session{1,s},2)
            if length(data_session{1,s}{3,i}) < max_length
                delete = [delete,i];
                uniSessions{1,s}.remove(i-count-1);
                count = count + 1;
            end
        end

        if size(data_session{1,s},2) > 1
            data_session{1,s}(:,delete) = [];
        end
    end
    
    data_session{1,s}{2,size(data_session{1,s},2)+1} = zeros(10,1);
    data_session{1,s} = dataFormat(data_session{1,s},window);
end

save('/home/ubuntu/workspace.mat','sessionStart','requestTimes','D_request','serverIDListAll','sessionsList','data','sessionIDList','frontendID','frontendList','nCPU','warmUp','N_haproxy','data_session','uniSessions')

fprintf(fileID,'Fourth check: %s\n',toc);

time = 7;
try
    for s = 1:frontendList.size
        for i = 1:uniSessions{1,s}.size
            temp = [];
            temp{3,1} = data_session{1,s}{3,i};
            temp{4,1} = data_session{1,s}{4,i};
            temp{2,2} = zeros(10,1);
            [~,D_session_detail] = ci(temp,1);
            N(s,i) = max(D_session_detail{1,1}(:,3));
            R(s,i) = mean(data_session{1,s}{5,i});
            X(s,i) = mean(data_session{1,s}{6,i});

            if length(data_session{1,s}{6,i}) <= time
                X_period(s,i) = mean(data_session{1,s}{6,i});
            else
                X_period(s,i) = mean(data_session{1,s}{6,i}(end-time:end-1,:));
            end
            Z_request(s,i) = mean(data_session{1,s}{7,i})/1000;
            uniArray{1,s} = arrayfun(@(e)e, uniSessions{1,s}.get(i-1).toArray())+1;
        end
    end
catch
    demand = -1;
    return
end
Z_session = N./X-R;
Z = Z_session + Z_request;

% if strcmp(frontendList.get(0),'backend_gold')
%     R_LLaw = [20,20]./X_period'- [21,13];
% else
%     R_LLaw = [20,20]./X_period'- [13,21];
% end
% R_LLaw = sum(R_LLaw.*X_period')/sum(X);

X_period_all = 0;
for i = 1:frontendList.size
    if strcmp(frontendList.get(i-1),'backend_gold')
        X_period_all = X_period_all + sum(X_period(i,:))*10;
    else
        X_period_all = X_period_all + sum(X_period(i,:));
    end
end

D_request
serverIDList{1,s}.size

for s = 1:frontendList.size
    for i = 1:serverIDListAll.size
        %for j = 1:frontendList.size
            %index = serverIDListAll.indexOf(serverIDList{1,s}.get(i-1));
            %server_id = serverIDListAll.get(i-1);
            %index = str2double(strrep(server_id,'ofbiz',''));
            D{1,s}(i,1) = sum(D_request{1,i}(uniArray{1,s}));
            %D{1,s}(i,1) = D{1,s}(i,1)/nCPU(index);
        %end
    end
end

for i = 1:frontendList.size
    try 
%         if strcmp(frontendList.get(i-1),'backend_gold')
%             dcAgent.sendSyncMonitoringDatum(num2str(sum(X_period(i,:))*2),returnedMetric,frontendResourceMap.get(frontendList.get(i-1)));
%         else
%             dcAgent.sendSyncMonitoringDatum(num2str(sum(X_period(i,:))),returnedMetric,frontendResourceMap.get(frontendList.get(i-1)));
%         end
            %dcAgent.sendSyncMonitoringDatum(num2str(R_LLaw),returnedMetric,frontendResourceMap.get(frontendList.get(i-1)));
        fprintf(fileID,'throughput: %s\n',num2str(X_period_all));
        dcAgent.sendSyncMonitoringDatum(num2str(X_period_all),returnedMetric,frontendResourceMap.get(frontendList.get(i-1)));
    catch 
        fprintf(fileID,'could not send data to dda');
        disp('could not send data to dda')
    end
end
D

save(strcat(filePath,'LBData.mat'),'uniSessions','sessionsList','sessionIDList','sessionTimes','thinkTimes','requestTimes','N','D','Z','frontendList','serverIDList','sessionStart','categoryList','N','R','X','uniArray','Z_request','serverIDListAll','data_session','data','D_request','old_value','frontendResourceMap')
save(strcat(filePath,'LBData',num2str(count_file),'.mat'),'uniSessions','sessionsList','sessionIDList','sessionTimes','thinkTimes','requestTimes','N','D','Z','frontendList','serverIDList','sessionStart','categoryList','N','R','X','uniArray','Z_request','serverIDListAll','data_session','data','D_request','old_value','frontendResourceMap')
count_file = count_file + 1;
demand = -1;
