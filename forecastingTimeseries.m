function values = forecastingTimeseries( targetResources,targetMetric,method,parameters, obj, mode )

%FIX
temp_str = obj.obtainData(targetResources,targetMetric);

if isempty(temp_str)
    values = -1;
    disp('No data received')
    return;
end

dataArrayList = temp_str.getValues;
data =  convertArrayList( dataArrayList );

if strcmp(mode, 'kb')
    if ~isempty(parameters.get('order'))
        m = str2double(parameters.get('order'));
    end
    if ~isempty(parameters.get('forecastPeriod'))
        K = str2double(parameters.get('forecastPeriod'));
    end
    if ~isempty(parameters.get('autoregressive'))
        p = str2double(parameters.get('autoregressive'));
    end
    if ~isempty(parameters.get('movingAverage'))
        q = str2double(parameters.get('movingAverage'));
    end
    if ~isempty(parameters.get('integrated'))
        d = str2double(parameters.get('integrated'));
    end
else
    for i = 1:size(parameters,1)
        switch parameters{i,1}
            case 'order'
                m = str2double(parameters{i,2});
            case 'forecastPeriod'
                K = str2double(parameters{i,2});
            case 'autoregressive'
                p = str2double(parameters{i,2});
            case 'movingAverage'
                q = str2double(parameters{i,2});
            case 'integrated'
                d = str2double(parameters{i,2});
        end
    end
end

switch(method)
    case 'AR'
        %% Forecast linear system response into future
        data_id = iddata(data',[]);
        try
            sys = ar(data_id,m);
            p = forecast(sys,data_id,K);
            values = p.y;
            values = values(K);
        catch exception
            values = -1;
            exception.message
            for k=1:length(exception.stack)
                exception.stack(k);
            end
            return;
        end
        
    case 'ARMA'
        if isnan(p) || isnan(q)
            LOGL = zeros(4,4); %Initialize
            PQ = zeros(4,4);
            for p = 1:4
                for q = 1:4
                    mod = arima(p,0,q);
                    [fit,~,logL] = estimate(mod,data','print',false);
                    LOGL(p,q) = logL;
                    PQ(p,q) = p+q;
                end
            end
            
            LOGL = reshape(LOGL,16,1);
            PQ = reshape(PQ,16,1);
            [~,bic] = aicbic(LOGL,PQ+1,100);
            bic = reshape(bic,4,4);
            
            [p,q] = find(bic==min(min(bic)));
        end
        
        Mdl = arima(p,0,q);
        
        try
            if iscolumn(data)
                EstMdl = estimate(Mdl,data);
                [YF YMSE] = forecast(EstMdl,K,'Y0',data);
            else
                EstMdl = estimate(Mdl,data');
                [YF YMSE] = forecast(EstMdl,K,'Y0',data');
            end
        catch exception
            values = -1;
            exception.message
            for k=1:length(exception.stack)
                exception.stack(k);
            end
            return;
        end
        
        values = YF(K);
        
    case 'ARIMA'
        %% Forecast ARIMA or ARIMAX process
        if isnan(p) || isnan(q) || isnan(d)
            LOGL = zeros(4,3,4); %Initialize
            PQ = zeros(4,3,4);
            for p = 1:4
                for q = 1:4
                    for d = 0:2
                        mod = arima(p,d,q);
                        [fit,~,logL] = estimate(mod,data','print',false);
                        LOGL(p,d+1,q) = logL;
                        PQ(p,d+1,q) = p+q;
                    end
                end
            end
            
            LOGL = reshape(LOGL,48,1);
            PQ = reshape(PQ,48,1);
            [~,bic] = aicbic(LOGL,PQ+1,100);
            bic = reshape(bic,4,3,4);
            
            [temp I] = min(bic,[],3);
            [p,d] = find(temp==min(min(temp)));
            q = I(p,d);
            d = d-1;
        end
        
        Mdl = arima(p,d,q);
        
        try
            if iscolumn(data)
                EstMdl = estimate(Mdl,data);
                [YF YMSE] = forecast(EstMdl,K,'Y0',data);
            else
                EstMdl = estimate(Mdl,data');
                [YF YMSE] = forecast(EstMdl,K,'Y0',data');
            end
        catch exception
            values = -1;
            exception.message
            for k=1:length(exception.stack)
                exception.stack(k);
            end
            return;
        end
        
        values = YF(K);
        
        %send back the data
end


end