%% main function, requires the configuration file as input
function main(mode, port)
% the required jar files
javaaddpath(fullfile(pwd,'lib/commons-lang3-3.1.jar'));
javaaddpath(fullfile(pwd,'lib/data-retriever-1.0.3.jar'))
javaaddpath(fullfile(pwd,'lib/object-store-api-0.1.jar'))
javaaddpath(fullfile(pwd,'lib/kbsync-0.0.1-SNAPSHOT.jar'))

if matlabpool('size') == 0
    matlabpool open
    setmcruserdata('ParallelProfile','clusterProfile.settings');
    parallel.importProfile('clusterProfile.settings')
end

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

if strcmp(mode,'kb')
    dc = javaObject('imperial.modaclouds.kbsync.DataCollectorAgent');
    dc.initialize(java.lang.String('file'));
    dcAgent = dc.getInstance();
    dcAgent.startSyncingWithKB();
end
startTime = 0;

supportedFunctions = {'estimationci','estimationfcfs','estimationubo','estimationubr', ...
    'haproxyci','haproxyubr','forecastingtimeseriesar','forecastingtimeseriesarima','forecastingtimeseriesarma'};

myRetriever = javaObject('imperial.modaclouds.monitoring.data_retriever.Client_Server');
myRetriever.retrieve(str2num(port));

fileID = fopen(fullfile(pwd,'nextTime.txt'),'w');

count = 1;

while 1
    
    if (strcmp(mode,'kb') && java.lang.System.currentTimeMillis - startTime > 600000)
        i = 0;
        for s = 1:length(supportedFunctions)
            %try
                sdas = dcAgent.getConfiguration([],supportedFunctions{1,s});
            %catch
                %classLoader = com.mathworks.jmi.ClassLoaderManager.getClassLoaderManager;
                %sdas = DataCollectorAgent.getAll(classLoader.loadClass('it.polimi.modaclouds.qos_models.monitoring_ontology.StatisticalDataAnalyzer'));
            %end

            sdas.size

            if ~isempty(sdas)
                it = sdas.iterator();
                while (it.hasNext)
                    config = it.next;
                    %sdas.get(i).setStarted(true);
                    %DataCollectorAgent.add(sdas.get(i));

                    temp_type = lower(char(config.getMonitoredMetric));
                    if isempty(find(ismember(supportedFunctions,temp_type)))
                        continue;
                    end

                    parameters{i+1} = config.getParameters;
                    returnedMetric{i+1} = char(config.getMonitoredMetric);
                    %targetMetric{i+1} = char(config.getTargetMetric);
                    setTargetResourceType = config.getMonitoredResourcesTypes;
                    type{i+1} = char(config.getMonitoredMetric);

                    if ~isempty(parameters{i+1}.get('samplingTime'))
                        new_period(i+1) = str2double(parameters{i+1}.get('samplingTime'))*1000;
                    end
                    if ~isempty(parameters{i+1}.get('targetMetric'))
                        targetMetric{i+1} = char(parameters{i+1}.get('targetMetric'));
                    end

                    it_resource = setTargetResourceType.iterator();
                    j = 0;
                    while (it_resource.hasNext)
                        set = dcAgent.getEntitiesByPropertyValue(it_resource.next,'type','model');
                        it_vm = set.iterator();
                        while (it_vm.hasNext)
                            targetResources{i+1,j+1} = char(it_vm.next.getId);
                            j = j+1;
                        end
    %                     targetResources{i+1,j+1} = char(it_resource.next());
    %                     if strcmp(targetResources{i+1,j+1},'Frontend')
    %                         targetResources{i+1,1} = 'frontend1';
    %                         %targetResources{i+1,2} = 'frontend2';
    %                     end


                    end
                    targetResources

                    i = i+1;
                end

            end
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
    
    value = -1;
    tic;
    switch lower(type{index})
        case 'estimationci'
            value = estimation(targetResources{index},targetMetric{index},'ci',parameters{index},myRetriever, mode);
        case 'estimationfcfs'
            value = estimation(targetResources{index},targetMetric{index},'fcfs',parameters{index},myRetriever, mode);
        case 'estimationubo'
            value = estimation(targetResources{index},targetMetric{index},'ubo',parameters{index},myRetriever, mode);
        case 'estimationubr'
            value = estimation(targetResources{index},targetMetric{index},'ubr',parameters{index},myRetriever, mode);
        case 'haproxyci'
            [value,count] = haproxyCI(targetResources(index,:),targetMetric{index},parameters{index},myRetriever, mode, dcAgent, returnedMetric{index}, new_period(index),fileID,count);
        case 'haproxyubr'
            value = haproxyUBR(targetResources(index,:),targetMetric{index},parameters{index},myRetriever, mode);
            %         case 'ForecastingML'
            %             value = forecastingML(targetResources{index},targetMetric{index},parameters{index},myRetriever);
            %         case 'Correlation'
            %             value = correlation(targetResources{index},targetMetric{index},parameters{index},myRetriever);
        case 'forecastingtimeseriesar'
            value = forecastingTimeseries(targetResources(index,:),returnedMetric{index},targetMetric{index},'AR',parameters{index},myRetriever, mode, dcAgent);
        case 'forecastingtimeseriesarima'
            value = forecastingTimeseries(targetResources(index,:),returnedMetric{index},targetMetric{index},'ARIMA',parameters{index},myRetriever, mode, dcAgent);
        case 'forecastingtimeseriesarma'
            value = forecastingTimeseries(targetResources(index,:),returnedMetric{index},targetMetric{index},'ARMA',parameters{index},myRetriever, mode, dcAgent);
    end
    
    if value + 1 < 0.00001
    else
        try
            value
            dcAgent.sendSyncMonitoringDatum(num2str(value),returnedMetric{index},targetResources{index});
        catch exception
            %    exception.message
            %    for k=1:length(exception.stack)
            %        exception.stack(k);
            %    end
        end
    end
    nextPauseTime = nextPauseTime - toc*1000;
    for i = 1:length(nextPauseTime)
        if nextPauseTime(i) < 0
            nextPauseTime(i) = 0;
        end
    end
    nextPauseTime(index) = max(period(index)-toc*1000,0);
end