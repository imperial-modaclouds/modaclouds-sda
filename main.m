%% main function, requires the configuration file as input
clc
clear
% the required jar files
javaaddpath(fullfile(pwd,'lib/commons-lang3-3.1.jar'));
javaaddpath(fullfile(pwd,'lib/data-retriever-1.0.jar'))
javaaddpath(fullfile(pwd,'lib/knowledge-base-api-1.0.jar'))
javaaddpath(fullfile(pwd,'lib/object-store-api-0.1.jar'))
javaaddpath(fullfile(pwd,'lib/dda-api-1.0.jar'))

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

kbConnector = it.polimi.modaclouds.monitoring.kb.api.KBConnector.getInstance;

startTime = 0;

myRetriever = javaObject('imperial.modaclouds.monitoring.data_retriever.Client_Server');
myRetriever.retrieve(8176);

ddaConnector = it.polimi.modaclouds.monitoring.ddaapi.DDAConnector.getInstance;

while 1
    
    if (java.lang.System.currentTimeMillis - startTime > 60000)
        
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
                        period(i+1) = str2double(parameter.getValue());
                    end
                end
                
                it_resource = setTargetResources{i+1}.iterator();
                while (it_resource.hasNext)
                    targetResources{i+1} = it_resource.next().getId();
                end
                
                i = i+1;
            end
        end
        
        startTime = java.lang.System.currentTimeMillis;
        
    end
    
    nextPauseTime = period;
    
    [pauseTime, index] = min(nextPauseTime);
    nextPauseTime = nextPauseTime - pauseTime;
    pause(pauseTime/1000)
    
    value = -1;
    
    switch type{index}
        case 'Estimation'
            value = estimation(targetResources{index},targetMetric{index},parameters{index},myRetriever);
%         case 'ForecastingML'
%             value = forecastingML(targetResources{index},targetMetric{index},parameters{index},myRetriever);
%         case 'Correlation'
%             value = correlation(targetResources{index},targetMetric{index},parameters{index},myRetriever);
        case 'ForecastingTimeSeriesAR'
            value = forecastingTimeseries(targetResources{index},targetMetric{index},'AR',parameters{index},myRetriever);
        case 'ForecastingTimeSeriesARIMA'
            value = forecastingTimeseries(targetResources{index},targetMetric{index},'ARIMA',parameters{index},myRetriever);
        case 'ForecastingTimeSeriesARMA'
            value = forecastingTimeseries(targetResources{index},targetMetric{index},'ARMA',parameters{index},myRetriever);
            
    end
    
    if value == -1
    else
        %value
        try
            ddaConnector.sendSyncMonitoringDatum(num2str(value),returnedMetric{index},'SDA');
        catch exception
            disp(exception);
        end
    end
    
    nextPauseTime(index) = period(index);
end