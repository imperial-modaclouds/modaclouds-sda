%% main function, requires the configuration file as input
function main(mode)
% the required jar files
javaaddpath(fullfile(pwd,'lib/commons-lang3-3.1.jar'));
javaaddpath(fullfile(pwd,'lib/data-retriever-1.0.4.jar'))
javaaddpath(fullfile(pwd,'lib/sdaSync-0.0.1-SNAPSHOT.jar'))

% if matlabpool('size') == 0
%     matlabpool open
%     setmcruserdata('ParallelProfile','clusterProfile.settings');
%     parallel.importProfile('clusterProfile.settings')
% end

port = getenv('MODACLOUDS_MATLAB_SDA_PORT')
%[~,port] = system('echo $MODACLOUDS_MATLAB_SDA_PORT')
% pwd
% ctfroot
% javaaddpath(fullfile(ctfroot,'lib/commons-lang3-3.1.jar'));
% javaaddpath(fullfile(ctfroot,'lib/pdm-timeseriesforecasting-ce-TRUNK-SNAPSHOT.jar'));
% javaaddpath(fullfile(ctfroot,'lib/sda-0.0.1-SNAPSHOT.jar'))
% javaaddpath(fullfile(ctfroot,'lib/weka.jar');
% javaaddpath(fullfile(ctfroot,'lib/retriever-0.0.1-SNAPSHOT.jar'))
% javaaddpath(fullfile(ctfroot,'lib/metrics-observer-0.1.jar'))
% javaaddpath(fullfile(ctfroot,'lib/knowledge-base-api-1.0-jar-with-dependencies.jar'))
% javaaddpath(fullfile(ctfroot,'lib/object-store-api-0.1-jar-with-dependencies.jar'))
% javaaddpath(fullfile(ctfroot,'lib/dda-api-1.0-jar-with-dependencies.jar'))

%objectStoreConnector = it.polimi.modaclouds.monitoring.objectstoreapi.ObjectStoreConnector.getInstance;
%mo = javaObject('it.polimi.modaclouds.qos_models.monitoring_ontology.MO');
%mo.setKnowledgeBaseURL(objectStoreConnector.getKBUrl);

if strcmp(mode,'tower4clouds')
    dc = javaObject('imperial.modaclouds.sdaSync.DataCollectorAgent');
    dc.initiate();
    dcAgent = dc.dcAgent();
    %dcAgent.startSyncingWithKB();
end
startTime = 0;

%supportedFunctions = {'estimationci','estimationfcfs','estimationubo','estimationubr', ...
%    'haproxyci','haproxyubr','forecastingtimeseriesar','forecastingtimeseriesarima','forecastingtimeseriesarma'};

myRetriever = javaObject('imperial.modaclouds.monitoring.data_retriever.Client_Server');
myRetriever.retrieve(str2num(port));

fileID = fopen(fullfile(pwd,'nextTime.txt'),'w');

count = 1;

while 1
    
    if (strcmp(mode,'tower4clouds') && java.lang.System.currentTimeMillis - startTime > 600000)
        i = 0;
        sdas = dc.checkMetric();
        
        sdas.size
        
        if ~isempty(sdas)
            it = sdas.iterator();
            while (it.hasNext)
                config = it.next;
                
                parameters{i+1} = config.getParameters;
                returnedMetric{i+1} = char(config.getMetricName);
                targetMetric{i+1} = char(config.getTargetMetric);
                type{i+1} = char(config.getFunction);
                
                if ~isempty(parameters{i+1}.get('samplingTime'))
                    new_period(i+1) = str2double(parameters{i+1}.get('samplingTime'))*1000;
                end
                
                if ~isempty(parameters{i+1}.get('CPUUtilMetric'))
                    flag = dc.registerMetric(parameters{i+1}.get('CPUUtilMetric'));
                    if flag == -1
                        disp('Error registering CPU Utilization metric');
                    else
                        disp('Registering CPU Utilization metric succsssful');
                    end
                end
                
                %                 if ~isempty(parameters{i+1}.get('targetMetric'))
                %                     targetMetric{i+1} = char(parameters{i+1}.get('targetMetric'));
                %                 end
                i = i+1;
            end
            
            if i == 0
                pause(10);
                continue;
            end
            
            if exist('period','var') == 0
                period = new_period;
                nextPauseTime = period;
            else
                if ~isequal(period,new_period)
                    nextPauseTime = period;
                end
            end
            
            startTime = java.lang.System.currentTimeMillis;
        end
    end
    if (strcmp(mode,'file') && java.lang.System.currentTimeMillis - startTime > 60000)
        file = 'configuration_SDA.xml';
        xDoc = xmlread(file);
        rootNode = xDoc.getDocumentElement.getChildNodes;
        node = rootNode.getFirstChild;
        
        nbMetric = 0;
        nbParameter = 0;
        
        while ~isempty(node)
            if strcmp(node.getNodeName, 'metric')
                subNode = node.getFirstChild;
                while ~isempty(subNode)
                    if strcmpi(subNode.getNodeName, 'type')
                        type{nbMetric} = char(subNode.getTextContent);
                        nbMetric = nbMetric + 1;
                    end
                    if strcmpi(subNode.getNodeName, 'timeStep')
                        new_period(nbMetric) = str2double(subNode.getTextContent)*1000
                    end
                    if strcmpi(subNode.getNodeName, 'targetResources')
                        targetResources{nbMetric} = char(subNode.getTextContent);
                    end
                    if strcmpi(subNode.getNodeName, 'targetMetric')
                        targetMetric{nbMetric} = char(subNode.getTextContent);
                    end
                    if strcmpi(subNode.getNodeName, 'parameter')
                        nbParameter = nbParameter + 1;
                        parameters{nbMetric}{nbParameter,1} = char(subNode.getAttribute('name'));
                        parameters{nbMetric}{nbParameter,2} = char(subNode.getAttribute('value'));
                    end
                    subNode = subNode.getNextSibling;
                end
                returnedMetric{nbMetric} = char(node.getAttribute('returnedMetric'));
            end
            node = node.getNextSibling;
        end
        
        if exist('period','var') == 0
            period = new_period;
            nextPauseTime = period;
        else
            if ~isequal(period,new_period)
                nextPauseTime = period;
            end
        end
    end
    
    nextPauseTime
    fprintf(fileID,'%d %d\n',nextPauseTime);
    [pauseTime, index] = min(nextPauseTime);
    nextPauseTime = nextPauseTime - pauseTime;
    pause(pauseTime/1000)
    
    tic;
    
    targetResources = myRetriever.getMetricMap.get(targetMetric{index})
    
    if ~isempty(targetResources)
        
        value = -1;
        type{index}
        switch lower(type{index})
            case 'estimationci'
                value = estimation_mic(targetResources,returnedMetric{index},targetMetric{index},'ci',parameters{index},myRetriever, mode, dc);
            case 'estimationfcfs'
                value = estimation_mic(targetResources,returnedMetric{index},targetMetric{index},'fcfs',parameters{index},myRetriever, mode, dc);
            case 'estimationubo'
                value = estimation_mic(targetResources,returnedMetric{index},targetMetric{index},'ubo',parameters{index},myRetriever, mode, dc);
            case 'estimationubr'
                value = estimation_mic(targetResources,returnedMetric{index},targetMetric{index},'ubr',parameters{index},myRetriever, mode, dc);
            case 'haproxyci'
                [value,count] = haproxyCI(targetResource,targetMetric{index},parameters{index},myRetriever, mode, dcAgent, returnedMetric{index}, new_period(index),fileID,count);
            case 'haproxyubr'
                value = haproxyUBR(targetResources,targetMetric{index},parameters{index},myRetriever, mode);
                %         case 'ForecastingML'
                %             value = forecastingML(targetResources,targetMetric{index},parameters{index},myRetriever);
                %         case 'Correlation'
                %             value = correlation(targetResources,targetMetric{index},parameters{index},myRetriever);
            case 'forecastingtimeseriesar'
                value = forecastingTimeseries(targetResources,returnedMetric{index},targetMetric{index},'AR',parameters{index},myRetriever, mode, dc);
            case 'forecastingtimeseriesarima'
                value = forecastingTimeseries(targetResources,returnedMetric{index},targetMetric{index},'ARIMA',parameters{index},myRetriever, mode, dc);
            case 'forecastingtimeseriesarma'
                value = forecastingTimeseries(targetResources,returnedMetric{index},targetMetric{index},'ARMA',parameters{index},myRetriever, mode, dc);
        end
        
    else
        disp(strcat('No resource found for metric: ',targetMetric{index}));
    end
    
    nextPauseTime = nextPauseTime - toc*1000;
    for i = 1:length(nextPauseTime)
        if nextPauseTime(i) < 0
            nextPauseTime(i) = 0;
        end
    end
    nextPauseTime(index) = max(period(index)-toc*1000,0);
end