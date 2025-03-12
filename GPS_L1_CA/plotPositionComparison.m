function plotPositionComparison(navSolutions, ekfSolutions)
    figure;
    
    % Convert ECEF to local ENU for better visualization
    [refLat, refLon, refAlt] = ecef2geodetic(navSolutions.X(1), navSolutions.Y(1), navSolutions.Z(1), 'wgs84');
    
    % Convert LS solutions to ENU
    enuLS = zeros(size(navSolutions.X));
    for i = 1:size(navSolutions.X, 1)
        if ~isnan(navSolutions.X(i))
            [enuLS(i,1), enuLS(i,2), enuLS(i,3)] = ecef2enu(navSolutions.X(i), navSolutions.Y(i), navSolutions.Z(i), refLat, refLon, refAlt, 'wgs84');
        else
            enuLS(i,:) = [NaN, NaN, NaN];
        end
    end
    
    % Convert EKF solutions to ENU
    enuEKF = zeros(size(ekfSolutions.ekfPos));
    for i = 1:size(ekfSolutions.ekfPos, 1)
        if ~isnan(ekfSolutions.ekfPos(i,1))
            [enuEKF(i,1), enuEKF(i,2), enuEKF(i,3)] = ecef2enu(ekfSolutions.ekfPos(i,1), ekfSolutions.ekfPos(i,2), ekfSolutions.ekfPos(i,3), refLat, refLon, refAlt, 'wgs84');
        else
            enuEKF(i,:) = [NaN, NaN, NaN];
        end
    end
    
    % Plot East-North comparison
    subplot(2,2,1);
    plot(enuLS(:,1), enuLS(:,2), 'b.-', enuEKF(:,1), enuEKF(:,2), 'r.-');
    title('Position: East-North');
    xlabel('East (m)');
    ylabel('North (m)');
    legend('Least Squares', 'Extended Kalman Filter');
    grid on;
    
    % Plot East-Up comparison
    subplot(2,2,2);
    plot(enuLS(:,1), enuLS(:,3), 'b.-', enuEKF(:,1), enuEKF(:,3), 'r.-');
    title('Position: East-Up');
    xlabel('East (m)');
    ylabel('Up (m)');
    grid on;
    
    % Plot position error over time
    subplot(2,2,3);
    validIndices = ~isnan(enuLS(:,1)) & ~isnan(enuEKF(:,1));
    posError = sqrt(sum((enuLS(validIndices,:) - enuEKF(validIndices,:)).^2, 2));
    plot(navSolutions.transmitTime(validIndices), posError, 'k.-');
    title('Position Error: EKF vs LS');
    xlabel('GPS Time of Week (s)');
    ylabel('Position Error (m)');
    grid on;
    
    % Plot velocity magnitude
    subplot(2,2,4);
    velMag = sqrt(sum(ekfSolutions.ekfVel.^2, 2));
    plot(navSolutions.transmitTime, velMag, 'g.-');
    title('Velocity Magnitude (EKF)');
    xlabel('GPS Time of Week (s)');
    ylabel('Velocity (m/s)');
    grid on;
end