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

    %% Task 1: Acquisition ============================================================
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

        plotAcquisition(acqResults);
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

    %% Plot tracking
    disp('   Plotting trackResults...');
    settings = initSettings();
    
    %% Ground truth data
    if (settings.dataNo == 0)
        open_gt = [22.3198722, 114.209101777778, 3]; % Urban gt
        disp('Urban gt: [22.3198722, 114.209101777778, 3]');
    else
        open_gt = [22.328444770087565, 114.1713630049711, 3]; % Opensky gt
        disp('Opensky gt: [22.328444770087565,114.1713630049711,3]');
    end
    
    %% Plot ground truth and navigation solutions on a map
    figure(1);
    geoscatter(open_gt(1), open_gt(2), 100, 'y', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5); % Ground truth point
    hold on;
    geobasemap satellite; % Use satellite basemap
    
    % Plot navigation solutions
    for i = 1:size(navSolutions.latitude, 2)
        geoplot(navSolutions.latitude(i), navSolutions.longitude(i), 'r*', 'MarkerSize', 10, 'LineWidth', 1.5);
        hold on;
    end
    
    % Add ground truth marker
    geoplot(open_gt(1), open_gt(2), 'o', 'MarkerFaceColor', 'y', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    title('Navigation Solutions vs Ground Truth');
    legend('Ground Truth', 'Navigation Solutions', 'Location', 'best');
    
    %% WLS for velocity
    figure(2)
    v = [];
    for i = 2:size(navSolutions.X, 2)
        v = [v; navSolutions.X(i) - navSolutions.X(i-1), navSolutions.Y(i) - navSolutions.Y(i-1), navSolutions.Z(i) - navSolutions.Z(i-1)];
    end
    
    % Plot velocity components with improved styles
    plot(1:size(navSolutions.X, 2)-1, v(:, 1), '-o', 'LineWidth', 1.2, 'MarkerSize', 6, 'Color', [0, 0.4470, 0.7410], 'DisplayName', 'v_x');
    hold on;
    plot(1:size(navSolutions.X, 2)-1, v(:, 2), '-s', 'LineWidth', 1.2, 'MarkerSize', 6, 'Color', [0.8500, 0.3250, 0.0980], 'DisplayName', 'v_y');
    plot(1:size(navSolutions.X, 2)-1, v(:, 3), '-d', 'LineWidth', 1.2, 'MarkerSize', 6, 'Color', [0.9290, 0.6940, 0.1250], 'DisplayName', 'v_z');
    
    % Add grid, labels, and legend
    grid on;
    xlabel('Epoch (s)', 'FontWeight', 'bold');
    ylabel('Velocity (m/s)', 'FontWeight', 'bold');
    legend('Location', 'best');
    title('Velocity Components Over Time');
    hold off;
end % if (fid > 0)


