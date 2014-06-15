%% main function, requires the configuration file as input

% the required jar files
javaaddpath(fullfile(pwd,'lib/commons-lang3-3.1.jar'));
javaaddpath(fullfile(pwd,'lib/data-retriever-1.0.jar'))
javaaddpath(fullfile(pwd,'lib/knowledge-base-api-1.0.jar'))
javaaddpath(fullfile(pwd,'lib/object-store-api-0.1.jar'))
javaaddpath(fullfile(pwd,'lib/dda-api-1.0.1.jar'))

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

fileID = fopen('port.txt','r');
port = fscanf(fileID,'%d');
mode = fscanf(fopen('mode.txt','r'),'%s');

if strcmp(mode,'kb')
    kbConnector = it.polimi.modaclouds.monitoring.kb.api.KBConnector.getInstance;
end
startTime = 0;

myRetriever = javaObject('imperial.modaclouds.monitoring.data_retriever.Client_Server');
myRetriever.retrieve(port);

ddaConnector = it.polimi.modaclouds.monitoring.ddaapi.DDAConnector.getInstance;

while 1
    
    if (strcmp(mode,'kb') && java.lang.System.currentTimeMillis - startTime > 10000)
        
        try
            sdas = kbConnector.getAll(java.lang.Class.forName('it.polimi.modaclouds.qos_models.monitoring_ontology.StatisticalDataAnalyzer'));
        catch
            classLoader = com.mathworks.jmi.ClassLoaderManager.getClassLoaderManager;
            sdas = kbConnector.getAll(classLoader.loadClass('it.polimi.modaclouds.qos_models.monitoring_ontology.StatisticalDataAnalyzer'));
        end
        
        if ~isempty(sdas)
            it = sdas.iterator();
            i = 0;
            while (it.hasNext)
                config = it.next;
                %sdas.get(i).setStarted(true);
                %kbConnector.add(sdas.get(i));
                
                parameters{i+1} = config.getParameters;
                returnedMetric{i+1} = char(config.getReturnedMetric);
                targetMetric{i+1} = char(config.getTargetMetric);
                setTargetResources{i+1} = config.getTargetResources;
                type{i+1} = char(config.getAggregateFunction);
                
                it_parameter = parameters{i+1}.iterator();
                while (it_parameter.hasNext)
                    parameter = it_parameter.next;
                    if strcmp(parameter.getName(), 'timeStep')
                        period(i+1) = str2double(parameter.getValue())*1000;
                    end
                end
                
                it_resource = setTargetResources{i+1}.iterator();
                while (it_resource.hasNext)
                    targetResources{i+1} = it_resource.next().getUri();
                end
                
                i = i+1;
            end
        end
        
        if i == 0
            pause(10);
            continue;
        end
        
        startTime = java.lang.System.currentTimeMillis;
    else
        file = 'configuration_SDA.xml';
        xDoc = xmlread(file);
        rootNode = xDoc.getDocumentElement.getChildNodes;
        node = rootNode.getFirstChild;
        
        nbMetric = 0;
        nbParameter = 0;
        
        while ~isempty(node)
            if strcmp(node.getNodeName, 'metric')
                nbMetric = nbMetric + 1;
                returnedMetric{nbMetric} = char(node.getAttribute('returnedMetric'));
                subNode = node.getFirstChild;
                while ~isempty(subNode)
                    if strcmpi(subNode.getNodeName, 'type')
                        type{nbMetric} = char(subNode.getTextContent);
                    end
                    if strcmpi(subNode.getNodeName, 'timeStep')
                        period(nbMetric) = str2double(subNode.getTextContent)*1000;
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
            end
            node = node.getNextSibling; 
        end
    end
    
    nextPauseTime = period;
    
    [pauseTime, index] = min(nextPauseTime);
    nextPauseTime = nextPauseTime - pauseTime;
    pause(pauseTime/1000)
    
    value = -1;
    
    switch type{index}
        case 'EstimationCI'
            value = estimation(targetResources{index},targetMetric{index},'ci',parameters{index},myRetriever, mode);
        case 'EstimationFCFS'
            value = estimation(targetResources{index},targetMetric{index},'fcfs',parameters{index},myRetriever, mode);
        case 'EstimationUBO'
            value = estimation(targetResources{index},targetMetric{index},'ubo',parameters{index},myRetriever, mode);
        case 'EstimationUBR'
            value = estimation(targetResources{index},targetMetric{index},'ubr',parameters{index},myRetriever, mode);
            %         case 'ForecastingML'
            %             value = forecastingML(targetResources{index},targetMetric{index},parameters{index},myRetriever);
            %         case 'Correlation'
            %             value = correlation(targetResources{index},targetMetric{index},parameters{index},myRetriever);
        case 'ForecastingTimeSeriesAR'
            value = forecastingTimeseries(targetResources{index},targetMetric{index},'AR',parameters{index},myRetriever, mode);
        case 'ForecastingTimeSeriesARIMA'
            value = forecastingTimeseries(targetResources{index},targetMetric{index},'ARIMA',parameters{index},myRetriever, mode);
        case 'ForecastingTimeSeriesARMA'
            value = forecastingTimeseries(targetResources{index},targetMetric{index},'ARMA',parameters{index},myRetriever, mode);
            
    end
    
    if value + 1 < 0.00001
    else
        try
            value
            ddaConnector.sendSyncMonitoringDatum(num2str(value),returnedMetric{index},targetResources{index});
        catch exception
            %    exception.message
            %    for k=1:length(exception.stack)
            %        exception.stack(k);
            %    end
        end
    end
    
    nextPauseTime(index) = period(index);
end