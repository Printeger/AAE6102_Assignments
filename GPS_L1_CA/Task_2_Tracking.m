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
    
    %% for multi-correaltor output
    % Define a color palette for better visualization
    colors = lines(7); % Use MATLAB's built-in 'lines' colormap for distinct colors
    
    % Loop through each subplot
    for k = 1:4
        subplot(2, 2, k);
        hold on; % Enable holding multiple plots
        
        % Loop through the data with a step of 1000
        for i = 1:1000:length(trackResults(k).I_multi)
            data = trackResults(k).I_multi{i}; % Get the data
            if data(6) < 0
                data = -data; % Flip the data if necessary
            end
            
            % Plot the data with a specific color and line style
            colors = lines(7); % 使用 lines 颜色映射生成 7 种颜色
            plot(-0.5:0.1:0.5, data, '-', 'LineWidth', 1.5, 'Color', colors(mod(i, 7) + 1, :));
            % scatter(-0.5:0.1:0.5, data, 50, pcolor(mod(i, 7) + 1, 'filled')); % Add scatter points
            scatter(-0.5:0.1:0.5, data, 50, colors(mod(i, 7) + 1, :), 'filled');
        end
        
        % Add labels and title
        xlabel('Code Delay (chips)', 'FontSize', 10, 'FontWeight', 'bold');
        ylabel('ACF (Amplitude)', 'FontSize', 10, 'FontWeight', 'bold');
        title(sprintf('ACF of Multi-correlator (PRN %d, 10s Interval)', k), 'FontSize', 12, 'FontWeight', 'bold');
        
        % Add grid for better readability
        grid on;
        
        % Add a legend
        legend('ACF Curve', 'ACF Points', 'Location', 'best');
        
        % Adjust subplot margins for better layout
        set(gca, 'FontSize', 10); % Set axis font size
        set(gca, 'LineWidth', 1.5); % Set axis line width
    end
    
    % Adjust overall figure layout
    set(gcf, 'Position', [100, 100, 1200, 800]); % Set figure size
    sgtitle('Multi-correlator ACF Results', 'FontSize', 14, 'FontWeight', 'bold'); % Add a global title

end % if (fid > 0)
