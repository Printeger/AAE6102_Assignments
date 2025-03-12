clear all; close all; clc;

format ('compact');
format ('long', 'g');

%--- Include folders with functions ---------------------------------------
addpath ('include')               % The software receiver functions
addpath ('Common')         % Common functions between differnt SDR receivers

%% Initialize constants, settings =========================================
settings = initSettings();
[fid, message] = fopen(settings.fileName, 'rb');

%Initialize the multiplier to adjust for the data type
if (settings.fileType==1) 
    dataAdaptCoeff=1;
else
    dataAdaptCoeff=2;
end

%If success, then process the data
if (fid > 0)
    
    % Move the starting point of processing. Can be used to start the
    % signal processing at any point in the data record (e.g. good for long
    % records or for signal processing in blocks).
    fseek(fid, dataAdaptCoeff*settings.skipNumberOfBytes, 'bof'); 
    disp(' ');

    % Do acquisition if it is not disabled in settings or if the variable
    % acqResults does not exist.
    if ((settings.skipAcquisition == 0) || ~exist('acqResults', 'var'))

        % Find number of samples per spreading code
        samplesPerCode = round(settings.samplingFreq / ...
                           (settings.codeFreqBasis / settings.codeLength));
        % Read data for acquisition. 11ms of signal are needed for the fine
        % frequency estimation
        data  = fread(fid, dataAdaptCoeff*11*samplesPerCode, settings.dataType)';

        if (dataAdaptCoeff==2)    
            data1=data(1:2:end);    
            data2=data(2:2:end);    
            data=data1 + 1i .* data2;    
        end

        %--- Do the acquisition -------------------------------------------
        disp ('   Acquiring satellites...');
        acqResults = acquisition(data, settings);

        % plotAcquisition(acqResults);
    end
    %% Initialize channels and prepare for the run ============================

    % Start further processing only if a GNSS signal was acquired (the
    % field FREQUENCY will be set to 0 for all not acquired signals)
    if (any(acqResults.carrFreq))
        channel = preRun(acqResults, settings);
        showChannelStatus(channel, settings);
    else
        % No satellites to track, exit
        disp('No GNSS signals detected, signal processing finished.');
        trackResults = [];
        return;
    end

    %% Track the signal =======================================================
    if (settings.dataNo == 0)
        if ~exist(['trackingResults_urban','.mat'])
            startTime = now;
            disp (['   Tracking started at ', datestr(startTime)]);
            
            % Process all channels for given data block
            [trackResults, channel] = tracking(fid, channel, settings);
            
            % Close the data file
            fclose(fid);
            
            disp(['   Tracking is over (elapsed time ', ...
                datestr(now - startTime, 13), ')'])
            
            % Auto save the acquisition & tracking results to a file to allow
            % running the positioning solution afterwards.
        %     disp('   Saving Acq & Tracking results to file "trackingResults.mat"')
            save('trackingResults_urban', ...
                'trackResults', 'settings', 'acqResults', 'channel');
            
        else
            load('trackingResults_urban.mat');
        end
    else
        if ~exist(['trackingResults_opensky','.mat'])
            startTime = now;
            disp (['   Tracking started at ', datestr(startTime)]);
            
            % Process all channels for given data block
            [trackResults, channel] = tracking(fid, channel, settings);
            
            % Close the data file
            fclose(fid);
            
            disp(['   Tracking is over (elapsed time ', ...
                datestr(now - startTime, 13), ')'])
            
            % Auto save the acquisition & tracking results to a file to allow
            % running the positioning solution afterwards.
            % disp('   Saving Acq & Tracking results to file "trackingResults.mat"')
            save('trackingResults_opensky', ...
                'trackResults', 'settings', 'acqResults', 'channel');
            
        else
            load('trackingResults_opensky.mat');
        end
    end
    
    %% Calculate navigation solutions =========================================
    disp('   Calculating navigation solutions...');
    settings = initSettings();
    [navSolutions, eph] = postNavigation(trackResults, settings);
    
    disp('   Processing is complete for this data block');
    for j = 1:length(eph)
         if (isempty(eph(j).C_ic))
            continue;
        end
        fields = fieldnames(eph(j));
    
        data = cell(length(fields), 2);
    
        for i = 1:length(fields)
            fieldName = fields{i};
            fieldValue = eph(j).(fieldName);
            
            data{i, 1} = fieldName;
            data{i, 2} = fieldValue;
        end
        title = ['====================== PRN ', num2str(j), ' ======================'];
        disp(title);
        resultTable = cell2table(data, 'VariableNames', {'FieldName', 'FieldValue'});
        disp(resultTable);
    end

end % if (fid > 0)


